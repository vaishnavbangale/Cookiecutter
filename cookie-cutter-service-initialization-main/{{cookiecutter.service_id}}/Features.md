## Template Features

As we add new features to the template, please note them here so consumers of the template can discover them.

### Gradle

The project automatically is configured with gradle, and a gradle wrapper ("gradlew"). [What's a gradle wrapper? Here's the documentation.](https://docs.gradle.org/current/userguide/gradle_wrapper.html)

Gradle provides a unified structure for executing project commands. To see what commands are currently configured with this or any gradle project, you can always run `./gradlew tasks --all` and it will list for you all available tasks.

Most commonly, `./gradlew assemble` will assemble any artifacts for the given project, and `./gradlew check` will run all validations required for the project.

As more features are added to the template project, it is likely these will each have associated tasks.

### Docker and Docker Compose

The template provides Docker and Docker Compose files to build and run your service.

You can run `docker-compose up` and have it build and run in a docker container.

### JUnit, AssertJ

For testing purposes, the template includes [JUnit Jupiter (aka JUnit5)](https://junit.org/junit5/docs/current/user-guide/) as its core test runner. Also included is the [AssertJ core library](https://assertj.github.io/doc/).

AssertJ is a slick alternative to standard JUnit assertions, that allow extensible fluency.

For example:

    assertThat(result).isEqualTo(expected);

    Optional<Thing> optionalResult = ...
    assertThat(optionalResult).hasValue(expectedResult);

    assertThat(optionalResult).isEmpty();

    assertThat(listResult).contains(expectedEntity);

These are all assertions that include matchers that are context-appropriate based on the type of the value provided to `assertThat`.

For information about how to extend AssertJ and add project-specific assertions, see [here](https://assertj.github.io/doc/#assertj-core-extensions).

### Spring Boot

The template automatically includes Spring Boot configuration.

### Spring Controller

The template includes GET implementations based on an '{{ cookiecutter.service_id }}' entity. 
