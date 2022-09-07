buildscript {
	repositories {
		maven("https://plugins.gradle.org/m2/")
		maven("https://packages.confluent.io/maven/")
		maven("https://jitpack.io")
	}
}

plugins {
	java
	id("org.springframework.boot") version ("2.7.0")
	id("io.spring.dependency-management") version ("1.0.11.RELEASE")
	id("io.freefair.lombok") version "5.3.0"
	jacoco
	id("org.sonarqube") version "3.3"
}

group = "com.happymoney"

extra["log4j2.version"] = "2.17.1" //override log4j2 for zero day exploit

sourceSets {
	val main by getting
	val test by getting

	val integrationTest by creating {
		compileClasspath += main.output + test.output
		runtimeClasspath += main.output + test.output
	}
}

repositories {
	mavenCentral()
	gradlePluginPortal()
	mavenLocal()
	maven {
		url = uri("https://happymoney-730502903637.d.codeartifact.us-east-1.amazonaws.com/maven/main/")
		credentials {
			username = "aws"
			password = System.getenv("CODEARTIFACT_AUTH_TOKEN")
		}
	}
	maven("https://packages.confluent.io/maven/")
	maven("https://repo.opensourceagility.com/release/")
	maven("https://dynamodb-local.s3-website-us-west-2.amazonaws.com/release")
}

configurations {
	all {
		exclude(mapOf("group" to "org.springframework.boot", "module" to "spring-boot-starter-logging"))
	}
	val testImplementation by getting
	val testRuntimeOnly by getting
	val annotationProcessor by getting
	"integrationTestImplementation" { extendsFrom(testImplementation) }
	"integrationTestRuntimeOnly" { extendsFrom(testRuntimeOnly) }
	"compileOnly" { extendsFrom(annotationProcessor)}
}


dependencies {
	// Api Platform Commons
	implementation("com.happymoney:api-platform-utilities:2.0.2")
	implementation("com.happymoney:api-platform-session:1.0.8")

	// REST dependencies
	implementation("org.springframework.boot:spring-boot-starter-web")
	implementation("org.springframework.boot:spring-boot-starter-actuator")

	// AOP
	implementation("org.springframework.boot:spring-boot-starter")
	testImplementation("org.springframework.boot:spring-boot-starter-test")

	// Logging dependencies
	implementation("org.springframework.boot:spring-boot-starter-log4j2")
	implementation("com.fasterxml.jackson.dataformat:jackson-dataformat-yaml")
	implementation("com.datadoghq:dd-java-agent:0.99.0")

	// Testing
	testImplementation("org.springframework.security:spring-security-test")
	testImplementation("org.testcontainers:kafka:1.17.3")
	testImplementation("org.springframework.kafka:spring-kafka-test")
	testImplementation("org.testcontainers:junit-jupiter:1.15.2")
	testImplementation("org.testcontainers:localstack:1.16.0")
	testAnnotationProcessor("org.mapstruct:mapstruct-processor:1.4.2.Final")
}

tasks {
	compileJava {
		options.compilerArgs = listOf(
				"-Amapstruct.defaultComponentModel=spring",
				"-Amapstruct.unmappedTargetPolicy=ERROR"
		)
	}

	bootRun {
		environment("spring_profiles_active", "local")
	}

	test {
		environment("spring_profiles_active", "test")
		useJUnitPlatform()
		finalizedBy(jacocoTestReport)
	}

	val integrationTest by creating(Test::class) {
		description = "Runs integration tests."
		group = "integration"

		testClassesDirs = sourceSets["integrationTest"].output.classesDirs
		classpath = sourceSets["integrationTest"].runtimeClasspath
		useJUnitPlatform()
		shouldRunAfter("test")
	}

	check {
		dependsOn(integrationTest)
		finalizedBy(jacocoTestReport)
	}

	// File Patterns to exclude from testing & code coverage metrics
	val jacocoExclusions = listOf(
			"{{ cookiecutter.package_dir }}/config/**",
			"{{ cookiecutter.package_dir }}/response/**",
			"{{ cookiecutter.package_dir }}/Application**",
			"{{ cookiecutter.package_dir }}/enumeration/**",
			"{{ cookiecutter.package_dir }}/exception/**",
			"{{ cookiecutter.package_dir }}/repository/**",
			"{{ cookiecutter.package_dir }}/dto/**",
			"{{ cookiecutter.package_dir }}/handlers/**",
			"{{ cookiecutter.package_dir }}/constants/**",
			"{{ cookiecutter.package_dir }}/entity/**",
			"{{ cookiecutter.package_dir }}/security/**",
	)

	jacocoTestReport {
		dependsOn(test)
		finalizedBy(jacocoTestCoverageVerification)
		reports {
			xml.required.set(true)
			csv.required.set(false)
			html.required.set(true)
		}
		classDirectories.setFrom(
				sourceSets.main.get().output.asFileTree.matching {
					exclude(jacocoExclusions)
				}
		)
	}

	jacocoTestCoverageVerification {
		violationRules {
			rule {
				classDirectories.setFrom(sourceSets.main.get().output.asFileTree.matching {
					exclude(jacocoExclusions)
				})
				limit {
					// Minimum code coverage % for the build to pass
					minimum = "0.0".toBigDecimal()  //TODO: Raise this value
				}
			}
		}
	}
}

sonarqube {
	properties {
		property("sonar.projectKey", "HappyMoneyInc_{{ cookiecutter.service_id }}")
		property("sonar.projectName", "{{ cookiecutter.service_id }}")
		property("sonar.organization", "happymoneyinc")
		property("sonar.host.url", "https://sonarcloud.io")
		property("sonar.coverage.jacoco.xmlReportPaths", "build/reports/jacoco/test/jacocoTestReport.xml")
		property("sonar.java.binaries", "build/classes")
		property("sonar.sources", "src/main/java")
		property("sonar.tests", "src/test/java")
	}
}
