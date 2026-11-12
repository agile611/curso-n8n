# Módulo 3: Eventos, webhooks e integración con sistemas

> **Duración:** 2 horas | **Formato:** Teoría (30 min) + Demo (15 min) + Labs (60 min) + Repaso (15 min)

---

## Objetivos del módulo

Al finalizar, los participantes podrán:

- Diferenciar **tipos de triggers** y elegir según el patrón de integración
- Configurar **webhooks seguros** como punto de entrada de automatizaciones
- Consumir **APIs REST** desde n8n con autenticación, paginación y manejo de errores
- Diseñar **patrones de reintento, fallback y circuit breaker** para resiliencia
- Implementar **validación de entradas** antes de llamar a sistemas externos

---

## 3.1 Automatización basada en eventos

### Diferencias entre ejecución manual, programada y disparada por evento

| Tipo de Trigger | Cuándo se ejecuta | Casos de uso típicos | Latencia |
|-----------------|-------------------|---------------------|----------|
| **Manual** | Usuario click "Execute" | Testing, desarrollo, runbooks ad-hoc | Inmediata (bajo demanda) |
| **Schedule (Cron)** | Expresión cron (ej. `0 6 * * *`) | Reportes diarios, limpieza, sincronización batch | Programada (minutos/horas) |
| **Webhook** | HTTP POST entrante | Alertas monitoring, Git push, Ticket creado, IoT | **Tiempo real** (<1s) |
| **Polling** | Intervalo fijo (n8n Trigger nodes) | APIs sin webhook, IMAP, FTP, DB changes | Intervalo (1-60 min) |
| **Queue/Message** | Mensaje en cola (RabbitMQ, Kafka, SQS) | Alto volumen, desacoplamiento, garantía entrega | Tiempo real |

> 💡 **Regla de decisión para clase:**
> - ¿Evento externo avisa? → **Webhook**
> - ¿No hay webhook disponible? → **Polling** (Schedule + HTTP Request)
> - ¿Alto volumen / garantía orden? → **Queue** (Kafka/SQS Trigger)
> - ¿Proceso batch nocturno? → **Schedule**

### Uso de webhooks como punto de entrada de automatizaciones

#### Configuración de Webhook en n8n

| Configuración | Valor recomendado | Explicación |
|---------------|-------------------|-------------|
| **Path** | `/webhook/alertas/monitoring` | Ruta única, semántica |
| **Method** | `POST` | Estándar para payloads |
| **Response Mode** | `On Received` (async) / `Response Node` (sync) | Ver abajo |
| **Authentication** | Header `X-Webhook-Token` / HMAC / Basic Auth | **Obligatorio en prod** |
| **Raw Body** | `true` | Para recibir JSON sin parsear n8n |

#### Modos de respuesta: Síncrono vs Asíncrono

> **Crítico para diseño de integraciones:**

| Modo | Comportamiento | Cuándo usar | Timeout |
|------|----------------|-------------|---------|
| **On Received** (async) | Responde `200 OK` **inmediatamente**, workflow continúa en background | Webhooks de alertas, eventos fire-and-forget, alta latencia esperada | N/A (inmediato) |
| **Response Node** (sync) | Espera a nodo `Respond to Webhook` → devuelve **su output** | APIs que esperan resultado, validaciones, enriquecimiento sincrónico | 300s (configurable) |

**Ejemplo Response Node (sync):**
```
Webhook → Set (validar) → IF (válido?) → HTTP Request (enriquecer) → Respond to Webhook
                                                            │
                                              ┌─────────────┴─────────────┐
                                              ▼                           ▼
                                         True (200 OK)              False (400 Bad Request)
                                         { "status": "ok",          { "error": "invalid",
                                           "data": {...} }             "details": [...] }
```

> ⚠️ **Advertencia:** "Si usáis **Response Node** y el workflow falla antes de llegar al nodo → el caller recibe **500/timeout**. Siempre poned **Error Trigger** → `Respond to Webhook` con error controlado."

