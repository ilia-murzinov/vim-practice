package com.example.service;

import com.example.dto.UserDto;
import com.example.dto.CreateUserRequest;
import com.example.entity.User;
import com.example.exception.UserNotFoundException;
import com.example.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final EmailService emailService;
    private final AuditService auditService;

    @Transactional(readOnly = true)
    public UserDto getUserById(UUID userId) {
        return userRepository.findById(userId)
                .map(this::toDto)
                .orElseThrow(() -> new UserNotFoundException(userId));
    }

    @Transactional(readOnly = true)
    public List<UserDto> getUsersByStatus(String status) {
        return userRepository.findAllByStatus(status)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public UserDto createUser(CreateUserRequest request) {
        validateEmail(request.getEmail());

        User user = User.builder()
                .id(UUID.randomUUID())
                .email(request.getEmail())
                .firstName(request.getFirstName())
                .lastName(request.getLastName())
                .status("ACTIVE")
                .createdAt(Instant.now())
                .build();

        User saved = userRepository.save(user);
        emailService.sendWelcomeEmail(saved.getEmail(), saved.getFirstName());
        auditService.record("USER_CREATED", saved.getId());

        return toDto(saved);
    }

    @Transactional
    public UserDto updateUser(UUID userId, CreateUserRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException(userId));

        user.setFirstName(request.getFirstName());
        user.setLastName(request.getLastName());
        user.setUpdatedAt(Instant.now());

        auditService.record("USER_UPDATED", userId);

        return toDto(userRepository.save(user));
    }

    @Transactional
    public void deleteUser(UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException(userId));

        user.setStatus("DELETED");
        user.setDeletedAt(Instant.now());
        userRepository.save(user);

        auditService.record("USER_DELETED", userId);
    }

    private void validateEmail(String email) {
        if (email == null || email.isBlank()) {
            throw new IllegalArgumentException("Email must not be blank");
        }
        if (!email.contains("@")) {
            throw new IllegalArgumentException("Invalid email format: " + email);
        }
        if (userRepository.existsByEmail(email)) {
            throw new IllegalArgumentException("Email already in use: " + email);
        }
    }

    private UserDto toDto(User user) {
        return UserDto.builder()
                .id(user.getId())
                .email(user.getEmail())
                .firstName(user.getFirstName())
                .lastName(user.getLastName())
                .status(user.getStatus())
                .createdAt(user.getCreatedAt())
                .build();
    }
}
