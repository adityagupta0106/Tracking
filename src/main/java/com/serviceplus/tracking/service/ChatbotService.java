
package com.serviceplus.tracking.service;

import static com.serviceplus.tracking.utility.CommonUtil.entityToString;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Duration;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.serviceplus.tracking.ExceptionHandler.SPRuntimeError;
import com.serviceplus.tracking.dto.LatestDocumentDownloadResponse;
import com.serviceplus.tracking.dto.SignedUrlResponse;
import com.serviceplus.tracking.dto.UserSessionDTO;
import com.serviceplus.tracking.entity.ApplicationDocumentTinyUrl;
import com.serviceplus.tracking.entity.ApplicationTracking;
import com.serviceplus.tracking.feignClient.FileManagementFeignClient;
import com.serviceplus.tracking.feignClient.InstanceConfigRegistryFeignClient;
import com.serviceplus.tracking.feignClient.UserManagmentFeignClient;
import com.serviceplus.tracking.repository.ApplicationDocumentTinyUrlRepository;
import com.serviceplus.tracking.repository.ApplicationTrackingDocumentRepository;
import com.serviceplus.tracking.repository.ApplicationTrackingRepository;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

@Service
public class ChatbotService {

    private static final Logger log = LoggerFactory.getLogger(ChatbotService.class);
    private static final String CLIENT_DOMAIN_HEADER = "SP-Client-Domain";
    private static final String GENERIC_ERROR = "Document email service unavailable";
    private static final Duration CLIENT_THROTTLE = Duration.ofSeconds(10);
    private static final Duration EMAIL_COOLDOWN = Duration.ofMinutes(30);

    private final ApplicationTrackingRepository trackingRepository;
    private final ApplicationTrackingDocumentRepository documentRepository;
    private final ApplicationDocumentTinyUrlRepository tinyUrlRepository;
    private final FileManagementFeignClient fileManagementFeignClient;
    private final UserManagmentFeignClient userManagementClient;
    private final InstanceConfigRegistryFeignClient instanceConfigClient;
    private final StringRedisTemplate redis;

    public ChatbotService(
            ApplicationTrackingRepository trackingRepository,
            ApplicationTrackingDocumentRepository documentRepository,
            ApplicationDocumentTinyUrlRepository tinyUrlRepository,
            FileManagementFeignClient fileManagementFeignClient,
            UserManagmentFeignClient userManagementClient,
            InstanceConfigRegistryFeignClient instanceConfigClient,
            StringRedisTemplate redis) {
        this.trackingRepository = trackingRepository;
        this.documentRepository = documentRepository;
        this.tinyUrlRepository = tinyUrlRepository;
        this.fileManagementFeignClient = fileManagementFeignClient;
        this.userManagementClient = userManagementClient;
        this.instanceConfigClient = instanceConfigClient;
        this.redis = redis;
    }

    // Existing logged-in API. Negative user IDs are allowed in this system.
    public LatestDocumentDownloadResponse downloadLatest(String applRefNo, UserSessionDTO user) {
        if (user == null || user.getUserID() == null
                || user.getTenantId() == null || user.getTenantId().isBlank()) {
            throw new SPRuntimeError("Authentication required", HttpStatus.UNAUTHORIZED);
        }
        if (applRefNo == null || applRefNo.isBlank()) {
            throw new SPRuntimeError("Application reference number is required", HttpStatus.BAD_REQUEST);
        }

        String reference = applRefNo.trim();
        String tenantId = user.getTenantId();

        if (trackingRepository.findByApplRefNoAndAppliedUserIdAndTenantIdOrderByProcessIdAsc(
                reference, user.getUserID(), tenantId).isEmpty()) {
            throw new SPRuntimeError("Application not found", HttpStatus.NOT_FOUND);
        }

        String uploadId = documentRepository.findLatestApplicantPermittedUploadId(reference, tenantId)
                .filter(id -> !id.isBlank())
                .orElseThrow(() -> new SPRuntimeError("Document not found", HttpStatus.NOT_FOUND));

        SignedUrlResponse signedUrl = fileManagementFeignClient.download(
                uploadId, Map.of("USER-DETAILS", entityToString(user)));

        if (signedUrl == null || signedUrl.getUrl() == null || signedUrl.getUrl().isBlank()) {
            throw new SPRuntimeError("Document download is unavailable", HttpStatus.BAD_GATEWAY);
        }

        return new LatestDocumentDownloadResponse(
                uploadId, signedUrl.getUrl(), signedUrl.getExpiresIn());
    }

