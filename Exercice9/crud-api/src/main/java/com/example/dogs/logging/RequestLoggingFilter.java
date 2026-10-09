package com.example.dogs.logging;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

/**
 * Pour chaque appel /api/..., envoie un log à l'API de logging :
 * INFO (2xx/3xx), WARN (4xx) ou ERR (5xx / exception non gérée).
 */
@Component
public class RequestLoggingFilter extends OncePerRequestFilter {

    private final LogClient logClient;

    public RequestLoggingFilter(LogClient logClient) {
        this.logClient = logClient;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return !request.getRequestURI().startsWith("/api/");
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {
        String source = "[CrudAPI] " + request.getMethod() + " " + request.getRequestURI();
        try {
            chain.doFilter(request, response);
        } catch (Exception e) {
            logClient.send("ERR", e.getClass().getSimpleName() + ": " + e.getMessage(), source);
            throw e;
        }

        int status = response.getStatus();
        HttpStatus resolved = HttpStatus.resolve(status);
        String message = "HTTP " + status + (resolved != null ? " " + resolved.getReasonPhrase() : "");
        String level = status >= 500 ? "ERR" : status >= 400 ? "WARN" : "INFO";
        logClient.send(level, message, source);
    }
}
