package com.happymoney.helloworld;

import org.junit.jupiter.api.BeforeAll;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.containers.KafkaContainer;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;

@Testcontainers
@SpringBootTest
@ActiveProfiles(profiles = {"integration"})
public class TestContainersBaseTest {
    // Set up testcontainer instances in this class
    protected static final KafkaContainer kafka = new KafkaContainer(DockerImageName.parse("730502903637.dkr.ecr.us-east-1.amazonaws.com/cp-kafka:7.0.1")
            .asCompatibleSubstituteFor("confluentinc/cp-kafka"))
            .withReuse(true);


    @DynamicPropertySource
    static void registerProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.kafka.bootstrap-servers", () -> kafka.getBootstrapServers());
        registry.add("spring.kafka.properties.schema.registry.url", () -> "mock://");
    }

    @BeforeAll
    public static void beforeAll() {
        kafka.start();
    }
}
