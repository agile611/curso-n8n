# Guía de Laboratorios - Ubuntu 24.04 Server

> **Entorno**: Ubuntu 24.04 LTS | **IP ejemplo**: `192.168.1.100` | **Usuario**: `curso` | **IP real lab**: `130.117.95.60`

---

## 0. Preparación del Entorno (Pre-curso)

### 0.1 Conexión al Servidor

```bash
# Desde tu máquina local
ssh curso@130.117.95.60

# Verificar que estás en el entorno correcto
lsb_release -a
# Debería mostrar: Ubuntu 24.04.x LTS
```

### 0.2 Verificar Requisitos Mínimos

```bash
# Docker
docker --version
# Docker version 27.x.x, build xxx

# Docker Compose (usa docker-compose v1 o docker compose v2)
docker-compose version
# Docker Compose version v2.x.x  (o v1.x.x si tienes el binario clásico)

# Si solo tienes 'docker' pero no 'docker-compose', instala el plugin v2:
# sudo apt-get update && sudo apt-get install -y docker-compose-plugin
# Luego usa: docker compose version

# Recursos
free -h
# Mem: 8Gi+ disponible recomendado

df -h /
# 20GB+ libre en /
```

### 0.3 Clonar Repositorio y Preparar Archivos

```bash
cd ~
git clone https://github.com/agile611/curso-n8n.git
cd curso-n8n

# Crear archivo de variables de entorno (incluye LAB_HOST para IP dinámica)
cat > .env.lab << 'EOF'
LAB_HOST=130.117.95.60
POSTGRES_PASSWORD=n8n_lab_2026
REDIS_PASSWORD=redis_lab_2026
N8N_BASIC_AUTH_PASSWORD=n8n_lab_2026
N8N_ENCRYPTION_KEY=clave_secreta_32_chars_minimo!!
DIFY_SECRET_KEY=dify_secret_key_32_chars_minimo!!

# Model Provider (Opcional - si usas OpenAI/Azure)
# OPENAI_API_KEY=sk-xxxxxxxxxxxxx
# AZURE_OPENAI_API_KEY=xxxxxxxxxxxxx
# AZURE_OPENAI_ENDPOINT=https://xxxx.openai.azure.com
EOF

# Verificar archivos necesarios existen
ls -la docker-compose.lab.yml init-multiple-dbs.sh nginx.lab.conf.template envsubst.sh
```

### 0.4 Levantar Stack Completo

```bash
# Dar permisos al script de init DB y entrypoint nginx
chmod +x init-multiple-dbs.sh envsubst.sh

# Levantar todos los servicios
docker-compose -f docker-compose.lab.yml --env-file .env.lab up -d

# Verificar estado (esperar 2-3 min para healthy)
watch docker-compose -f docker-compose.lab.yml ps
# Todos deben mostrar: Up (healthy) o Up
```

### 0.5 Verificar Accesos Iniciales

```bash
# Desde tu navegador LOCAL (no en el servidor)
# Documentación: http://130.117.95.60/docs/  (o :8001)
# n8n: http://130.117.95.60/n8n/  (o :5678)
# Dify: http://130.117.95.60/dify/  (o :8080)

# Test rápido via curl desde el servidor
curl -s http://localhost:5678/healthz   # n8n
curl -s http://localhost/console/api/init   # Dify API (via nginx)
curl -s http://localhost:8001/          # Docs
```

### 0.6 ⚠️ Dify: Configuración Inicial Obligatoria (Setup Wizard)

> **IMPORTANTE**: Al acceder por primera vez a `http://130.117.95.60/dify/` (o `http://130.117.95.60:8080`), verás una página de error con el mensaje:
> > "Dify has not been initialized and installed yet. Please proceed with the initialization and installation process first."
>
> **Esto es NORMAL y ESPERADO**. Dify requiere un asistente de configuración inicial (Setup Wizard) la primera vez que se ejecuta.

#### Pasos del Setup Wizard (ejecutar UNA sola vez):

1. **Abrir en navegador**: `http://130.117.95.60/dify/install` (o `http://130.117.95.60:8080/install`)
2. **Click "Get Started"**
3. **Crear cuenta administrador**:
   - Email: `admin@lab.local` (o tu email)
   - Password: `dify_lab_2026`
   - Nombre: `Lab Admin`
