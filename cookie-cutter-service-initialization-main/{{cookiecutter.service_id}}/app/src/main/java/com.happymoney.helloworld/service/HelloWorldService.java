package com.happymoney.helloworld.service;

import com.happymoney.helloworld.controller.dto.HelloWorldResponse;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public interface HelloWorldService {
    HelloWorldResponse getHelloWorld(String message);
}
