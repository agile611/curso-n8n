# Módulo 2: Primer workflow práctico con n8n

> **Duración:** 2 horas | **Formato:** Teoría (30 min) + Demo (15 min) + Labs (60 min) + Repaso (15 min)

---

## Objetivos del módulo

Al finalizar, los participantes podrán:

- Crear y ejecutar un **workflow completo** en n8n desde cero
- Usar **nodos esenciales**: Trigger, Set, IF, HTTP Request, Slack/Email
- **Transformar datos** entre pasos con expresiones n8n (`{{ $json... }}`)
- **Depurar ejecuciones** leyendo inputs/outputs de cada nodo
- Aplicar **buenas prácticas**: nombres, comentarios, organización

---

## 2.1 Creación de flujos visuales

### Estructura de un workflow y ejecución manual

> **Anatomía de un workflow n8n:**

```
┌─────────────────────────────────────────────────────────────────┐
│  WORKFLOW: "Clasificación Alertas Monitoring"                   │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐  │
│  │  START   │───▶│   SET    │───▶│    IF    │───▶│ HTTP REQ │  │
│  │ (Manual) │    │ Validar  │    │ Prioridad│    │  Jira    │  │
│  └──────────┘    └──────────┘    └────┬─────┘    └──────────┘  │
│                                       │                          │
│                              ┌────────┴────────┐                 │
│                              ▼                 ▼                 │
│                         ┌──────────┐      ┌──────────┐          │
│                         │  SLACK   │      │   SET    │          │
│                         │  (P1)    │      │  (Log)   │          │
│                         └──────────┘      └──────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

| Elemento | Descripción | Ejemplo |
|----------|-------------|---------|
| **Trigger/Start** | Punto de entrada (Manual, Webhook, Schedule, etc.) | `Manual Trigger` para testing |
| **Nodos de acción** | Hacen algo: HTTP Request, Slack, Email, DB | `HTTP Request` → Jira API |
| **Nodos de lógica** | Controlan flujo: IF, Switch, Merge, Split | `IF` → `{{ $json.severity === 'critical' }}` |
| **Nodos de datos** | Transforman: Set, Function, Code, Edit Fields | `Set` → normalizar campos |
| **Conexiones** | Flujo de datos (JSON) entre nodos | Output → Input |

> 💡 **Ejecución manual:** Botón **"Execute Workflow"** (play) → usa datos de test definidos en el trigger.

### Nodos básicos: trigger, edición de campos, condiciones y salida

#### 1. Trigger: Manual Trigger (para desarrollo/testing)

```json
// Datos de prueba en el nodo Manual Trigger
{
  "alertname": "DiskSpaceCritical",
  "instance": "prod-web-01",
  "severity": "critical",
  "value": "95%",
  "mountpoint": "/var/log",
  "timestamp": "2026-01-15T10:30:00Z"
}
```

#### 2. Set / Edit Fields: Validación y normalización

> **Nodo `Set` (recomendado sobre Edit Fields para nuevos workflows)**

| Campo | Valor (expresión n8n) | Explicación |
|-------|----------------------|-------------|
| `alert_name` | `{{ $json.alertname }}` | Copia directa |
| `host` | `{{ $json.instance }}` | Renombra |
| `severity_norm` | `{{ $json.severity.toLowerCase() }}` | Normaliza |
| `is_critical` | `{{ $json.severity === 'critical' }}` | Boolean para IF |
| `env` | `{{ $json.instance.startsWith('prod') ? 'production' : 'non-prod' }}` | Lógica condicional |
| `timestamp_iso` | `{{ $now.toISOString() }}` | Timestamp ejecución |

> 💡 **Expresiones útiles:**
> - `{{ $json.field }}` — Acceso a campo del input
> - `{{ $json.field.subfield }}` — Anidado
> - `{{ $json.array[0] }}` — Primer elemento array
> - `{{ $now }}` — Fecha actual (luxon DateTime)
> - `{{ $('Nombre Nodo').item.json.field }}` — Dato de **otro nodo** (referencia)

#### 3. IF: Condiciones y rutas alternativas

> **Configuración nodo IF:**

| Modo | Cuándo usar |
|------|-------------|
| **Boolean** | Una condición SÍ/NO → 2 salidas (True/False) |
| **Value** | Comparar campo contra valor → múltiples ramas |

**Ejemplo Boolean (True/False):**
```
Condition: {{ $json.is_critical === true }}
  ├─ True  → Rama crítica (P1)
  └─ False → Rama no crítica