4. **Configurar Workspace**:
   - Nombre: `Curso n8n Lab`
5. **Proveedor de Modelo (Opcional - se puede hacer después en Módulo 4)**:
   - Si tienes API Key de OpenAI/Azure → Configurar ahora
   - Si NO tienes → Click **"Skip"** (configurarás Ollama local en Módulo 4)
6. **Click "Finish"** → Acceso al Dashboard de Dify

> 💡 **Tip**: El setup solo se hace **una vez**. Después tendrás acceso completo al dashboard de Dify.

#### Credenciales de Laboratorio Dify (para referencia):

| Campo | Valor |
|-------|-------|
| **URL** | `http://130.117.95.60/dify/` (o `/dify/install` para setup) |
| **Email admin** | `admin@lab.local` |
| **Password admin** | `dify_lab_2026` |
| **Workspace** | `Curso n8n Lab` |

#### Verificar que Dify está listo:

```bash
# Test API health (debe devolver JSON, no HTML)
curl -s http://localhost/console/api/init

# Test via nginx proxy
curl -s http://localhost/dify/ | grep -c '__next_error__' && echo "Setup pendiente" || echo "Dify OK"
```

### 0.7 🔧 Fixes Aplicados (Troubleshooting Común)

Si encuentras problemas durante la instalación, estos son los fixes ya aplicados en el repositorio:

| Problema | Solución Aplicada |
|----------|-------------------|
| **n8n: "secure cookie" error** | `N8N_SECURE_COOKIE=false` en docker-compose.lab.yml |
| **PostgreSQL: "role already exists" error** | Script `init-multiple-dbs.sh` idempotente (CREATE IF NOT EXISTS) |
| **Dify web: OOM (out of memory)** | `NODE_OPTIONS=--max-old-space-size=6144` + límite 8G container |
| **Dify API: "net::ERR_NAME_NOT_RESOLVED"** | `CONSOLE_API_URL` usa nginx proxy (puerto 80) → `/console/api/` |
| **Static assets 404** (`/_next/...`, `/logo/...`) | Nginx locations `/_next/` y `/logo/` proxy a `dify-web:3000` |
| **Dify setup wizard 404** | Nginx location `/install` proxy a `dify-web:3000/install` |
| **n8n static assets 404** (`/static/...`, `/assets/...`) | Nginx locations `/static/` y `/assets/` proxy a `n8n:5678` |
| **IP hardcodeada** | Variable `LAB_HOST` en `.env.lab` + `envsubst` en nginx template |
| **docker-compose version warning** | Eliminado atributo `version:` obsoleto |

#### Comandos de Verificación Post-Instalación:

```bash
# Verificar todos los servicios
curl -s http://localhost:5678/healthz && echo "n8n: OK"
curl -s http://localhost/n8n/healthz && echo "nginx->n8n: OK"
curl -s -I http://localhost/static/prefers-color-scheme.css | grep -c "200" && echo "n8n static: OK"
curl -s -I http://localhost/assets/index-D6_HFhbh.js | grep -c "200" && echo "n8n assets: OK"
curl -s http://localhost/n8n/ | grep -c "n8n" && echo "n8n UI: OK"

curl -s http://localhost/console/api/init && echo "Dify API: OK"
curl -s http://localhost/dify/install | grep -c "Get Started" && echo "Dify Install: OK"
curl -s -I http://localhost/dify/ | grep -c "307" && echo "Dify redirect: OK"
curl -s -I http://localhost/_next/static/chunks/000sllnm6mfe0.css | grep -c "200" && echo "Dify static: OK"

curl -s http://localhost/docs/ | head -c 50 && echo "Docs: OK"
curl -s -I http://localhost/ | grep -c "302" && echo "Root redirect: OK"
```

---

## 1. Configuración Inicial n8n (Módulo 2)
| **Dify setup wizard 404** | Nginx location `/install` proxy a `dify-web:3000/install` |
| **IP hardcodeada** | Variable `LAB_HOST` en `.env.lab` + `envsubst` en nginx template |
| **docker-compose version warning** | Eliminado atributo `version:` obsoleto |

#### Comandos de Verificación Post-Instalación:

