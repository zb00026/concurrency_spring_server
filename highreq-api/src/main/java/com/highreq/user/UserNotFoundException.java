package com.highreq.user;

public class UserNotFoundException extends RuntimeException {

    public UserNotFoundException(long id) {
        super("User not found: " + id);
    }
}
