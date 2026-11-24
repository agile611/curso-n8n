# Documentación de Workflow: {{WORKFLOW_NAME}}

> **Versión**: {{VERSION}} | **Fecha**: {{DATE}} | **Autor**: {{AUTHOR}} | **Estado**: {{STATUS}}

---

## 1. Resumen Ejecutivo

| Campo | Valor |
|-------|-------|
| **Nombre** | {{WORKFLOW_NAME}} |
| **ID n8n** | {{N8N_WORKFLOW_ID}} |
| **Versión** | {{VERSION}} (SemVer) |
| **Entorno** | Lab / Staging / Production |
| **Propietario** | {{OWNER_TEAM}} |
| **Criticalidad** | Baja / Media / Alta / Crítica |

**Descripción breve (2-3 líneas):**
> {{SHORT_DESCRIPTION}}

---

## 2. Arquitectura y Flujo

### 2.1 Diagrama de Alto Nivel

```mermaid
flowchart LR
    A[{{TRIGGER_TYPE}}] --> B[Validación]
    B --> C{Decisión}
    C -->|Rama 1| D[Acción 1]
    C -->|Rama 2| E[Acción 2]
    D --> F[Merge]
    E --> F
    F --> G[Audit Log]
    G --> H[Notificación]
```

### 2.2 Componentes Principales

| Componente | Tipo | Descripción |
|------------|------|-------------|
| {{TRIGGER_NAME}} | Trigger | {{TRIGGER_DESC}} |
| {{VALIDATION_NODE}} | Set/Function | Validación y sanitización entrada |
| {{DECISION_NODE}} | IF/Switch | Lógica de routing |
| {{ACTION_NODES}} | HTTP Request / Slack / etc | Acciones deterministas |
| {{MERGE_NODE}} | Merge (Wait) | Unificación ramas |
| {{AUDIT_NODE}} | Set + HTTP/DB | Registro auditoría |
| {{NOTIFY_NODE}} | Slack/Email/Webhook | Notificación resultado |

---

## 3. Contrato de Entrada (Input Schema)

### 3.1 Trigger: {{TRIGGER_TYPE}}

```json
{
  "{{FIELD_1}}": "{{TYPE_1}}",
  "{{FIELD_2}}": "{{TYPE_2}}",
  "{{FIELD_3}}": "{{TYPE_3}}"
}
```

### 3.2 Campos Obligatorios

| Campo | Tipo | Validación | Ejemplo |
|-------|------|------------|---------|
| `{{REQ_FIELD_1}}` | string | Required, minLength: 1 | `"{{REQ_EXAMPLE_1}}"` |
| `{{REQ_FIELD_2}}` | string | Required, enum: [a,b,c] | `"{{REQ_EXAMPLE_2}}"` |

### 3.3 Campos Opcionales

| Campo | Tipo | Default | Descripción |
|-------|------|---------|-------------|
| `{{OPT_FIELD_1}}` | string | `"{{OPT_DEFAULT_1}}"` | {{OPT_DESC_1}} |

---

## 4. Contrato de Salida (Output Schema)

### 4.1 Respuesta Exitosa

```json
{
  "status": "success",
  "execution_id": "{{EXECUTION_ID}}",
  "result": {
    "{{RESULT_FIELD_1}}": "{{RESULT_TYPE_1}}",
    "{{RESULT_FIELD_2}}": "{{RESULT_TYPE_2}}"
  },
  "audit": {
    "timestamp": "{{TIMESTAMP}}",
    "workflow": "{{WORKFLOW_NAME}}",
    "version": "{{VERSION}}"
  }
}
```

### 4.2 Respuesta de Error

```json
{
  "status": "error",
  "execution_id": "{{EXECUTION_ID}}",
  "error": {
    "code": "{{ERROR_CODE}}",
    "message": "{{ERROR_MESSAGE}}",
    "details": "{{ERROR_DETAILS}}"
  }
}
```

---

## 5. Dependencias Externas

| Sistema | Endpoint | Autenticación | Timeout | Retry Policy |
|---------|----------|---------------|---------|--------------|
| {{EXT_SYS_1}} | `{{EXT_URL_1}}` | {{EXT_AUTH_1}} | {{EXT_TIMEOUT_1}} | {{EXT_RETRY_1}} |
| {{EXT_SYS_2}} | `{{EXT_URL_2}}` | {{EXT_AUTH_2}} | {{EXT_TIMEOUT_2}} | {{EXT_RETRY_2}} |

---

## 6. Credenciales Utilizadas

| Credencial n8n | Tipo | Propósito | Rotación |
|----------------|------|-----------|----------|
| `{{CRED_1}}` | {{CRED_TYPE_1}} | {{CRED_PURPOSE_1}} | {{CRED_ROTATION_1}} |
| `{{CRED_2}}` | {{CRED_TYPE_2}} | {{CRED_PURPOSE_2}} | {{CRED_ROTATION_2}} |

> ⚠️ **NUNCA** hardcodear credenciales en el workflow. Usar siempre n8n Credentials.

---

## 7. Manejo de Errores y Fallbacks

| Escenario | Detección | Acción | Fallback |
|-----------|-----------|--------|----------|
| Validación falla | IF Valid = false | Respuesta 400 + Log | - |
| API externa timeout | Error Trigger | Reintento (3x, backoff) | Cola dead-letter + Alerta |
| API externa 5xx | Error Trigger | Circuit Breaker | Respuesta degradada + Alerta |
| Dify no responde | Error Trigger | Clasificación por reglas | Ticket genérico + Escalado |