```bash
# Verificar todos los servicios
curl -s http://localhost:5678/healthz && echo "n8n: OK"
curl -s http://localhost/console/api/init && echo "Dify API: OK"
curl -s http://localhost/docs/ && echo "Docs: OK"
curl -s http://localhost/_next/static/chunks/000sllnm6mfe0.css -I | head -1 && echo "Static assets: OK"

# Verificar Dify setup
curl -s http://localhost/dify/install | grep -c 'Get Started' && echo "Install page: OK"
curl -s http://localhost/console/api/init | grep -c 'finished' && echo "Dify API: OK"
```

---

## 1. Configuración Inicial n8n (Módulo 2)

---

## 1. Configuración Inicial n8n (Módulo 2)

### 1.1 Primer Acceso y Credenciales de Lab

1. Abrir `http://192.168.1.100:5678`
2. Login: `admin` / `n8n_lab_2026`
3. Completar setup inicial (owner, email, password - puede ser mismo)

### 1.2 Crear Credenciales Reutilizables

**En n8n UI → Credentials → New Credential:**

| Tipo | Nombre | Configuración |
|------|--------|---------------|
| **HTTP Header Auth** | `Lab HTTP Auth` | Header: `Authorization` = `Bearer lab-token-2026` |
| **Webhook URL** | `Lab Webhook Site` | URL: `https://webhook.site/#!/view/<TU_UUID>` (crear uno en webhook.site) |
| **Slack API** | `Lab Slack` | Webhook URL: `https://webhook.site/#!/view/<OTRO_UUID>` |

> 💡 **Tip**: Cada alumno/grupo debe crear su propio webhook.site para no mezclar logs.

### 1.3 Crear Workflow "CMDB Mock" (Para Módulo 3)

1. **New Workflow** → Nombre: `Lab - CMDB Mock`
2. **Add Node** → **Webhook** → Path: `/cmdb` → Method: POST
3. **Add Node** → **IF** → Condition: `{{ $json.instance }}` **Exists**
4. **True Branch** → **Set** → Nombre: `CMDB Response`
   ```json
   {
     "host": "{{ $json.instance }}",
     "owner_team": "platform",
     "environment": "{{ $json.instance.startsWith('prod') ? 'production' : 'staging' }}",
     "service": "web-frontend",
     "runbook_url": "https://wiki.example.com/runbooks/{{ $json.instance }}",
     "recent_changes": ["Deploy v2.3.1 (2h ago)", "Config change (1d ago)"]
   }
   ```
5. **False Branch** → **Set** → Nombre: `Not Found`
   ```json
   {
     "error": "Host not found in CMDB",
     "host": "{{ $json.instance }}"
   }
   ```
6. **Merge** (Wait mode) → Conectar ambas ramas
7. **Respond to Webhook** → Status: 200 / 404 según rama
8. **Save** → **Activate** (toggle Active)

**Test:**
```bash
curl -X POST http://192.168.1.100:5678/webhook/cmdb \
  -H "Content-Type: application/json" \
  -d '{"instance": "prod-web-01"}'
```

---

## 2. Configuración Inicial Dify (Módulo 4-5)

### 2.1 Primer Acceso y Registro

1. Abrir `http://192.168.1.100:8080`
2. Registrar usuario admin (email, password)
3. Completar setup inicial de workspace

### 2.2 Configurar Model Provider

**Opción A: OpenAI / Azure (Requiere API Key real)**
1. Settings → Model Provider → OpenAI / Azure OpenAI
2. API Key: `[proporcionada por instructor]`
3. Base URL: `https://api.openai.com/v1` (o endpoint Azure)
4. Modelos: `gpt-4o-mini`, `text-embedding-3-small`

**Opción B: Ollama Local (Gratis, sin API Key)**
```bash
# En servidor lab (una sola vez)
docker run -d --name ollama \
  -p 11434:11434 \
  -v ollama_data:/root/.ollama \
  --restart unless-stopped \
  ollama/ollama:latest

# Descargar modelo (puede tardar 5-10 min)
docker exec -it ollama ollama pull llama3.1:8b
# O más ligero: docker exec -it ollama ollama pull qwen2.5:7b
```

Luego en Dify:
1. Settings → Model Provider → Ollama
2. Base URL: `http://192.168.1.100:11434`
3. Seleccionar: `llama3.1:8b` (chat) + `nomic-embed-text` (embedding)

### 2.3 Crear Knowledge Base para Labs (Módulo 5)

