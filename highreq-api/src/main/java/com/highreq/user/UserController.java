package com.highreq.user;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/users")
public class UserController {

    private final UserService service;

    public UserController(UserService service) {
        this.service = service;
    }

    public record CreateUserRequest(
            @NotBlank(message = "name is required") String name,
            @NotBlank @Email(message = "email must be valid") String email) {
    }

    public record UserResponse(long id, String name, String email) {
        static UserResponse from(User u) {
            return new UserResponse(u.getId(), u.getName(), u.getEmail());
        }
    }

    @GetMapping("/{id}")
    public UserResponse get(@PathVariable long id) {
        return UserResponse.from(service.getUser(id));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public UserResponse create(@Valid @RequestBody CreateUserRequest request) {
        return UserResponse.from(service.createUser(request.name(), request.email()));
    }

    @GetMapping("/health")
    public Map<String, String> health() {
        return Map.of("status", "UP");
    }
}
