package com.example.Java.Jenkins.CI.CD.Pipeline.controller;


import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class Controller {


    @GetMapping("/hello")
    public String Hello(){
        return "Hello from Devops Project";
    }

}
