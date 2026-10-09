package com.example.logs;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface LogRepository extends JpaRepository<LogEntry, Long> {

    List<LogEntry> findAllByOrderByIdAsc();
}