#### Seguridad de webhooks (checklist obligatorio)

```yaml
# Checklist para cada webhook en producción
webhook_security:
  - authentication: "HMAC-SHA256 (firma payload) O Header Token rotativo"
  - ip_whitelist: "Solo IPs conocidas (monitoring, GitLab, etc.)"
  - rate_limit: "n8n global + reverse proxy (nginx/traefik)"
  - payload_validation: "Schema JSON (ajv) en primer Set node"
  - replay_protection: "Timestamp + nonce en header, verificar ventana 5min"
  - logging: "Log request ID, IP, timestamp, hash payload (sin secrets)"
  - tls: "Solo HTTPS, cert válido, HSTS"
```

> 💡 **HMAC ejemplo (n8n Function node para verificar):**
```javascript
const crypto = require('crypto');
const secret = $credentials.webhookHmacSecret; // Guardado en Credentials
const signature = $request.headers['x-webhook-signature'];
const payload = JSON.stringify($request.body);

const expected = 'sha256=' + crypto.createHmac('sha256', secret)
  .update(payload).digest('hex');

if (signature !== expected) {
  throw new Error('Invalid webhook signature');
}
return items;
```

### Procesamiento síncrono y asíncrono en escenarios corporativos

| Escenario | Patrón recomendado | Justificación |
|-----------|-------------------|---------------|
| **Alerta monitoring → Ticket** | Async (On Received) | Fire-and-forget, no bloquear monitoring |
| **Git push → Deploy preview** | Sync (Response Node) | Caller (CI/CD) espera URL preview |
| **Ticket creado → Enriquecer CMDB** | Async | No bloquear creación ticket |
| **API interna → Validar + Transformar** | Sync | Contrato API: request/response |
| **Webhook pago → Procesar pedido** | Async + Idempotency Key | Procesamiento largo, evitar duplicados |
| **IoT sensor → Almacenar + Alertar** | Async | Alto volumen, latencia no crítica |

> 📝 **Idempotency Key pattern (async):**
> ```json
> // Header del caller: X-Idempotency-Key: "alert-12345-20260115"
> // n8n: Set node → Check Redis/DB si key existe
> //   Sí → Respond 200 "Already processed"
> //   No → Save key (TTL 24h) → Continue workflow
> ```

### Estrategias de reintento, tratamiento de errores y rutas de fallback

#### Configuración de reintento en n8n (nodo HTTP Request)

| Parámetro | Valor recomendado | Explicación |
|-----------|-------------------|-------------|
| **Retry On Fail** | `true` | Activar reintento |
| **Max Tries** | `3` | 1 intento + 2 reintentos |
| **Retry Interval** | `5000` (ms) | 5s entre intentos |
| **Retry On** | `5xx, 429, ECONNREFUSED, ETIMEDOUT` | Solo errores transitorios |

> ⚠️ **No reintentar:** `4xx` (salvo 429), errores de validación, auth fallida → son errores **permanentes**.

#### Patrones de resiliencia (para dibujar en pizarra)

```
┌────────────────────────────────────────────────────────────────────┐
│                    CIRCUIT BREAKER PATTERN                         │
│                                                                    │
│  HTTP Request                                                      │
│       │                                                            │
│       ├─ Success (2xx) ──▶ Continue                                │
│       │                                                            │
│       ├─ 4xx (client error) ──▶ IF → Log + Alert → Fallback       │
│       │                                                            │
│       └─ 5xx / Timeout ──▶ Retry (3x, 5s)                         │
│                            │                                       │
│                            ├─ Success ──▶ Continue                 │
│                            │                                       │
│                            └─ Fail ──▶ Circuit Breaker Check      │
│                                         │                          │
│                                         ├─ Open? ──▶ Fallback      │
│                                         │                          │
│                                         └─ Closed ──▶ Alert + Queue│
└────────────────────────────────────────────────────────────────────┘
```