```

**Ejemplo Value (múltiples ramas):**
```
Field: {{ $json.severity_norm }}
  ├─ "critical" → Rama P1
  ├─ "warning"  → Rama P2
  ├─ "info"     → Rama P3
  └─ Fallback   → Rama P4 (default)
```

#### 4. Salidas: HTTP Request, Slack, Email, Database

**HTTP Request (genérico, para cualquier API):**

| Configuración | Ejemplo Jira Create Issue |
|---------------|---------------------------|
| **Method** | POST |
| **URL** | `https://jira.tuempresa.com/rest/api/2/issue` |
| **Authentication** | Header Auth → `Authorization: Basic {{ $credentials.jiraBasicAuth }}` |
| **Headers** | `Content-Type: application/json` |
| **Body** | JSON (ver abajo) |

```json
// Body HTTP Request - Jira Create Issue
{
  "fields": {
    "project": { "key": "OPS" },
    "summary": "[AUTO] {{ $json.alert_name }} en {{ $json.host }}",
    "description": "Alerta automática desde monitoring\n\n**Detalles:**\n- Host: {{ $json.host }}\n- Severidad: {{ $json.severity }}\n- Valor: {{ $json.value }}\n- Mountpoint: {{ $json.mountpoint }}\n- Entorno: {{ $json.env }}\n- Timestamp: {{ $json.timestamp_iso }}",
    "issuetype": { "name": "Task" },
    "labels": ["auto", "monitoring", "{{ $json.env }}"],
    "components": [{ "name": "{{ $json.env === 'production' ? 'PROD' : 'NON-PROD' }}" }]
  }
}
```

**Slack (Post Message):**
| Campo | Valor |
|-------|-------|
| **Channel** | `#alertas-{{ $json.env }}` |
| **Text** | `🚨 *{{ $json.alert_name }}* en \`{{ $json.host }}\` ({{ $json.severity }})` |
| **Blocks** | JSON con formato rico (ver docs Slack Block Kit) |

---

### Transformación de datos entre pasos y lectura de resultados intermedios

> **Concepto clave:** **Cada nodo recibe JSON y devuelve JSON**. El output de un nodo = input del siguiente.

#### Flujo de datos típico

```
Manual Trigger (input test)
       │
       ▼
Set "Normalizar"          ──▶ Output: { alert_name, host, severity_norm, is_critical, env, timestamp_iso }
       │
       ▼
IF "Es crítica?"          ──▶ Input: output del Set. Evalúa {{ $json.is_critical }}
       │
       ├─ True  ▼
       │   HTTP Request "Jira P1"  ──▶ Output: { key: "OPS-1234", id: "12345", ... }
       │
       └─ False ▼
           HTTP Request "Jira P3"  ──▶ Output: { key: "OPS-1235", id: "12346", ... }
```

#### Acceder a datos de nodos anteriores (referencias cruzadas)

> 💡 **Sintaxis:** `{{ $('Nombre Exacto del Nodo').item.json.campo }}`

```javascript
// En un nodo POSTERIOR al IF, quiero el ticket key sea cual sea la rama:
{{ $('HTTP Request Jira P1').item.json.key ?? $('HTTP Request Jira P3').item.json.key }}

// O mejor: usar Merge node antes para unificar
```

#### Nodo Merge: Unificar ramas

| Modo | Uso |
|------|-----|
| **Append** | Concatenar arrays (varios items) |
| **Merge by Key** | Unir por campo común (ej. `host`) |
| **Wait** | Esperar a que lleguen TODAS las ramas conectadas |

> 📝 **Best practice:** "Siempre poned un **Merge (Wait)** después de un IF si los nodos siguientes necesitan datos de **ambas ramas**."

---

### Depuración de ejecuciones y análisis de errores frecuentes

#### Panel de ejecución (Execution Log)

> Al ejecutar, cada nodo muestra: **Input** | **Output** | **Status** (Success/Error/Waiting)

| Columna | Qué ver | Acción si error |
|---------|---------|-----------------|
| **Input** | JSON que recibió el nodo | ¿Faltan campos? ¿Formato incorrecto? |
| **Output** | JSON que devolvió | ¿Es el esperado? ¿Null/undefined? |
| **Status** | ✅ Success / ❌ Error / ⏳ Waiting | Click en Error → ver stack trace |