    // Public chatbot API: send only an existing document link to the registered email.
    // The controller returns a generic response whether the application is eligible or not.
    public void sendDocumentLinkEmail(String applRefNo, HttpServletRequest request) {
        if (applRefNo == null || applRefNo.isBlank() || applRefNo.length() > 128) {
            log.debug("CHATBOT_EMAIL SKIPPED reason=INVALID_REFERENCE");
            return;
        }

        String clientDomain = request.getHeader(CLIENT_DOMAIN_HEADER);
        if (clientDomain == null || clientDomain.isBlank()) {
            log.debug("CHATBOT_EMAIL SKIPPED reason=CLIENT_DOMAIN_MISSING");
            return;
        }

        String tenantId = resolveTenantId(clientDomain);
        String reference = applRefNo.trim();
        String refTag = sha256(tenantId + "|" + reference).substring(0, 12);
        log.info("CHATBOT_EMAIL START tenantId={} refTag={}", tenantId, refTag);

        // Use hashed keys: do not expose reference numbers or client addresses in Redis keys.
        if (!reserve("chatbot:email:client:", tenantId + "|" + request.getRemoteAddr(), CLIENT_THROTTLE)) {
            log.info("CHATBOT_EMAIL SKIPPED reason=CLIENT_THROTTLE refTag={}", refTag);
            return;
        }

        if (!isCurrentlyDelivered(reference, tenantId)) {
            log.info("CHATBOT_EMAIL SKIPPED reason=NOT_DELIVERED refTag={}", refTag);
            return;
        }

        Optional<Long> userId = findApplicantUserId(reference, tenantId);
        Optional<String> documentId = documentRepository
                .findLatestApplicantPermittedUploadId(reference, tenantId)
                .filter(id -> !id.isBlank());

        if (userId.isEmpty() || documentId.isEmpty()) {
            log.info("CHATBOT_EMAIL SKIPPED reason=DATA_MISSING refTag={} applicantFound={} documentFound={}",
                    refTag, userId.isPresent(), documentId.isPresent());
            return;
        }

        String link = tinyUrlRepository
                .findFirstByDocumentIdAndReferenceNoAndTenantIdOrderByCrDateDesc(
                        documentId.get(), reference, tenantId)
                .map(ApplicationDocumentTinyUrl::getTinyUrl)
                .orElse(null);

        if (link == null || link.isBlank()) {
            log.info("CHATBOT_EMAIL SKIPPED reason=TINY_URL_MISSING refTag={}", refTag);
            return;
        }

        // Claim before dispatch: prevents concurrent duplicate sends.
        String cooldownKey = "chatbot:email:application:"
                + sha256(tenantId + "|" + reference);

        if (!Boolean.TRUE.equals(
                redis.opsForValue().setIfAbsent(cooldownKey, "1", EMAIL_COOLDOWN))) {
            log.info("CHATBOT_EMAIL SKIPPED reason=EMAIL_COOLDOWN refTag={}", refTag);
            return;
        }

        try {
            log.info("CHATBOT_EMAIL USERMANAGEMENT_DISPATCH refTag={}", refTag);
            ResponseEntity<Map<String, Object>> response =
                    userManagementClient.sendChatbotDocumentEmail(
                            Map.of(
                                    "userId", userId.get(),
                                    "tenantId", tenantId,
                                    "documentUrl", link
                            ));

            if (response == null
                    || !response.getStatusCode().is2xxSuccessful()
                    || response.getBody() == null
                    || !Boolean.TRUE.equals(response.getBody().get("accepted"))) {

                throw new SPRuntimeError(GENERIC_ERROR, HttpStatus.BAD_GATEWAY);
            }

            log.info("CHATBOT_EMAIL USERMANAGEMENT_ACCEPTED refTag={}", refTag);
        } catch (RuntimeException e) {
            log.error("CHATBOT_EMAIL USERMANAGEMENT_FAILED refTag={} errorType={}",
                    refTag, e.getClass().getSimpleName());
            try {
                redis.delete(cooldownKey);
            } catch (RuntimeException cleanupError) {
                log.warn("CHATBOT_EMAIL COOLDOWN_RELEASE_FAILED refTag={} errorType={}",
                        refTag, cleanupError.getClass().getSimpleName());
            }
            throw e;
        }
    }

    private String resolveTenantId(String clientDomain) {
        ResponseEntity<String> response = instanceConfigClient.fetchTenantId(
                Map.of(CLIENT_DOMAIN_HEADER, clientDomain));

        if (response == null || !response.getStatusCode().is2xxSuccessful()
                || response.getBody() == null || response.getBody().isBlank()) {
            throw new SPRuntimeError("Unable to resolve tenant", HttpStatus.BAD_GATEWAY);
        }
        return response.getBody().trim();
    }

    private boolean isCurrentlyDelivered(String reference, String tenantId) {
        return trackingRepository
                .findFirstByApplRefNoAndTenantIdAndActionTakenAndActionOnIsNotNullOrderByActionOnDescProcessIdDesc(
                        reference, tenantId, "Y")
                .filter(row -> {
                    String action = row.getActionName();
                    return Integer.valueOf(11).equals(row.getActionCode())
                            && action != null
                            && ("Deliver".equalsIgnoreCase(action.trim())
                                    || "Delivered".equalsIgnoreCase(action.trim()));
                })
                .isPresent();
    }

    private Optional<Long> findApplicantUserId(String reference, String tenantId) {
        List<Long> ids = trackingRepository.findByApplRefNoAndTenantIdOrderByProcessIdAsc(reference, tenantId)
                .stream()
                .filter(row -> "s_1".equals(row.getTaskId()))
                .map(ApplicationTracking::getAppliedUserId)
                .filter(id -> id != null)
                .distinct()
                .limit(2)
                .toList();

        return ids.size() == 1 ? Optional.of(ids.get(0)) : Optional.empty();
    }

    private boolean reserve(String prefix, String value, Duration ttl) {
        String key = prefix + sha256(value);
        // Redis unavailable => fail closed, not an unthrottled email sender.
        return Boolean.TRUE.equals(redis.opsForValue().setIfAbsent(key, "1", ttl));
    }

    private static String sha256(String value) {
        try {
            byte[] bytes = MessageDigest.getInstance("SHA-256")
                    .digest(value.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(bytes);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 unavailable", e);
        }
    }
}