#### Implementación práctica en n8n

**1. Fallback node (Set con valores por defecto):**
```json
// Set - Fallback Data (conectado a rama Error del HTTP Request)
{
  "source": "fallback",
  "data": {
    "host": "{{ $json.host }}",
    "status": "unknown",
    "message": "Sistema origen no disponible, usando cache/valores por defecto"
  },
  "timestamp": "{{ $now.toISOString() }}"
}
```

**2. Dead Letter Queue (DLQ) para errores no recuperables:**
```
HTTP Request (Error) → Set - Build DLQ Record → HTTP Request - DLQ API / DB / File
                                                              │
                                                    Incluir: request original, error, stack trace, timestamp, workflow ID
```

**3. Alerting on failure (paralelo al workflow principal):**
```
HTTP Request (Error) → Slack/Email/PagerDuty (async, no bloquea)
```

### Diseño de respuestas seguras y trazables

#### Contrato de respuesta estándar (para todos los webhooks sync)

```json
// Éxito
{
  "success": true,
  "request_id": "wf-{{ $execution.id }}-{{ $now.format('yyyyMMddHHmmss') }}",
  "data": { ... },
  "metadata": {
    "workflow": "Alert Classification",
    "version": "1.2.0",
    "duration_ms": "{{ $execution.duration }}",
    "timestamp": "{{ $now.toISOString() }}"
  }
}

// Error controlado
{
  "success": false,
  "request_id": "wf-{{ $execution.id }}-{{ $now.format('yyyyMMddHHmmss') }}",
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Campo 'host' obligatorio",
    "details": [{ "field": "host", "issue": "required" }]
  },
  "metadata": { ... }
}

// Error interno (Error Trigger → Respond to Webhook)
{
  "success": false,
  "request_id": "...",
  "error": {
    "code": "INTERNAL_ERROR",
    "message": "Error procesando solicitud",
    "reference": "ERR-{{ $now.format('yyyyMMddHHmmssSSS') }}"
  }
}
```

> 💡 **Logging estructurado (para SIEM/Splunk/ELK):**
> ```json
> // En Set node final o Function node de logging
> {
>   "log_level": "INFO",
>   "event_type": "workflow_execution",
>   "workflow_name": "{{ $workflow.name }}",
>   "execution_id": "{{ $execution.id }}",
>   "trigger_type": "webhook",
>   "source_ip": "{{ $request.ip }}",
>   "request_id": "{{ $request.headers['x-request-id'] ?? $execution.id }}",
>   "status": "success",
>   "duration_ms": "{{ $execution.duration }}",
>   "payload_hash": "{{ $sha256(JSON.stringify($request.body)) }}"
> }
> ```

---

## 3.2 Integraciones mediante APIs

### Conceptos prácticos de REST, JSON, cabeceras y tokens

> **Repaso rápido (5 min) - Para perfiles técnicos asumido conocido, pero refrescar:**

| Concepto | Qué es | Ejemplo n8n |
|----------|--------|-------------|
| **REST** | Estilo arquitectural: recursos + verbos HTTP | `GET /users/123`, `POST /tickets` |
| **JSON** | Formato intercambio (clave-valor, arrays, anidado) | Body requests/responses |
| **Headers** | Metadatos: Auth, Content-Type, Accept, Custom | `Authorization: Bearer <token>` |
| **Tokens** | Credenciales opacas (JWT, API Key, OAuth) | Guardados en **Credentials** n8n |
| **Status codes** | 2xx=OK, 4xx=Client error, 5xx=Server error | Manejo en IF/Error Trigger |

### Consumo de APIs desde n8n mediante peticiones HTTP

#### Nodo HTTP Request - Configuración completa

