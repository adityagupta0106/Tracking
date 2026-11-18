package com.serviceplus.tracking.feignClient;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;

import com.serviceplus.tracking.dto.FormAttributeRequest;


import java.util.Map;
import org.springframework.web.bind.annotation.RequestHeader;

@FeignClient(name = "formDesigner", path = "/formmgmt", url = "${formdesigner.service.url}")
public interface FormDesignerFeignClient {

	@PostMapping("/filter-attributes")
	public ResponseEntity<?> getFilterAttributes(@RequestBody FormAttributeRequest formAttributeRequest);


	  // Internal tracking - Get submitted application data
    @PostMapping("/internal/tracking/application-data")
    ResponseEntity<Map<String, Object>> getTrackingApplicationData(
            @RequestBody Map<String, Object> request);

    // Internal tracking - Match OTP / Form Attributes
    @PostMapping("/internal/tracking/match")
    ResponseEntity<Map<String, Object>> matchTrackingApplications(
            @RequestBody Map<String, Object> request);
}