---

## 8. Auditoría y Trazabilidad

### 8.1 Campos de Audit Log

```json
{
  "timestamp": "{{TIMESTAMP}}",
  "workflow_id": "{{N8N_WORKFLOW_ID}}",
  "workflow_name": "{{WORKFLOW_NAME}}",
  "workflow_version": "{{VERSION}}",
  "execution_id": "{{EXECUTION_ID}}",
  "trigger_type": "{{TRIGGER_TYPE}}",
  "input_hash": "{{SHA256_INPUT}}",
  "status": "success|error|partial",
  "duration_ms": "{{DURATION}}",
  "actions_taken": ["{{ACTION_1}}", "{{ACTION_2}}"],
  "external_calls": [
    {"system": "{{SYS_1}}", "status": "success", "latency_ms": "{{LAT_1}}"},
    {"system": "{{SYS_2}}", "status": "error", "latency_ms": "{{LAT_2}}"}
  ],
  "error_details": "{{ERROR_IF_ANY}}",
  "approved_by": "{{APPROVER_IF_ANY}}",
  "approval_timestamp": "{{APPROVAL_TS_IF_ANY}}"
}
```

### 8.2 Destino de Logs

- **Primario**: {{AUDIT_DESTINATION_1}} (ej. Elasticsearch / Loki / DB)
- **Secundario**: {{AUDIT_DESTINATION_2}} (ej. File / S3 / Splunk)

---

## 9. Métricas y SLOs

| Métrica | Target | Actual (Piloto) | Fuente |
|---------|--------|-----------------|--------|
| **Disponibilidad** | 99.9% | {{AVAIL_ACTUAL}}% | n8n / Prometheus |
| **Latencia P95** | < 5s | {{LATENCY_P95}}s | n8n Execution Log |
| **Tasa Error** | < 1% | {{ERROR_RATE}}% | n8n / Audit Log |
| **Throughput** | {{THROUGHPUT_TARGET}}/min | {{THROUGHPUT_ACTUAL}}/min | n8n |

---

## 10. Pruebas de Regresión

| Test Case | Input | Expected Output | Status |
|-----------|-------|-----------------|--------|
| TC-01: Happy Path | `{{TC01_INPUT}}` | `{{TC01_EXPECTED}}` | ☐ Pass / ☐ Fail |
| TC-02: Invalid Input | `{{TC02_INPUT}}` | 400 + Error JSON | ☐ Pass / ☐ Fail |
| TC-03: API Timeout | Mock 5s delay | Retry → Fallback | ☐ Pass / ☐ Fail |
| TC-04: Auth Expired | Invalid token | 401 + Alert | ☐ Pass / ☐ Fail |
| TC-05: Approval Required | `{{TC05_INPUT}}` | Wait → Approve → Execute | ☐ Pass / ☐ Fail |

---

## 11. Runbook de Incidencias

### 11.1 Síntomas Comunes

| Síntoma | Causa Probable | Acción Inmediata |
|---------|----------------|------------------|
| Workflow no ejecuta | Trigger inactivo / Webhook 404 | Verificar Active toggle / URL |
| Error 401 externo | Credenciales expiradas | Rotar credencial en n8n |
| Timeout recurrente | Sistema destino lento | Aumentar timeout / Circuit breaker |
| Datos corruptos | Validación insuficiente | Añadir validación + Reprocesar |

### 11.2 Escalado

| Nivel | Contacto | SLA Respuesta | Canal |
|-------|----------|---------------|-------|
| L1 - On-call | {{L1_CONTACT}} | 15 min | PagerDuty / Slack |
| L2 - Platform Lead | {{L2_CONTACT}} | 1 hora | Slack / Email |
| L3 - Arquitectura | {{L3_CONTACT}} | 4 horas | Email / Reunión |

---

## 12. Historial de Cambios (Changelog)

| Versión | Fecha | Autor | Cambios | Tipo |
|---------|-------|-------|---------|------|
| {{VERSION}} | {{DATE}} | {{AUTHOR}} | {{CHANGES}} | {{TYPE: major/minor/patch}} |

---

## 13. Checklist Go/No-Go (Para Piloto)

| Criterio | Target | Evidencia | ✅/❌ |
|----------|--------|-----------|------|
| Documentación completa | 100% | Este doc | ☐ |
| Test coverage | > 80% | CI Report | ☐ |
| Security Review | Aprobado | Checklist Módulo 7 | ☐ |
| Performance Test | P95 < 5s | Grafana | ☐ |
| Error Rate | < 1% | Audit Log | ☐ |
| Runbook Incidentes | Existe | Link | ☐ |
| On-call entrenado | Sí | Lista asistentes | ☐ |
| Rollback probado | Sí | Test report | ☐ |

---

## 14. Anexos

- [ ] Workflow exportado (`.json`) adjunto
- [ ] Diagramas Mermaid/draw.io fuente
- [ ] Postman collection para testing
- [ ] Datos de prueba anonimizados

---

> **Plantilla versión 1.0** - Adaptar según necesidades del proyecto. Mantener en control de versiones (Git) junto al workflow exportado.