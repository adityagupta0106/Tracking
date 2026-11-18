
package com.serviceplus.tracking.dto;

import java.time.LocalDateTime;
import java.util.Date;

public record SlaApplicationResponse(
        String applId,
        String applRefNo,
        Integer serviceId,
        String serviceName,
        String taskId,
        String taskName,
        String formId,
        String currentProcessId,
        Date applRecievedOn,
        Integer locationId,
        Boolean isPriority,
        LocalDateTime dueDate,
        String slaStatus,
        long daysOverdue
) {
}