1. **Knowledge** → **Create Knowledge** → Nombre: `Lab Course Docs`
2. **Upload Files** → Seleccionar todos los `.md` de `~/curso-n8n/docs/modulos/`
3. **Chunk Settings**:
   - Chunk Size: `800`
   - Chunk Overlap: `100`
   - Separator: `Recursive (Markdown aware)`
4. **Retrieval Settings**:
   - Search Method: `Hybrid Search`
   - Top K: `5`
   - Rerank: `Enabled` (si modelo disponible)
5. **Save & Process** → Esperar indexing completo

### 2.4 Crear App "Lab Classifier" (Módulo 4)

1. **Studio** → **Create App** → **Chat Assistant**
2. Nombre: `Lab - Alert Classifier`
3. **System Prompt**: Copiar del Módulo 4 (plantilla completa)
4. **Variables** (en Start node):
   - `alert_json` (Text)
   - `cmdb_data` (Text, optional)
   - `runbook_summary` (Text, optional)
5. **Model**: Seleccionar proveedor configurado
6. **Publish** → **Run App** → Test con JSON de alerta de muestra

### 2.5 Obtener API Key para Integración n8n (Módulo 6)

1. App → **Settings** → **API Access**
2. **Generate API Key** → Copiar y guardar
3. Formato: `app-xxxxxxxxxxxxxxxxxxxxxxxx`

---

## 3. Datos de Prueba Comunes

### 3.1 alert-sample.json (Crear en ~/curso-n8n/)

```bash
cat > ~/curso-n8n/alert-sample.json << 'EOF'
{
  "alertname": "DiskSpaceCritical",
  "instance": "prod-web-01",
  "severity": "critical",
  "value": "95%",
  "mountpoint": "/var/log",
  "timestamp": "2026-01-15T10:30:00Z",
  "labels": {
    "environment": "production",
    "team": "platform",
    "service": "web-frontend"
  }
}
EOF
```

### 3.2 request-sample.json (Para Módulo 2)

```bash
cat > ~/curso-n8n/request-sample.json << 'EOF'
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
EOF
```

---

## 4. Guía Rápida por Módulo

### Módulo 2: Primer Workflow n8n

| Paso | Acción | Detalle |
|------|--------|---------|
| 1 | Crear workflow | Nombre: `Lab 2.1 - Process Tech Request` |
| 2 | Manual Trigger | Pegar `request-sample.json` en Test Data |
| 3 | Set (Validate) | Validar campos obligatorios, normalizar |
| 4 | IF (Valid?) | `{{ $json.valid === true }}` |
| 5 | Switch (System) | github / jira / aws / default |
| 6 | HTTP Request (Mock) | `https://httpbin.org/post` con credenciales Lab HTTP Auth |
| 7 | Merge (Wait) | Unificar ramas |
| 8 | Set (Audit) | Construir registro auditoría |
| 9 | HTTP Request (Audit) | `https://webhook.site/#!/view/<UUID>` |
| 10 | Slack (Notify) | Webhook Site URL |
| 11 | Save & Execute | Verificar en Execution Log |

**Test Webhook (Módulo 3):**
```bash
# Activar workflow con Webhook Trigger
# Path: /lab21/request
curl -X POST http://192.168.1.100:5678/webhook/lab21/request \
  -H "Content-Type: application/json" \
  -d @~/curso-n8n/request-sample.json
```

### Módulo 3: Webhooks y APIs

**Lab 3.1 - Webhook Alerta:**
1. Workflow: `Lab 3.1 - Alert Webhook`
2. Webhook Trigger: Path `/alertas/monitoring`, Method POST, Response Mode: On Received
3. Set: Validar + Sanitizar (Function node con sanitización Módulo 7)
4. HTTP Request → CMDB Mock: `http://192.168.1.100:5678/webhook/cmdb`
5. IF: Severity critical + env production → P1
6. HTTP Request → Dify Analysis (ver Módulo 6)
7. Respond to Webhook (si sync) o solo log (si async)

**Test:**
```bash
curl -X POST http://192.168.1.100:5678/webhook/alertas/monitoring \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Token: lab-token-2026" \
  -d @~/curso-n8n/alert-sample.json
```

### Módulo 4: Asistentes Dify

