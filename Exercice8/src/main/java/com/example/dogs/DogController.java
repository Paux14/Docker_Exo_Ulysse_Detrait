package com.example.dogs;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/dogs")
public class DogController {

    private final DogRepository repository;

    public DogController(DogRepository repository) {
        this.repository = repository;
    }

    @GetMapping
    public List<Dog> list() {
        return repository.findAll();
    }

    @GetMapping("/{dogId}")
    public ResponseEntity<Dog> get(@PathVariable Long dogId) {
        return repository.findById(dogId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<Dog> create(@Valid @RequestBody Dog dog) {
        dog.setId(null); // l'ID est toujours généré par la base
        return ResponseEntity.status(HttpStatus.CREATED).body(repository.save(dog));
    }

    @PutMapping("/{dogId}")
    public ResponseEntity<Dog> update(@PathVariable Long dogId, @Valid @RequestBody Dog dog) {
        return repository.findById(dogId)
                .map(existing -> {
                    existing.setName(dog.getName());
                    existing.setBreed(dog.getBreed());
                    existing.setBirthDate(dog.getBirthDate());
                    existing.setSterilized(dog.isSterilized());
                    return ResponseEntity.ok(repository.save(existing));
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{dogId}")
    public ResponseEntity<Void> delete(@PathVariable Long dogId) {
        if (!repository.existsById(dogId)) {
            return ResponseEntity.notFound().build();
        }
        repository.deleteById(dogId);
        return ResponseEntity.noContent().build();
    }
}
