package com.example.dogs.logging;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.time.Duration;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

/** Envoie les logs à l'API de logging via un client HTTP (RestTemplate). */
@Component
public class LogClient {

    private final RestTemplate restTemplate;
    private final String logsUrl;

    public LogClient(RestTemplateBuilder builder, @Value("${logs.api.url}") String logsUrl) {
        this.restTemplate = builder
                .connectTimeout(Duration.ofSeconds(2))
                .readTimeout(Duration.ofSeconds(2))
                .build();
        this.logsUrl = logsUrl;
    }

    public void send(String level, String message, String source) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("message", message);
        body.put("source", source);
        body.put("timestamp", Instant.now().toString());
        body.put("level", level);
        try {
            restTemplate.postForEntity(logsUrl, body, Void.class);
        } catch (Exception e) {
            // Une panne de l'API de logs ne doit jamais faire échouer l'API CRUD
            System.err.println("Impossible d'envoyer le log à " + logsUrl + " : " + e.getMessage());
        }
    }
}
