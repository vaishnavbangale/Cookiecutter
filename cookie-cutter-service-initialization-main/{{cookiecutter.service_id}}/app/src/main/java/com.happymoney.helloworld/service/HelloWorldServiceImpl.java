package com.happymoney.helloworld.service;

import com.happymoney.helloworld.controller.dto.HelloWorldResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class HelloWorldServiceImpl implements HelloWorldService {

    @Override
    public HelloWorldResponse getHelloWorld(String message) {
        return HelloWorldResponse.builder().message(message).build();
    }


}
