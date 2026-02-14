package com.example.mtls.controller;

import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.security.Principal;
import java.util.HashMap;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api")
public class SecureController {

    @GetMapping("/hello")
    public ResponseEntity<Map<String, String>> hello(Principal principal) {
        log.info("Request from client: {}", principal.getName());

        Map<String, String> response = new HashMap<>();
        response.put("message", "Hello from secure endpoint!");
        response.put("authenticatedUser", principal.getName());
        response.put("timestamp", String.valueOf(System.currentTimeMillis()));

        return ResponseEntity.ok(response);
    }

    @GetMapping("/info")
    public ResponseEntity<Map<String, Object>> info(Principal principal) {
        log.info("Info request from client: {}", principal.getName());

        Map<String, Object> response = new HashMap<>();
        response.put("clientCN", principal.getName());
        response.put("authType", "Mutual TLS (2-Way Authentication)");
        response.put("secure", true);
        response.put("protocol", "HTTPS");

        return ResponseEntity.ok(response);
    }

    @GetMapping("/status")
    public ResponseEntity<Map<String, String>> status() {
        Map<String, String> response = new HashMap<>();
        response.put("status", "UP");
        response.put("service", "POC 2-Way Authentication");

        return ResponseEntity.ok(response);
    }
}
