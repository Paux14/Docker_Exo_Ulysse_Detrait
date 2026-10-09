package com.example.logs;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.Instant;

@Entity
@Table(name = "logs")
public class LogEntry {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank
    @Column(length = 2000)
    private String message;

    @NotBlank
    private String source;

    // Reçu / renvoyé en JSON sous forme de chaîne ISO-8601 (ex: 2026-10-09T10:15:30Z)
    private Instant timestamp;

    @NotNull
    @Enumerated(EnumType.STRING)
    private LogLevel level;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }

    public String getSource() { return source; }
    public void setSource(String source) { this.source = source; }

    public Instant getTimestamp() { return timestamp; }
    public void setTimestamp(Instant timestamp) { this.timestamp = timestamp; }

    public LogLevel getLevel() { return level; }
    public void setLevel(LogLevel level) { this.level = level; }
}
