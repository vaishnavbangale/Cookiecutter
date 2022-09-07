package com.happymoney.helloworld.model.enums;

import lombok.Getter;

@Getter
public enum AccessScopes {

    HELLO_WORLD("test:helloworld", "SCOPE_test:helloworld");

    private final String scope;
    private final String scopeWithPrefix;

    AccessScopes(String scope, String scopeWithPrefix) {
        this.scope = scope;
        this.scopeWithPrefix = scopeWithPrefix;
    }

}