| Sección | Configuración | Ejemplo |
|---------|---------------|---------|
| **Authentication** | **Predefined Credential Type** | `Header Auth`, `OAuth2`, `API Key`, `Digest Auth` |
| **URL** | Base + path + query params | `https://api.github.com/repos/{{ $json.owner }}/{{ $json.repo }}/issues` |
| **Method** | GET, POST, PUT, PATCH, DELETE | Según operación |
| **Headers** | `Content-Type: application/json`, `Accept: application/json` | + custom headers |
| **Query Parameters** | Key/Value pairs (auto-encoded) | `per_page=100`, `state=open` |
| **Body** | JSON, Form, Raw, Binary | JSON para APIs REST |
| **Options** | Timeout, Follow Redirects, Reject Unauthorized | `Timeout: 30000` |

#### Gestión de credenciales (Best Practice)

> **NUNCA** pongáis tokens en el workflow. **SIEMPRE** usad **Credentials**.

```yaml
# Tipos de Credentials n8n más usados
credentials_types:
  - "Header Auth": "Authorization: Bearer <token> / Custom header"
  - "OAuth2 API": "Flujo completo (Google, GitHub, Azure, custom)"
  - "API Key": "Header o Query param (ej. X-API-Key)"
  - "Basic Auth": "user:pass → Base64"
  - "Digest Auth": "HTTP Digest"
  - "AWS Signature": "Para AWS APIs (S3, Lambda, etc.)"
```

**Crear Credential → Asignar en HTTP Request → Referenciar como `{{ $credentials.nombreCredencial }}`**

### Normalización de respuestas JSON para pasos posteriores

> **Problema:** Cada API devuelve formato distinto. **Solución:** Normalizar a **esquema interno** en Set/Function post-HTTP.

#### Ejemplo: GitHub Issues → Esquema interno unificado

```javascript
// Function node: "Normalize GitHub Issue"
const issue = items[0].json; // Response de GET /repos/{owner}/{repo}/issues

return [{
  json: {
    // Esquema interno estándar
    "source": "github",
    "source_id": issue.id.toString(),
    "title": issue.title,
    "description": issue.body ?? '',
    "status": issue.state === 'open' ? 'open' : 'closed',
    "priority": issue.labels?.some(l => l.name === 'critical') ? 'P1' :
                issue.labels?.some(l => l.name === 'urgent') ? 'P2' : 'P3',
    "assignee": issue.assignee?.login ?? null,
    "labels": issue.labels?.map(l => l.name) ?? [],
    "created_at": issue.created_at,
    "updated_at": issue.updated_at,
    "url": issue.html_url,
    // Metadatos de trazabilidad
    "fetched_at": new Date().toISOString(),
    "workflow_execution": $execution.id
  }
}];
```

#### Patrones de normalización comunes

| Patrón | Cuándo usar | Implementación |
|--------|-------------|----------------|
| **Flatten** | API devuelve objeto anidado profundo | Function node + lodash `_.flattenDeep` |
| **Array → Items** | API devuelve array, n8n necesita items separados | `Split In Batches` node o `Item Lists` |
| **Pagination** | API pagina resultados (cursor, offset, link header) | Loop: HTTP Request → Merge → IF hasNext → Repeat |
| **Schema mapping** | Mapear campos origen → destino | Set node con expresiones (ver arriba) |

### Separación de credenciales, variables y datos de prueba

#### Arquitectura de configuración (Environment-based)

```
┌─────────────────────────────────────────────────────────────┐
│                    WORKFLOW (código)                        │
│  - Lógica, nodos, expresiones                               │
│  - NO secrets, NO URLs hardcoded, NO datos reales           │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
       ┌────────────┐  ┌────────────┐  ┌────────────┐
       │CREDENTIALS │  │ VARIABLES  │  │ TEST DATA  │
       │ (Secrets)  │  │ (Config)   │  │ (Mock)     │
       ├────────────┤  ├────────────┤  ├────────────┤
       │ API Keys   │  │ Base URLs  │  │ Manual     │
       │ Tokens     │  │ Timeouts   │  │ Trigger    │
       │ Certs      │  │ Feature    │  │ "Test Data"│
       │            │  │ flags      │  │            │
       └────────────┘  └────────────┘  └────────────┘
              │               │               │
              ▼               ▼               ▼
       n8n Credentials   Workflow        Manual Trigger
       (encrypted)       Variables       (solo en editor)
       / Environment     (Settings)      / Pin Data
       Variables
```

