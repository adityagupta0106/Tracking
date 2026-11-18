package com.serviceplus.tracking.feignClient;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;


import java.util.Map;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;

import org.springframework.web.bind.annotation.RequestHeader;


@FeignClient(name = "UserManagement", path = "/usermgmt", url = "${usermanagement.service.url}")
public interface UserManagmentFeignClient {

	@GetMapping("/checkUserAssigned")
	public ResponseEntity<?> checkUserAssigned(@RequestParam String userToken ,@RequestParam Long userId);

	  // Reference-based email tracking OTP
    @PostMapping("/internal/tracking/otp/send/email")
    ResponseEntity<Map<String, Object>> sendTrackingEmailOtp(
            @RequestBody Map<String, Object> request);

    // Verify tracking OTP
    @PostMapping("/internal/tracking/otp/verify")
    ResponseEntity<Map<String, Object>> verifyTrackingOtp(
            @RequestBody Map<String, Object> request);

    // Mobile / Email tracking OTP
    @PostMapping("/internal/tracking/otp/send")
    ResponseEntity<Map<String, Object>> sendTrackingOtp(
            @RequestBody Map<String, Object> request);
    
    // Chatbot Email API - Without login 
    @PostMapping("/internal/chatbot/document/email")
    ResponseEntity<Map<String, Object>> sendChatbotDocumentEmail(@RequestBody Map<String, Object> request);
}
