package com.serviceplus.tracking.service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;
import java.util.Collections;
import java.util.List;
import java.util.Set;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.serviceplus.tracking.ExceptionHandler.SPRuntimeError;
import com.serviceplus.tracking.dto.ServerSidePaginationRecord;
import com.serviceplus.tracking.dto.SlaApplicationResponse;
import com.serviceplus.tracking.dto.UserSessionDTO;
import com.serviceplus.tracking.entity.UserInbox;
import com.serviceplus.tracking.repository.UserInboxRepository;
import com.serviceplus.tracking.utility.CommonUtil;

import jakarta.servlet.http.HttpServletRequest;

@Service
public class SlaService {

    private final UserInboxRepository userInboxRepository;
    private final WorkflowInboxRedisService workflowInboxRedisService;

    public SlaService(
            UserInboxRepository userInboxRepository,
            WorkflowInboxRedisService workflowInboxRedisService) {

        this.userInboxRepository = userInboxRepository;
        this.workflowInboxRedisService = workflowInboxRedisService;
    }

    @Transactional(readOnly = true)
    public ServerSidePaginationRecord<SlaApplicationResponse> getApplications(
            HttpServletRequest request, int page, int size) {

        if (page < 0 || size < 1) {
            throw new SPRuntimeError("Invalid pagination", HttpStatus.BAD_REQUEST);
        }

        // 1. Same logged-in session as Workflow Inbox
        UserSessionDTO session =
                CommonUtil.getUserSessionDetails(request);

        if (session == null
                || session.getUserID() == null
                || session.getLocationId() == null
                || session.getTenantId() == null
                || session.getTenantId().isBlank()) {

            throw new SPRuntimeError(
                    "Invalid session", HttpStatus.UNAUTHORIZED);
        }

        int pageSize = Math.min(size, 50);

        // 2. Same Redis holder-token logic as Workflow Inbox
        Set<Object> tokens =
                workflowInboxRedisService.getTokensByUserAndLocation(
                        session.getUserID(),
                        String.valueOf(session.getLocationId()));

        if (tokens == null || tokens.isEmpty()) {
            return emptyResponse(page, pageSize);
        }

        List<String> tokenKeys = tokens.stream()
                .map(String::valueOf)
                .toList();

        // 3. All overdue + today + tomorrow
        LocalDate today =
                LocalDate.now(ZoneId.of("Asia/Kolkata"));

        LocalDateTime endDate =
                today.plusDays(2).atStartOfDay();

        // 4. Fetch pending inbox applications filtered by SLA
        Page<UserInbox> inboxPage =
        	    userInboxRepository.findSlaApplications(
        	        tokenKeys,
        	        endDate,
        	        PageRequest.of(page, pageSize)
        	    );
        // 5. Convert inbox data into SLA response
        ServerSidePaginationRecord<SlaApplicationResponse> response =
                new ServerSidePaginationRecord<>();

        response.setData(inboxPage.getContent().stream()
                .map(inbox -> buildSlaResponse(inbox, today))
                .toList());

        response.setTotalRecords(inboxPage.getTotalElements());
        response.setCurrentPage(inboxPage.getNumber());
        response.setPageSize(inboxPage.getSize());
        response.setTotalPages(inboxPage.getTotalPages());

        return response;
    }

    private SlaApplicationResponse buildSlaResponse(
            UserInbox inbox, LocalDate today) {

        long days = ChronoUnit.DAYS.between(
                inbox.getDueDate().toLocalDate(),
                today);

        String status;

        if (days > 0) {
            status = "OVERDUE";
        } else if (days == 0) {
            status = "DUE_TODAY";
        } else {
            status = "DUE_TOMORROW";
        }

        return new SlaApplicationResponse(
                inbox.getApplId(),
                inbox.getApplRefNo(),
                inbox.getServiceId(),
                inbox.getServiceName(),
                inbox.getTaskId(),
                inbox.getTaskName(),
                inbox.getFormId(),
                inbox.getCurrentProcessId(),
                inbox.getApplRecievedOn(),
                inbox.getLocationId(),
                inbox.getIsPriority(),
                inbox.getDueDate(),
                status,
                Math.max(0, days)
        );
    }

    private ServerSidePaginationRecord<SlaApplicationResponse> emptyResponse(
            int page, int size) {

        ServerSidePaginationRecord<SlaApplicationResponse> response =
                new ServerSidePaginationRecord<>();

        response.setData(Collections.emptyList());
        response.setTotalRecords(0);
        response.setCurrentPage(page);
        response.setPageSize(size);
        response.setTotalPages(0);

        return response;
    }
}