#### Errores frecuentes y soluciones

| Error | Causa típica | Solución |
|-------|--------------|----------|
| `Cannot read property 'field' of undefined` | Nodo anterior no devolvió ese campo | Verificar output del nodo anterior; usar `??` default |
| `401 Unauthorized` | Credenciales mal configuradas / expiradas | Revisar **Credentials** en n8n; probar con curl |
| `400 Bad Request` | JSON malformado / campos requeridos faltantes | Validar body con `JSON.parse()` en Function node previo |
| `ECONNREFUSED` / `ETIMEDOUT` | Red / firewall / URL incorrecta | Verificar conectividad desde contenedor n8n |
| `Expression evaluation failed` | Sintaxis `{{ }}` incorrecta | Probar expresión en nodo **Set** aislado |
| `Workflow execution timeout` | Nodo tarda > 300s (default) | Aumentar timeout en settings o usar async pattern |

#### Debugging pro-tips

> 💡 **Trucos para clase:**

1. **Nodo "Set" como breakpoint:** Insertad un Set vacío entre nodos para inspeccionar datos
2. **Console.log en Function node:**
   ```javascript
   console.log('DEBUG:', JSON.stringify(items[0].json, null, 2));
   return items;
   ```
3. **Execution history:** Sidebar izquierdo → "Executions" → ver últimas 50 ejecuciones con filtros
4. **Pin data:** En ejecución, click en pin 📌 en output → fija datos para siguiente ejecución manual

---

### Buenas prácticas de nombres, comentarios y organización del flujo

#### Convención de nombres (recomendada para el curso)

| Elemento | Convención | Ejemplo |
|----------|------------|---------|
| **Workflow** | `Dominio - Acción - Entorno` | `Monitoring - Alert Classification - Prod` |
| **Nodos acción** | `Verbo + Sustantivo + Detalle` | `HTTP Request - Jira Create Issue` |
| **Nodos lógica** | `Tipo + Condición` | `IF - Is Critical`, `Switch - Severity` |
| **Nodos datos** | `Set/Function + Propósito` | `Set - Normalize Alert`, `Function - Enrich CMDB` |
| **Credenciales** | `Servicio - Tipo - Entorno` | `Jira - Basic Auth - Prod`, `Slack - OAuth - Lab` |

#### Comentarios en nodos (Sticky Notes)

> **n8n permite añadir notas** (click derecho → Add Note). Usadlas para:

```
┌────────────────────────────────────────┐
│  ⚠️ VALIDACIÓN CRÍTICA                 │
│  Este IF decide P1 vs P3.              │
│  Si cambias la lógica, actualiza       │
│  el runbook en Confluence:             │
│  /wiki/spaces/OPS/pages/123456         │
└────────────────────────────────────────┘
```

#### Organización visual en canvas

> 💡 **Layout recomendado (left-to-right):**

```
[TRIGGER] → [VALIDACIÓN/SET] → [LÓGICA IF/SWITCH] → [ACCIONES] → [MERGE/LOG] → [NOTIFICACIÓN]
     │              │                  │                 │              │              │
  Entrada       Normaliza           Ramas             Ejecuta        Unifica       Avisa
```

- **Alinear nodos** (Shift + drag para multi-selección → align)
- **Agrupar con colores** (click derecho → Change Color): 🔴 Triggers, 🟢 Actions, 🔵 Logic, 🟡 Data, 🟣 Output
- **Evitar cruces de líneas** (reordenar nodos)

---

## 2.2 Automatización de una tarea técnica sencilla

### Flujo completo: Recepción → Validación → Clasificación → Respuesta → Trazabilidad

> **Escenario Lab 2.1:** Procesar solicitud técnica estructurada (ej. "Crear usuario en AD")

#### Paso a paso (para instructor - demo en vivo)

**1. RECEPCIÓN - Webhook Trigger (producción) / Manual Trigger (lab)**
```json
// Input esperado
{
  "request_id": "REQ-2026-001234",
  "request_type": "create_ad_user",
  "payload": {
    "username": "jgarcia",
    "display_name": "Juan García",
    "department": "IT",
    "manager": "mgonzalez",
    "groups": ["VPN_Users", "Developers"]
  },
  "requester": "helpdesk@tuempresa.com",
  "priority": "normal"
}
```