**Lab 4.1 - Asistente Clasificador:**
1. En Dify App "Lab - Alert Classifier" → Debug & Preview
2. Input:
   ```json
   {
     "alert_json": "{...alert-sample.json...}",
     "cmdb_data": "{...cmdb response...}",
     "runbook_summary": "Runbook: Disk Space - 1. Check logs 2. Clean old logs 3. Increase disk if needed"
   }
   ```
3. Verificar output JSON según schema definido
4. Probar variaciones: severity warning, instance no-prod, campos faltantes

### Módulo 5: RAG

**Lab 5.1 - Knowledge Base:**
1. Ya creada en 2.3 con docs del curso
2. Probar consultas:
   - "¿Qué es un workflow en n8n?"
   - "¿Cómo configurar webhook en n8n?"
   - "¿Diferencias entre n8n y Make?"
   - "¿Qué es RAG?" (fuera de alcance docs del curso)

**Lab 5.2 - Asistente RAG:**
1. Nueva App → Chat Assistant → Nombre: `Lab - Course Assistant`
2. Vincular Knowledge Base: `Lab Course Docs`
3. System Prompt: "Responde SOLO usando la base de conocimiento. Cita fuentes. Si no hay info → 'No tengo información suficiente en la documentación del curso.'"
4. Test mismas consultas + verificar citas [doc_1], [doc_2]

### Módulo 6: Orquestación n8n ↔ Dify

**Lab 6.1 - Conectar n8n → Dify Workflow:**

1. **En Dify**: Crear **Workflow** (no Chat App) → `Lab - Alert Analysis Workflow`
   - Start node: inputs `alert_json`, `cmdb_data`
   - LLM node: Clasificar + Recomendar (output JSON schema)
   - End node: Output estructurado
   - Publish → Obtener **Workflow Run URL**: `http://192.168.1.100:8080/v1/workflows/run`

2. **En n8n**: Workflow `Lab 6.1 - n8n to Dify`
   - Webhook Trigger: `/alert-processor`
   - HTTP Request → CMDB Mock
   - **HTTP Request → Dify Workflow**:
     - URL: `http://192.168.1.100:8080/v1/workflows/run`
     - Method: POST
     - Headers: `Authorization: Bearer app-xxxxxxxxxxxxx` (API Key Dify), `Content-Type: application/json`
     - Body:
       ```json
       {
         "inputs": {
           "alert_json": "{{ JSON.stringify($json) }}",
           "cmdb_data": "{{ JSON.stringify($('CMDB Mock').item.json) }}"
         },
         "response_mode": "blocking",
         "user": "n8n-lab"
       }
       ```
   - Parse Dify Response (Set/Function)
   - IF: `action_required` → Execution branches
   - Merge + Audit + Notify

**Lab 6.3 - Aprobación Humana:**
1. n8n **Wait Node** (Webhook mode)
   - Webhook URL: `http://192.168.1.100:5678/webhook/approval/{{ $execution.id }}`
   - Timeout: 3600 (1 hora)
2. Rama True (approved) → Ejecutar acción
3. Rama False/Timeout → Escalar / Notificar / Log

**Simular aprobación:**
```bash
# Obtener execution ID de la ejecución en espera
curl -X POST http://192.168.1.100:5678/webhook/approval/<EXECUTION_ID> \
  -H "Content-Type: application/json" \
  -d '{"approved": true, "comment": "Aprobado por on-call"}'
```

---

## 5. Comandos de Operación Diaria

### 5.1 Ver Logs en Tiempo Real

```bash
# n8n
docker-compose -f ~/curso-n8n/docker-compose.lab.yml logs -f n8n

# Dify API
docker-compose -f ~/curso-n8n/docker-compose.lab.yml logs -f dify-api

# Dify Worker
docker-compose -f ~/curso-n8n/docker-compose.lab.yml logs -f dify-worker

# Todos
docker-compose -f ~/curso-n8n/docker-compose.lab.yml logs -f
```

### 5.2 Reiniciar Servicios

```bash
# Solo n8n
docker-compose -f ~/curso-n8n/docker-compose.lab.yml restart n8n

# Solo Dify
docker-compose -f ~/curso-n8n/docker-compose.lab.yml restart dify-api dify-worker

# Todo el stack
docker-compose -f ~/curso-n8n/docker-compose.lab.yml restart
```

### 5.3 Backup Workflows n8n

