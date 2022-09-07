package com.happymoney.helloworld.integration;

import com.happymoney.helloworld.TestContainersBaseTest;
import org.junit.Test;

public class HelloWorldKafkaTest extends TestContainersBaseTest {

    // Dummy test to showcase testcontainer usage
    @Test
    public void testUsage() throws Exception {
        kafka.getBootstrapServers();
    }
}