**2. VALIDACIÓN - Set + IF (campos obligatorios)**
```javascript
// Set: "Validar campos"
{
  "valid": true,
  "errors": [],
  "username": "{{ $json.payload.username }}",
  "display_name": "{{ $json.payload.display_name }}",
  "department": "{{ $json.payload.department }}",
  "manager": "{{ $json.payload.manager }}",
  "groups": "{{ $json.payload.groups }}"
}

// Function: "Validar obligatorios" (más potente que IF multiple)
const required = ['username', 'display_name', 'department', 'manager'];
const errors = required.filter(f => !$json[f] || $json[f].trim() === '');
return [{
  json: {
    ...$json,
    valid: errors.length === 0,
    errors: errors.map(e => `Campo obligatorio faltante: ${e}`)
  }
}];
```

**3. CLASIFICACIÓN - Switch (por request_type / priority)**
```
Switch on: {{ $json.request_type }}
  ├─ "create_ad_user" → Rama AD Create
  ├─ "disable_ad_user" → Rama AD Disable
  ├─ "reset_password" → Rama Password Reset
  └─ Default → Rama "Tipo no soportado" → Error response
```

**4. RESPUESTA - HTTP Request (API AD / PowerShell / Azure AD Graph)**
```json
// Body para Microsoft Graph Create User
{
  "accountEnabled": true,
  "displayName": "{{ $json.display_name }}",
  "mailNickname": "{{ $json.username }}",
  "userPrincipalName": "{{ $json.username }}@tuempresa.com",
  "passwordProfile": {
    "forceChangePasswordNextSignIn": true,
    "password": "{{ $randomString(12) }}"
  },
  "department": "{{ $json.department }}",
  "manager": { "id": "{{ $('Get Manager ID').item.json.id }}" }
}
```

**5. TRAZABILIDAD - Set + HTTP Request (Audit Log / DB / Notion / Sheet)**
```json
// Registro de auditoría
{
  "timestamp": "{{ $now.toISOString() }}",
  "workflow": "AD User Management",
  "request_id": "{{ $json.request_id }}",
  "action": "create_user",
  "target": "{{ $json.username }}",
  "status": "{{ $('HTTP Request Graph').item.json.id ? 'success' : 'failed' }}",
  "result_id": "{{ $('HTTP Request Graph').item.json.id ?? 'N/A' }}",
  "executed_by": "n8n-automation",
  "duration_ms": "{{ $execution.duration }}"
}
```

---

## 2.3 Prácticas (Labs)

### Lab 2.1 - Construir un workflow que procese una solicitud técnica estructurada

> **Duración:** 25 min | **Objetivo:** Workflow end-to-end funcional

#### Especificación

**Entrada (Manual Trigger test data):**
```json
{
  "ticket_id": "INC-2026-00042",
  "type": "access_request",
  "system": "github",
  "requester": "dev-team-lead",
  "details": {
    "username": "newdev01",
    "repositories": ["frontend-app", "backend-api"],
    "permission": "write",
    "justification": "Nuevo desarrollador sprint 12"
  },
  "priority": "high"
}
```

**Requisitos del workflow:**

