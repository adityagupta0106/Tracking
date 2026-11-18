package com.serviceplus.tracking.controller;

import com.serviceplus.tracking.service.SlaService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/a/sla")
public class SlaController {

    private final SlaService slaService;

    public SlaController(SlaService slaService) {
        this.slaService = slaService;
    }

    @GetMapping("/applications")
    public ResponseEntity<?> getApplications(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            HttpServletRequest request) {
    	System.out.println("SLA CONTROLLER HIT");

        return ResponseEntity.ok(slaService.getApplications(request, page, size));
    }
}