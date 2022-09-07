package com.happymoney.helloworld.config;

import com.happymoney.helloworld.model.enums.AccessScopes;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.method.configuration.EnableGlobalMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configuration.WebSecurityConfigurerAdapter;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;
import java.util.Collections;

import static org.springframework.http.HttpMethod.DELETE;
import static org.springframework.http.HttpMethod.GET;
import static org.springframework.http.HttpMethod.HEAD;
import static org.springframework.http.HttpMethod.OPTIONS;
import static org.springframework.http.HttpMethod.PATCH;
import static org.springframework.http.HttpMethod.POST;
import static org.springframework.http.HttpMethod.PUT;

@Configuration
@EnableWebSecurity
@EnableGlobalMethodSecurity(
        securedEnabled = true, //enables @Secured annotation
        jsr250Enabled = true, //enables @RolesAllowed annotation
        prePostEnabled = true //enables @PreAuthorize, @PostAuthorize, @PreFilter, @PostFilter annotations
)
public class SecurityConfig extends WebSecurityConfigurerAdapter {
//    private static final String HELLO_WORLD = "/helloworld/**";

    private static final String[] PUBLIC_RESOURCES = {
            "/actuator/**",
            "/swagger-ui/**",
            "/swagger-ui.html",
            "/webjars/**",
            "/v2/**",
            "/swagger-resources/**",
            "/no-auth/**"
    };

    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http.cors().and().csrf().disable()

                // Set session management to stateless
                .sessionManagement()
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
                .and()
                .authorizeRequests()
                // TODO: Add example scopes here
//                .antMatchers(HttpMethod.GET, HELLO_WORLD).hasAuthority(AccessScopes.HELLO_WORLD.getScopeWithPrefix())
                .antMatchers(PUBLIC_RESOURCES).permitAll();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        final CorsConfiguration configuration = new CorsConfiguration();

        configuration.setAllowedOriginPatterns(Collections.singletonList("*"));
        configuration.setAllowedMethods(Arrays.asList(
                GET.name(),
                POST.name(),
                PUT.name(),
                DELETE.name(),
                PATCH.name(),
                OPTIONS.name(),
                HEAD.name()
        ));
        configuration.setAllowCredentials(true);
        configuration.setAllowedHeaders(Collections.singletonList("*"));

        final UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);

        return source;
    }

}