#### Variables de entorno en n8n (Settings → Workflow Variables)

| Variable | Ejemplo | Uso en expresiones |
|----------|---------|-------------------|
| `API_BASE_URL` | `https://api.tuempresa.com/v1` | `{{ $vars.API_BASE_URL }}/tickets` |
| `DEFAULT_TIMEOUT` | `30000` | `{{ $vars.DEFAULT_TIMEOUT }}` |
| `ENABLE_DEBUG_LOG` | `true` | `{{ $vars.ENABLE_DEBUG_LOG === 'true' }}` |
| `SLACK_CHANNEL_ALERTS` | `#alertas-prod` | `{{ $vars.SLACK_CHANNEL_ALERTS }}` |

> 💡 **Variables por entorno:** n8n permite **Workflow Variables** que se sobrescriben al importar en otro entorno (dev/staging/prod).

### Validación de entradas antes de llamar a sistemas externos

#### Esquema de validación (JSON Schema + AJV en Function node)

```javascript
// Function node: "Validate Input Schema"
const Ajv = require('ajv');
const ajv = new Ajv({ allErrors: true, strict: false });

const schema = {
  type: 'object',
  required: ['ticket_id', 'type', 'payload'],
  properties: {
    ticket_id: { type: 'string', pattern: '^INC-\d{4}-\d{5}$' },
    type: { type: 'string', enum: ['access_request', 'incident', 'change'] },
    payload: {
      type: 'object',
      required: ['username', 'system'],
      properties: {
        username: { type: 'string', minLength: 3, maxLength: 32 },
        system: { type: 'string', enum: ['github', 'jira', 'aws', 'ad'] },
        priority: { type: 'string', enum: ['low', 'normal', 'high', 'critical'] }
      }
    }
  }
};

const validate = ajv.compile(schema);
const valid = validate(items[0].json);

if (!valid) {
  return [{
    json: {
      valid: false,
      errors: validate.errors.map(e => ({
        field: e.instancePath.replace('/', '') || e.schemaPath,
        message: e.message,
        value: e.data
      }))
    }
  }];
}

return [{ json: { ...items[0].json, valid: true } }];
```

#### Validación en capas (Defense in Depth)

| Capa | Qué valida | Dónde |
|------|------------|-------|
| **1. Webhook/Trigger** | Content-Type, tamaño max, firma HMAC | n8n Webhook settings + Function node inicial |
| **2. Esquema negocio** | Campos obligatorios, enums, formatos, rangos | Function node con AJV (ver arriba) |
| **3. Lógica de negocio** | Referencias existen (usuario en AD, repo en GitHub) | HTTP Request a APIs de validación + IF |
| **4. Sanitización** | Escape HTML, SQL injection, path traversal | Function node antes de usar en queries |

> ⚠️ **Regla:** "Validación temprana = fallo rápido = ahorro de recursos + mejor UX para caller."

---

## 3.3 Prácticas (Labs)

### Lab 3.1 - Crear un webhook que reciba una alerta o solicitud simulada

> **Duración:** 25 min | **Objetivo:** Webhook funcional end-to-end (sync + async)

#### Parte A: Webhook Síncrono (Request/Response)

**Especificación:**
- Path: `/webhook/lab/alert-sync`
- Method: POST
- Auth: Header `X-Lab-Token: {{ $vars.LAB_WEBHOOK_TOKEN }}`
- Input: JSON alerta (ver abajo)
- Output: Respuesta sincrónica con `request_id`, `status`, `enriched_data`

