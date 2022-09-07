# STAGE 1 - Download dependencies
FROM 730502903637.dkr.ecr.us-east-1.amazonaws.com/gradle:7.3.3-jdk11 AS builder
ENV GRADLE_USER_HOME=/home/gradle/cache_home
RUN mkdir -p $GRADLE_USER_HOME

ENV BUILD_DIR=/usr/src/app
WORKDIR $BUILD_DIR

# Build minimal app
COPY settings.gradle.kts .
COPY app/build.gradle.kts app/

RUN gradle --stacktrace -i clean app:dependencies

# STAGE 2 - Build app
ARG CODEARTIFACT_AUTH_TOKEN
ENV SRC_PATH=/usr/src/app
WORKDIR $SRC_PATH

# Copy the source code
COPY . $SRC_PATH

# Run the build without checks or unit tests
RUN gradle clean build -x check
RUN mv $SRC_PATH/app/build/libs/app.jar $SRC_PATH/app.jar

# Extract the files
RUN java -Djarmode=layertools -jar app.jar extract

# STAGE 3 - Run application
FROM 730502903637.dkr.ecr.us-east-1.amazonaws.com/gradle:7.3.3-jdk11
ARG USER=mps-user
ENV APP_HOME=/usr/src/app
EXPOSE {{cookiecutter.port}}
RUN adduser -s/sbin/nologin -d/home/$USER $USER
WORKDIR $APP_HOME

# Copy source
COPY settings.gradle.kts $APP_HOME
COPY ./app $APP_HOME/app

# Copy application
COPY --from=builder /usr/src/app/dependencies/ ./
COPY --from=builder /usr/src/app/snapshot-dependencies/ ./
COPY --from=builder /usr/src/app/spring-boot-loader/ ./
COPY --from=builder /usr/src/app/application/ ./

RUN chown -R $USER $APP_HOME
USER $USER

CMD ["java", "-javaagent:/usr/src/app/BOOT-INF/lib/dd-java-agent-0.99.0.jar", "org.springframework.boot.loader.JarLauncher", "-Ddd.trace.header.tags=X-HM-Request-Id:agw-request-id", "-Ddd.tags=team:{{ cookiecutter.team_name }},domain:{{ cookiecutter.project_domain }}"]
