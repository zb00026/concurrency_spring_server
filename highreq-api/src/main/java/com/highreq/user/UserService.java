package com.highreq.user;

import org.springframework.cache.annotation.CachePut;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserService {

    private final UserRepository repository;

    public UserService(UserRepository repository) {
        this.repository = repository;
    }

    /**
     * Hot-path read: cached in Caffeine so repeated reads never hit the DB.
     * In a multi-instance deployment this becomes Redis instead.
     */
    @Cacheable(cacheNames = "users", key = "#id")
    @Transactional(readOnly = true)
    public User getUser(long id) {
        return repository.findById(id)
                .orElseThrow(() -> new UserNotFoundException(id));
    }

    @CachePut(cacheNames = "users", key = "#result.id")
    @Transactional
    public User createUser(String name, String email) {
        return repository.save(new User(name, email));
    }
}
