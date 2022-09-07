package com.happymoney.helloworld.controller;

import com.fasterxml.jackson.core.JsonProcessingException;

import lombok.RequiredArgsConstructor;
import com.happymoney.helloworld.controller.dto.HelloWorldResponse;
import com.happymoney.helloworld.service.HelloWorldService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/")
@RequiredArgsConstructor
public class HelloWorldController {

    @Autowired
    private HelloWorldService helloWorldService;

    @GetMapping(path = "helloworld", produces = "application/json")
    @ResponseBody
    public HelloWorldResponse getHelloWorld() {
        return helloWorldService.getHelloWorld("Hello World!");
    }
}