**Input test (Manual Trigger → Test Data):**
```json
{
  "alert_id": "ALERT-2026-001",
  "source": "prometheus",
  "alertname": "HighMemoryUsage",
  "instance": "prod-app-03",
  "severity": "warning",
  "value": "87%",
  "labels": {
    "team": "platform",
    "environment": "production",
    "service": "payment-api"
  },
  "annotations": {
    "summary": "Memory usage above 85%",
    "runbook_url": "https://wiki/runbooks/high-memory"
  },
  "startsAt": "2026-01-15T14:30:00Z"
}
```

**Pasos:**
1. Webhook Trigger (Response Mode: **Response Node**)
2. Set: Validar campos + normalizar severity
3. HTTP Request: Consultar CMDB mock (`https://httpbin.org/get?host={{ $json.instance }}`)
4. Set: Construir respuesta enriquecida
5. **Respond to Webhook** (con output del Set anterior)
6. **Error Trigger** → Respond to Webhook (error controlado)

**Criterios de aceptación:**
- [ ] POST a webhook devuelve 200 con JSON enriquecido en <3s
- [ ] Input inválido → 400 con error estructurado
- [ ] CMDB falla → 200 con `source: "fallback"` en respuesta
- [ ] Logs muestran request_id correlacionado

#### Parte B: Webhook Asíncrono (Fire-and-forget)

**Cambios:** Webhook Trigger → Response Mode: **On Received**
**Añadir:** Slack notification + Audit log (paralelo, no bloqueante)

---

### Lab 3.2 - Consultar una API de laboratorio y enriquecer la información recibida

> **Duración:** 25 min | **Objetivo:** Consumo API real + normalización + paginación

#### API de laboratorio: **JSONPlaceholder** (https://jsonplaceholder.typicode.com)

**Endpoints disponibles:**
- `GET /users` - Lista usuarios
- `GET /users/{id}` - Usuario por ID
- `GET /posts?userId={id}` - Posts de usuario
- `GET /comments?postId={id}` - Comentarios de post

#### Ejercicio: "Enriquecer alerta con datos de usuario responsable"

**Flujo:**
1. Webhook recibe alerta con `labels.team` (ej. "platform")
2. **Buscar usuario responsable** en `/users` (filtrar por `username` o email domain)
3. **Obtener posts recientes** del usuario (simula actividad reciente)
4. **Normalizar** a esquema interno
5. Responder (sync) o notificar (async)

**Implementación sugerida:**
```
Webhook → Set (extract team) → HTTP Request (GET /users) 
    → Function (filter user by team mapping) 
    → HTTP Request (GET /posts?userId={{ $json.id }}) 
    → Set (normalize) → Respond/Notify
```

**Mapeo team → user (mock):**
```javascript
// Function node: "Map Team to User"
const teamUserMap = {
  'platform': 'Bret',      // id: 1
  'backend': 'Antonette',  // id: 2
  'frontend': 'Samantha',  // id: 3
  'security': 'Karianne'   // id: 4
};
const team = items[0].json.labels?.team ?? 'platform';
const username = teamUserMap[team] ?? 'Bret';

// Buscar en items (output de GET /users)
const user = items[0].json.find(u => u.username === username);
return [{ json: { ...items[0].json, responsible_user: user } }];
```

**Criterios de aceptación:**
- [ ] Maneja paginación (JSONPlaceholder no pagina, pero añadir lógica `?_page=1&_limit=10`)
- [ ] Normaliza respuesta a esquema interno
- [ ] Si usuario no encontrado → fallback a "unassigned"
- [ ] Timeout 10s, reintento 2x en error 5xx

---

### Lab 3.3 - Generar una respuesta estructurada y registrar evidencias de ejecución

> **Duración:** 10 min | **Objetivo:** Trazabilidad completa + respuesta estándar

#### Requisitos de respuesta estructurada (contrato)