```bash
# Via API (requiere workflow activo)
curl -X GET http://192.168.1.100:5678/api/v1/workflows \
  -H "Authorization: Basic $(echo -n 'admin:n8n_lab_2026' | base64)" \
  > ~/n8n-backup-$(date +%Y%m%d-%H%M).json

# Via UI: Workflows → ⋮ → Export
```

### 5.4 Backup Dify

```bash
# Via UI: Settings → Backup & Restore → Export
# Genera archivo .zip con apps, knowledge bases, configuración
```

### 5.5 Limpieza Final (Post-curso)

```bash
cd ~/curso-n8n
docker-compose -f docker-compose.lab.yml down -v
# -v elimina volúmenes (postgres_data, redis_data, n8n_data, dify_storage)
docker volume prune -f
docker image prune -f
```

---

## 6. Troubleshooting Rápido

| Síntoma | Comando Diagnóstico | Solución |
|---------|---------------------|----------|
| n8n no carga | `docker-compose logs n8n \| tail -50` | Esperar postgres healthy, verificar N8N_ENCRYPTION_KEY (32+ chars) |
| Dify "Database connection failed" | `docker-compose logs postgres` | Verificar POSTGRES_PASSWORD coincide en .env y init script |
| Webhook 404 | Verificar workflow **Active** en n8n | Toggle Active → Save |
| Dify "Model provider error" | `docker-compose logs dify-api \| grep -i model` | Verificar API Key / Ollama corriendo en puerto 11434 |
| Out of Memory | `free -h` / `docker stats` | Añadir swap 4GB: `sudo fallocate -l 4G /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile` |
| Puerto ocupado | `sudo lsof -i :5678` | Matar proceso o cambiar puerto en docker-compose |
| Certificados SSL | `docker-compose logs certbot` | Verificar dominio apunta a IP, puertos 80/443 abiertos |

---

## 7. URLs de Referencia Rápida (Hoja de Chuleta)

| Qué | URL | Credenciales |
|-----|-----|--------------|
| **Docs Curso** | http://192.168.1.100:8001 | - |
| **n8n UI** | http://192.168.1.100:5678 | admin / n8n_lab_2026 |
| **n8n Webhook Base** | http://192.168.1.100:5678/webhook/ | - |
| **n8n API** | http://192.168.1.100:5678/api/v1/ | Basic Auth admin:n8n_lab_2026 |
| **Dify UI** | http://192.168.1.100:8080 | Tu registro |
| **Dify API** | http://192.168.1.100:8080/v1/ | Bearer <APP_API_KEY> |
| **CMDB Mock** | http://192.168.1.100:5678/webhook/cmdb | - |
| **Ollama (si usado)** | http://192.168.1.100:11434 | - |
| **httpbin.org** | https://httpbin.org | - |
| **webhook.site** | https://webhook.site | Crear UUID propio |
| **jsonplaceholder** | https://jsonplaceholder.typicode.com | - |

---

## 8. Checklist de Entrega por Alumno (Fin de Curso)

Cada alumno debe entregar:

- [ ] **Repositorio Git** (o .zip) con:
  - [ ] Workflows n8n exportados (`.json`) - Módulos 2, 3, 6, 9
  - [ ] Capturas de ejecución exitosa (Execution Log verde)
  - [ ] Documentación workflows (plantilla `workflow_doc_template.md`)
- [ ] **Dify Apps** exportadas (via Settings → Backup) o capturas:
  - [ ] Chat Assistant Clasificador (Módulo 4)
  - [ ] Knowledge Base + Asistente RAG (Módulo 5)
  - [ ] Analysis Workflow (Módulo 6)
- [ ] **Caso Final (Módulo 9)**:
  - [ ] Arquitectura diagramada (Mermaid/draw.io)
  - [ ] Workflow n8n principal exportado
  - [ ] Dify Workflow exportado
  - [ ] Test cases ejecutados (tabla con resultados)
  - [ ] Riesgos identificados + Plan mitigación
  - [ ] Próximos pasos para piloto (Go/No-Go)
- [ ] **Política Seguridad** (Módulo 7): `SECURITY_POLICY.md` firmada
- [ ] **Métricas** (Módulo 8): Definición de 3-5 KPIs + baseline

---

> **Nota**: Reemplazar `192.168.1.100` por la **IP real del servidor** en todos los comandos y configuraciones.