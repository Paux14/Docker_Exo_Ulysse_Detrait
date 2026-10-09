package com.example.logs;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.List;

@RestController
@RequestMapping("/api/v1/logs")
public class LogController {

    private final LogRepository repository;

    public LogController(LogRepository repository) {
        this.repository = repository;
    }

    @GetMapping
    public List<LogEntry> list() {
        return repository.findAllByOrderByIdAsc();
    }

    @PostMapping
    public ResponseEntity<LogEntry> create(@Valid @RequestBody LogEntry entry) {
        entry.setId(null);
        if (entry.getTimestamp() == null) {
            entry.setTimestamp(Instant.now());
        }
        return ResponseEntity.status(HttpStatus.CREATED).body(repository.save(entry));
    }
}