```json
// Respuesta estándar para TODOS los webhooks sync del curso
{
  "success": true,
  "request_id": "wf-<execution_id>-<timestamp>",
  "data": {
    "alert": { ... },           // Alerta original normalizada
    "enrichment": { ... },      // Datos de CMDB, usuario, etc.
    "actions_taken": [          // Qué hizo el workflow
      { "step": "cmdb_lookup", "status": "success", "duration_ms": 45 },
      { "step": "user_lookup", "status": "success", "duration_ms": 120 }
    ]
  },
  "metadata": {
    "workflow": "Alert Enrichment Lab",
    "version": "1.0.0",
    "execution_id": "{{ $execution.id }}",
    "duration_ms": "{{ $execution.duration }}",
    "timestamp": "{{ $now.toISOString() }}"
  }
}
```

#### Evidencias de ejecución (Audit Log)

**Destinos sugeridos para lab:**
1. **Archivo local** (Write Binary File node) → `/data/audit/{{ $execution.id }}.json`
2. **HTTP a mock** (httpbin.org/post o webhook.site)
3. **Google Sheets / Notion / Airtable** (si hay credenciales de lab)
4. **Console log** (Function node con `console.log`)

**Estructura evidencia:**
```json
{
  "evidence_id": "evt-{{ $execution.id }}-{{ $now.format('yyyyMMddHHmmssSSS') }}",
  "workflow": "Alert Enrichment Lab",
  "execution_id": "{{ $execution.id }}",
  "trigger": { "type": "webhook", "source_ip": "{{ $request.ip }}", "path": "{{ $request.path }}" },
  "input": { ... },           // Payload original (sanitizado sin secrets)
  "steps": [                  // Array de steps ejecutados
    { "node": "CMDB Lookup", "status": "success", "input": {...}, "output": {...}, "duration_ms": 45 },
    { "node": "User Lookup", "status": "success", "input": {...}, "output": {...}, "duration_ms": 120 }
  ],
  "output": { ... },          // Respuesta final
  "status": "success",
  "timestamp": "{{ $now.toISOString() }}"
}
```

> 💡 **Function node para construir evidencia (reutilizable):**
```javascript
// Function: "Build Evidence Record"
const evidence = {
  evidence_id: `evt-${$execution.id}-${Date.now()}`,
  workflow: $workflow.name,
  execution_id: $execution.id,
  trigger: { type: 'webhook', source_ip: $request?.ip, path: $request?.path },
  input: $json.original_input ?? $json,  // Guardar input original al inicio
  steps: $json.steps ?? [],              // Acumular en cada step
  output: $json.final_output ?? null,
  status: $json.final_status ?? 'in_progress',
  timestamp: new Date().toISOString()
};
return [{ json: evidence }];
```

---

## Resumen del Módulo 3

| Concepto | Clave |
|----------|-------|
| **Webhook Sync vs Async** | Response Node vs On Received |
| **Seguridad webhook** | HMAC + IP whitelist + Rate limit + Validación |
| **Reintentos** | Solo 5xx/429/timeout, max 3, backoff |
| **Fallback** | Set con valores por defecto en rama Error |
| **DLQ** | Capturar errores no recuperables para revisión |
| **Contrato respuesta** | `success`, `request_id`, `data`, `error`, `metadata` |
| **Credenciales** | Siempre en n8n Credentials, nunca en workflow |
| **Variables** | Workflow Variables para URLs, timeouts, feature flags |
| **Validación** | Capas: Trigger → Schema → Business Logic → Sanitización |
| **Evidencias** | Request ID correlacionado, steps array, input/output por step |

---

## 🔗 Siguiente: [Módulo 4: Asistentes y workflows de IA con Dify](modulo-04-asistentes-dify.md)

> **Preparad:** Acceso a Dify lab, API Key de aplicación, endpoint de modelo (OpenAI/Azure/Ollama), documentación técnica ficticia para RAG.
