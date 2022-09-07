package com.happymoney.helloworld;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest
class {{ cookiecutter.service_id|replace('-', '') }}Test {

    @Test
    void contextLoads() {
    }

}
