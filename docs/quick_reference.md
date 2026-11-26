# Quick Reference Card - Curso n8n + Dify

> **Entorno Lab**: Ubuntu 24.04 | **IP real**: `<IP_DE_TU_SERVIDOR>` (ej. `192.168.1.100`) | Configurada en `.env.lab` como `LAB_HOST`

---

## 🌐 URLs de Acceso

| Servicio | URL | Credenciales |
|----------|-----|--------------|
| **Docs Curso** | `http://<IP_DE_TU_SERVIDOR>/docs/` | Pública |
| **n8n** | `http://<IP_DE_TU_SERVIDOR>/n8n/` | `admin` / `n8n_lab_2026` |
| **Dify** | `http://<IP_DE_TU_SERVIDOR>/dify/` | `admin@lab.local` / `dify_lab_2026` |
| **n8n Webhooks** | `http://<IP_DE_TU_SERVIDOR>/n8n/webhook/` | - |
| **Dify API** | `http://<IP_DE_TU_SERVIDOR>/console/api/` | `Bearer <APP_API_KEY>` |

> ⚠️ **Dify primera vez**: Al abrir `http://<IP_DE_TU_SERVIDOR>/dify/` verás "Dify has not been initialized". Es normal → Completa el Setup Wizard en `/dify/install` (ver [Guía Laboratorios §0.6](guia_laboratorios_ubuntu24.md#06-dify-configuración-inicial-obligatoria-setup-wizard))

> 💡 **IP del servidor**: Configurada en `.env.lab` como `LAB_HOST=<IP_DE_TU_SERVIDOR>` (ej. `192.168.1.100`). nginx usa `envsubst` para sustituir `${LAB_HOST}` en la configuración.

---

## 🐳 Comandos Docker Esenciales

```bash
# Levantar stack
cd ~/curso-n8n
docker-compose -f docker-compose.lab.yml --env-file .env.lab up -d

# Ver estado
docker-compose -f docker-compose.lab.yml ps

# Logs tiempo real
docker-compose -f docker-compose.lab.yml logs -f n8n
docker-compose -f docker-compose.lab.yml logs -f dify-api

# Reiniciar servicio
docker-compose -f docker-compose.lab.yml restart n8n

# Backup workflows n8n
curl -H "Authorization: Basic $(echo -n 'admin:n8n_lab_2026' | base64)" \
  http://<IP_DE_TU_SERVIDOR>:5678/api/v1/workflows > backup-$(date +%Y%m%d).json

# Limpiar todo
docker-compose -f docker-compose.lab.yml down -v
```

---

## 🔧 Fixes Aplicados (Troubleshooting Rápido)

| Problema | Solución Aplicada |
|----------|-------------------|
| n8n: "secure cookie" error | `N8N_SECURE_COOKIE=false` |
| PostgreSQL: "role already exists" | Script `init-multiple-dbs.sh` idempotente |
| Dify web: OOM | `NODE_OPTIONS=--max-old-space-size=6144` + 8G limit |
| Dify API: "ERR_NAME_NOT_RESOLVED" | `CONSOLE_API_URL` via nginx proxy (puerto 80) |
| Static assets 404 (`/_next/...`) | Nginx `/_next/` y `/logo/` → `dify-web:3000` |
| Setup wizard 404 | Nginx `/install` → `dify-web:3000/install` |
| IP hardcodeada | Variable `LAB_HOST` en `.env.lab` + `envsubst` |
| docker-compose version warning | Eliminado `version:` obsoleto |

---

## 🔧 n8n - Expresiones Clave

| Qué | Sintaxis |
|-----|----------|
| Campo input actual | `{{ $json.campo }}` |
| Campo nodo anterior | `{{ $('Nombre Nodo').item.json.campo }}` |
| Condicional inline | `{{ cond ? 'a' : 'b' }}` |
| Default/fallback | `{{ $json.campo ?? 'default' }}` |
| Fecha actual ISO | `{{ $now.toISOString() }}` |
| Random string | `{{ $randomString(12) }}` |
| JSON stringify | `{{ JSON.stringify($json) }}` |

---

## 🎯 n8n - Nodos Imprescindibles

| Nodo | Uso |
|------|-----|
| **Manual Trigger** | Testing con Test Data JSON |
| **Webhook** | Entrada eventos (Path: `/webhook/...`) |
| **Set** | Validar, normalizar, construir objetos |
| **IF** | Boolean (True/False) o Value (múltiples ramas) |
| **Switch** | Múltiples ramas por valor de campo |
| **HTTP Request** | Llamar APIs (REST, GraphQL, webhooks) |
| **Merge (Wait)** | Unificar ramas tras IF/Switch |
| **Function** | Lógica JS compleja, validación, sanitización |
| **Respond to Webhook** | Respuesta síncrona (modo Response Node) |
| **Wait (Webhook)** | Pausa para aprobación humana |
| **Error Trigger** | Capturar errores → fallback controlado |

---

## 🤖 Dify - Tipos de App

| Tipo | Para qué | Control |
|------|----------|---------|
| **Chat Assistant** | Conversación guiada, clasificación, FAQ | Prompt sistema fijo |
| **Agent** | Tareas abiertas, planifica + usa tools | Tools allowlist + approval |
| **Workflow** | Pipeline IA determinista (extraer → clasificar → resumir) | Pasos fijos, output schema |
| **Knowledge Base** | RAG: indexar docs → recuperar → responder | Chunking + Retrieval config |

---

## 📝 Dify - System Prompt Template

```markdown
# ROLE
Eres un {{ROL}} especializado en {{DOMINIO}}.

# OBJECTIVE
{{OBJETIVO_CLARO}}

# CONTEXT
- Entorno: {{ENTORNO}}
- Herramientas: {{HERRAMIENTAS}}
- SLAs: {{SLAS}}

# INPUT VARIABLES
- `{{VAR_1}}`: {{DESC_1}}
- `{{VAR_2}}`: {{DESC_2}}

# CONSTRAINTS
1. NUNCA inventes datos. Si falta info → `unknown` + recomienda investigación.
2. SIEMPRE devuelve JSON válido según schema.
3. No acciones destructivas sin validación humana.
4. Cita fuentes: `source1`, `source2`, `inference`.

# OUTPUT FORMAT (JSON Schema)
{{JSON_SCHEMA_AQUI}}
```

---

## 🔐 Seguridad - Checklist Rápido

- [ ] **Credenciales** solo en n8n Credentials / Dify Secrets
- [ ] **Validación entrada** en primer nodo (n8n) / System Prompt (Dify)
- [ ] **Sanitización logs** antes de Slack/Email/Log (Function node)
- [ ] **Delimitadores** en System Prompt Dify: ```USER_INPUT_START``` ... ```USER_INPUT_END```
- [ ] **Allowlist tools** en Dify Agent (solo lectura sin approval)
- [ ] **Approval gate** (Wait node) para acciones que modifican estado
- [ ] **KB pre-scan** con truffleHog antes de indexar
- [ ] **Audit log** con correlation_id en cada ejecución

---

## 🧪 Testing - Mock Endpoints

| Qué | URL |
|-----|-----|
| HTTP POST echo | `https://httpbin.org/post` |
| HTTP GET echo | `https://httpbin.org/get` |
| Webhook capture | `https://webhook.site/#!/view/<TU_UUID>` |
| JSON placeholder | `https://jsonplaceholder.typicode.com/users/1` |
| Delay response | `https://httpbin.org/delay/3` |
| Status codes | `https://httpbin.org/status/200` (cambiar 200→400,500) |

---

## 📋 Estructura Workflow Estándar

```
[TRIGGER] → [VALIDATE/SANITIZE] → [ENRICH] → [DECIDE (IF/Switch)]
                                                    │
                              ┌─────────────────────┼─────────────────────┐
                              ▼                     ▼                     ▼
                         [ACTION 1]             [ACTION 2]            [FALLBACK]
                              │                     │                     │
                              └─────────────────────┼─────────────────────┘
                                                    ▼
                                            [MERGE (Wait)]
                                                    │
                                                    ▼
                                            [AUDIT LOG]
                                                    │
                                                    ▼
                                            [NOTIFY]
```

---

## 🚨 Troubleshooting Rápido

| Problema | Qué Mirar | Solución |
|----------|-----------|----------|
| n8n 502/timeout | `docker logs n8n` | Verificar PostgreSQL healthy, reiniciar n8n |
| Webhook 404 | n8n UI → Workflow Active? | Toggle Active ON + Save |
| Dify "Model error" | `docker logs dify-api` | Verificar API Key / Ollama running |
| Out of Memory | `free -h` / `docker stats` | Añadir swap 4GB |
| Puerto ocupado | `sudo lsof -i :5678` | Matar proceso o cambiar puerto |

---

## 📁 Archivos Clave del Repo

```
curso-n8n/
├── docker-compose.lab.yml    # Stack completo lab
├── .env.lab                  # Variables de entorno
├── init-multiple-dbs.sh      # Init PostgreSQL multi-DB
├── nginx.lab.conf            # Reverse proxy config
├── docs/
│   ├── temario_adaptado.md   # Temario + labs adaptados
│   ├── guia_laboratorios_ubuntu24.md  # Guía paso a paso
│   ├── workflow_doc_template.md       # Plantilla doc workflow
│   ├── security_policy_template.md    # Política seguridad
│   ├── quick_reference.md             # Esta hoja
│   └── modulos/              # 9 módulos teórico-prácticos
```

---

## ✅ Entregables por Módulo

| Módulo | Qué Entregar |
|--------|--------------|
| 1 | Tabla procesos candidatos + Mapa I-P-D-S + Matriz riesgo |
| 2 | Workflow `.json` + Execution Log verde + Capturas |
| 3 | Webhook funcionando + CMDB Mock + Audit log |
| 4 | Dify App exportada + System Prompt + Test cases |
| 5 | KB creada + Asistente RAG + Evaluación citas |
| 6 | n8n→Dify integrado + Approval gate funcionando |
| 7 | Workflow inseguro analizado + Versión segura + Policy firmada |
| 8 | Doc workflow (plantilla) + Go/No-Go + Métricas |
| 9 | Prototipo integrado + Test cases + Riesgos + Próximos pasos |

---

> **Tip**: Guarda esta hoja como favorito en tu navegador. Reemplaza `192.168.1.100` por la IP real de tu lab.