1. **Validar** campos obligatorios: `ticket_id`, `type`, `system`, `username`, `repositories`
2. **Normalizar** `permission` a minúsculas, validar que sea `read` | `write` | `admin`
3. **Clasificar** por `system`: `github` → API GitHub, `jira` → API Jira, `aws` → API AWS
4. **Simular** la acción (HTTP Request a mock API o Function node que devuelve éxito)
5. **Registrar** en "audit log" (Set + Write Binary File local o HTTP a mock endpoint)
6. **Notificar** resultado por Slack (canal #lab-automation)

#### Criterios de aceptación

- [ ] Workflow se ejecuta sin errores con datos de test
- [ ] Validación rechaza input incompleto (rama error)
- [ ] Rama GitHub crea "PR simulado" con datos correctos
- [ ] Audit log contiene: ticket_id, username, system, status, timestamp
- [ ] Notificación Slack llega al canal de lab
- [ ] Nodos nombrados según convención, con notas explicativas

#### Estructura esperada (para instructor)

```
Manual Trigger
    │
    ▼
Set - Validate & Normalize
    │
    ▼
IF - Valid? ({{ $json.valid }})
    ├─ True → Switch - System
    │           ├─ github → HTTP Request - GitHub API (mock)
    │           ├─ jira   → HTTP Request - Jira API (mock)
    │           └─ aws    → HTTP Request - AWS API (mock)
    │
    └─ False → Set - Error Response → Slack - Notify Error
    │
    ▼ (Merge Wait)
Set - Build Audit Record
    │
    ▼
HTTP Request - Audit Log (mock endpoint)
    │
    ▼
Slack - Notify Result
```

> 💡 **Mock endpoint para labs:** Usar `https://httpbin.org/post` o `https://webhook.site/` para probar HTTP Requests sin APIs reales.

---

### Lab 2.2 - Añadir condiciones y rutas alternativas según prioridad o tipo de petición

> **Duración:** 20 min | **Extensión del Lab 2.1**

#### Nuevos requisitos

1. **Prioridad `critical`** → Notificación **inmediata** a `#critical-ops` + PagerDuty (simulado)
2. **Prioridad `low`** → Solo audit log, **sin notificación Slack** (batch diario)
3. **Tipo `emergency_access`** → Requiere **aprobación manual** (nodo `Wait` + `Manual Approval` simulado)
4. **Sistema no soportado** → Respuesta de error estructurada + alerta a equipo plataforma

#### Implementación sugerida

```javascript
// Set - Routing Logic (antes del Switch)
{
  "route": "{{ $json.priority === 'critical' ? 'critical' : $json.priority === 'low' ? 'batch' : 'standard' }}",
  "requires_approval": "{{ $json.type === 'emergency_access' }}",
  "notify_slack": "{{ $json.priority !== 'low' }}"
}

// IF - Requires Approval?
// True → Wait for Webhook (approval callback) → Continue
// False → Continue directly
```

> 📝 **Nota instructor:** "El nodo `Wait` en n8n permite pausar ejecución hasta webhook externo. Simulad aprobación con un 2º Manual Trigger o webhook.site."

---

### Lab 2.3 - Revisar el historial de ejecución y corregir errores introducidos intencionadamente

> **Duración:** 15 min | **Debugging guiado**

#### Ejercicio: "Caza de bugs"

El instructor proporciona un workflow **roto** (exportado `.json`) con estos errores intencionados:

| Bug # | Error | Síntoma | Cómo detectar |
|-------|-------|---------|---------------|
| 1 | Campo `username` mal referenciado (`{{ $json.user }}` en vez de `{{ $json.payload.username }}`) | `undefined` en HTTP Request | Ver Input del HTTP Request |
| 2 | IF condition: `{{ $json.priority = 'critical' }}` (asignación, no comparación) | Siempre True | Ver Output del IF → ambos ramas ejecutadas |
| 3 | Credenciales Slack apuntan a workspace incorrecto | `401 Unauthorized` | Execution log → Error details |
| 4 | Merge node en modo `Append` en vez de `Wait` | Datos duplicados / mezcla | Ver Output del Merge |
| 5 | Function node con `return items;` sin modificar (olvidaron transformar) | Datos sin procesar | Comparar Input vs Output del Function |

#### Metodología de debugging (enseñar en clase)

1. **Ejecutar** → Ver ejecución fallida en historial
2. **Click en nodo rojo** → Ver **Input** y **Error message**
3. **Comparar** con lo esperado (especificación)
4. **Corregir** expresión / configuración
5. **Re-ejecutar** (botón "Re-run" en ejecución fallida)
6. **Verificar** output completo end-to-end

> 💡 **Pro-tip:** "Usad **'Pin Data'** en la ejecución correcta → la siguiente ejecución manual usará esos datos fijos. Ideal para testear nodos finales sin re-ejecutar todo."

---

## Resumen del Módulo 2

| Concepto | Comando/Expresión clave |
|----------|------------------------|
| **Trigger test data** | Manual Trigger → "Test Data" JSON |
| **Acceso a campo** | `{{ $json.campo }}` |
| **Acceso a nodo previo** | `{{ $('Nombre Nodo').item.json.campo }}` |
| **Condicional inline** | `{{ cond ? 'a' : 'b' }}` |
| **Default/fallback** | `{{ $json.campo ?? 'default' }}` |
| **Fecha actual** | `{{ $now.toISOString() }}` |
| **Merge ramas** | Merge node → Mode: Wait |
| **Debug** | Execution Log → Input/Output/Error |

---

## 🔗 Siguiente: [Módulo 3: Eventos, webhooks e integración con sistemas](modulo-03-eventos-webhooks.md)

> **Preparad:** Endpoints de prueba (webhook.site, httpbin.org), credenciales API de lab, Postman/curl para testear webhooks.
