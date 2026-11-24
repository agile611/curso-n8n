# Temario Adaptado: Automatización y agentes sin código para perfiles técnicos

> **Versión adaptada** al contenido disponible en `/docs/modulos/` y entorno de laboratorio **Ubuntu 24.04** (IP ejemplo: `192.168.1.100`)

---

## Correspondencia Temario Original ↔ Módulos Disponibles

| Módulo Original (Temario) | Horas | Módulo en Docs | Archivo | Estado |
|---------------------------|-------|----------------|---------|--------|
| 1. Fundamentos de automatización y agentes sin código | 2h | **Módulo 1** | `modulo-01-fundamentos.md` | ✅ Completo |
| 2. Primer workflow práctico con n8n | 2h | **Módulo 2** | `modulo-02-primer-workflow.md` | ✅ Completo |
| 3. Eventos, webhooks e integración con sistemas | 2h | **Módulo 3** | `modulo-03-eventos-webhooks.md` | ✅ Completo |
| 4. Asistentes y workflows de IA con Dify | 2h | **Módulo 4** | `modulo-04-asistentes-dify.md` | ✅ Completo |
| 5. RAG y bases de conocimiento para documentación técnica | 2h | **Módulo 5** | `modulo-05-rag-conocimiento.md` | ✅ Completo |
| 6. Orquestación de agentes con Dify y n8n | 3h | **Módulo 6** | `modulo-06-orquestacion-agentes.md` | ✅ Completo |
| 7. Seguridad, gobierno y calidad en automatizaciones con IA | 2h | **Módulo 7** | `modulo-07-seguridad-gobierno.md` | ✅ Completo |
| 8. Operación, mantenimiento y ciclo de vida | 2h | **Módulo 8** | `modulo-08-operacion-ciclo-vida.md` | ✅ Completo |
| 9. Caso práctico final integrado | 3h | **Módulo 9** | `modulo-09-caso-final.md` | ✅ Completo |
| **TOTAL** | **18h** | | | **9/9 módulos** |

> ✅ **Cobertura 100%**: Todos los temas del temario original tienen módulo correspondiente en la documentación.

---

## Adaptación de Prácticas para Entorno Ubuntu 24.04 Remoto

### Entorno de Laboratorio

| Componente | Especificación |
|------------|----------------|
| **SO** | Ubuntu 24.04 LTS |
| **Acceso** | SSH: `ssh curso@192.168.1.100` |
| **Usuario** | `curso` (sudo sin password configurado) |
| **Docker** | Docker Engine + Docker Compose Plugin |
| **Puertos expuestos** | 22 (SSH), 80/443 (nginx), 5678 (n8n), 8080 (Dify), 8001 (MkDocs docs) |
| **IP ejemplo docs** | `192.168.1.100` (sustituir por IP real del lab) |

### Preparación Previa (Ejecutar ANTES del curso)

```bash
# 1. Conectar al servidor de laboratorio
ssh curso@192.168.1.100

# 2. Verificar requisitos
docker --version           # Docker version 27.x+
docker-compose version     # Docker Compose v2.x+
free -h                    # RAM ≥ 8 GB recomendado
df -h /                    # Disco ≥ 20 GB libre

# 3. Clonar repositorio del curso
git clone https://github.com/agile611/curso-n8n.git
cd curso-n8n

# 4. Levantar stack completo (n8n + Dify + Docs + PostgreSQL + Redis)
docker-compose -f docker-compose.lab.yml up -d

# 5. Verificar servicios
docker-compose -f docker-compose.lab.yml ps
# Todos deben mostrar "Up" / "healthy"

# 6. Acceder a interfaces (desde navegador LOCAL del alumno)
# - Documentación del curso: http://192.168.1.100:8001
# - n8n: http://192.168.1.100:5678 (admin / n8n_lab_2026)
# - Dify: http://192.168.1.100:8080 (admin@lab.local / dify_lab_2026)

> ⚠️ **Dify primera vez**: Al abrir `http://192.168.1.100:8080` verás *"Dify has not been initialized..."*. **Es normal** → Completa el Setup Wizard (crear admin, workspace, skip model provider si no tienes API Key). Ver [Guía Laboratorios §0.6](../GUIA_LABORATORIOS_UBUNTU24.md#06-dify-configuración-inicial-obligatoria-setup-wizard)
```

### docker-compose.lab.yml (Crear en raíz del repo)

```yaml
version: '3.8'

services:
  # Base de datos compartida
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: n8n
      POSTGRES_USER: n8n
      POSTGRES_PASSWORD: "${POSTGRES_PASSWORD:-n8n_lab_2026}"
      POSTGRES_MULTIPLE_DATABASES: "n8n,dify"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init-multiple-dbs.sh:/docker-entrypoint-initdb.d/init-multiple-dbs.sh:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U n8n"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - lab_net

  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes --requirepass "${REDIS_PASSWORD:-redis_lab_2026}"
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - lab_net

  # n8n - Orquestación de workflows
  n8n:
    image: n8nio/n8n:latest
    environment:
      # Base config
      N8N_HOST: "192.168.1.100"
      N8N_PORT: "5678"
      N8N_PROTOCOL: "http"
      WEBHOOK_URL: "http://192.168.1.100:5678/"
      GENERIC_TIMEZONE: "Europe/Madrid"
      
      # Database
      DB_TYPE: "postgresdb"
      DB_POSTGRESDB_HOST: "postgres"
      DB_POSTGRESDB_PORT: "5432"
      DB_POSTGRESDB_DATABASE: "n8n"
      DB_POSTGRESDB_USER: "n8n"
      DB_POSTGRESDB_PASSWORD: "${POSTGRES_PASSWORD:-n8n_lab_2026}"
      
      # Redis (queue mode)
      EXECUTIONS_MODE: "queue"
      QUEUE_BULL_REDIS_HOST: "redis"
      QUEUE_BULL_REDIS_PORT: "6379"
      QUEUE_BULL_REDIS_PASSWORD: "${REDIS_PASSWORD:-redis_lab_2026}"
      
      # Security
      N8N_BASIC_AUTH_ACTIVE: "true"
      N8N_BASIC_AUTH_USER: "admin"
      N8N_BASIC_AUTH_PASSWORD: "${N8N_BASIC_AUTH_PASSWORD:-n8n_lab_2026}"
      N8N_ENCRYPTION_KEY: "${N8N_ENCRYPTION_KEY:-clave_secreta_32_chars_minimo!!}"
      
      # Limits
      N8N_PAYLOAD_SIZE_MAX: "16"
      N8N_DEFAULT_BINARY_DATA_MODE: "filesystem"
    ports:
      - "5678:5678"
    volumes:
      - n8n_data:/home/node/.n8n
      - ./n8n-backups:/backups
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://localhost:5678/healthz"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - lab_net

  # Dify - IA, RAG, Agentes
  dify-api:
    image: langgenius/dify-api:latest
    environment:
      # Database
      DB_TYPE: "postgresql"
      DB_HOST: "postgres"
      DB_PORT: "5432"
      DB_USERNAME: "n8n"
      DB_PASSWORD: "${POSTGRES_PASSWORD:-n8n_lab_2026}"
      DB_DATABASE: "dify"
      
      # Redis
      REDIS_HOST: "redis"
      REDIS_PORT: "6379"
      REDIS_PASSWORD: "${REDIS_PASSWORD:-redis_lab_2026}"
      REDIS_DB: "0"
      
      # Config
      SECRET_KEY: "${DIFY_SECRET_KEY:-dify_secret_key_32_chars_minimo!!}"
      CONSOLE_API_URL: "http://192.168.1.100:8080"
      CONSOLE_WEB_URL: "http://192.168.1.100:8080"
      SERVICE_API_URL: "http://192.168.1.100:8080/v1"
      FILES_URL: "http://192.168.1.100:8080/v1/files"
      
      # Storage (local para lab)
      STORAGE_TYPE: "local"
      LOCAL_STORAGE_PATH: "/var/lib/dify/storage"
      
      # Model providers (configurar según disponibilidad)
      # OPENAI_API_KEY: "${OPENAI_API_KEY:-}"
      # AZURE_OPENAI_API_KEY: "${AZURE_OPENAI_API_KEY:-}"
      # OLLAMA_BASE_URL: "http://ollama:11434"
    volumes:
      - dify_storage:/var/lib/dify/storage
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - lab_net

  dify-web:
    image: langgenius/dify-web:latest
    environment:
      CONSOLE_API_URL: "http://192.168.1.100:8080"
      CONSOLE_WEB_URL: "http://192.168.1.100:8080"
    ports:
      - "8080:3000"
    depends_on:
      - dify-api
    networks:
      - lab_net

  dify-worker:
    image: langgenius/dify-api:latest
    command: ["celery", "worker", "-A", "app.celery", "-Q", "default", "-c", "2"]
    environment:
      DB_TYPE: "postgresql"
      DB_HOST: "postgres"
      DB_PORT: "5432"
      DB_USERNAME: "n8n"
      DB_PASSWORD: "${POSTGRES_PASSWORD:-n8n_lab_2026}"
      DB_DATABASE: "dify"
      REDIS_HOST: "redis"
      REDIS_PORT: "6379"
      REDIS_PASSWORD: "${REDIS_PASSWORD:-redis_lab_2026}"
      REDIS_DB: "0"
      SECRET_KEY: "${DIFY_SECRET_KEY:-dify_secret_key_32_chars_minimo!!}"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - lab_net

  # Documentación del curso (MkDocs)
  docs:
    image: python:3.12-alpine
    working_dir: /app
    command: >
      sh -c "pip install -q mkdocs-material mkdocs-mermaid2-plugin mkdocs-git-revision-date-localized-plugin &&
             mkdocs serve --dev-addr=0.0.0.0:8001"
    volumes:
      - ./docs:/app/docs
      - ./mkdocs.yml:/app/mkdocs.yml
      - ./requirements.txt:/app/requirements.txt
    ports:
      - "8001:8001"
    networks:
      - lab_net

  # Nginx reverse proxy (opcional, para producción)
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.lab.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - n8n
      - dify-web
      - docs
    networks:
      - lab_net

volumes:
  postgres_data:
  redis_data:
  n8n_data:
  dify_storage:

networks:
  lab_net:
    driver: bridge
```

### init-multiple-dbs.sh (Crear en raíz del repo)

```bash
#!/bin/bash
# Script para crear múltiples bases de datos en PostgreSQL

set -e

function create_user_and_database() {
    local database=$1
    echo "Creating user and database '$database'"
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
        CREATE USER $database WITH PASSWORD '$database';
        CREATE DATABASE $database;
        GRANT ALL PRIVILEGES ON DATABASE $database TO $database;
EOSQL
}

if [ -n "$POSTGRES_MULTIPLE_DATABASES" ]; then
    echo "Multiple database creation requested: $POSTGRES_MULTIPLE_DATABASES"
    for db in $(echo $POSTGRES_MULTIPLE_DATABASES | tr ',' ' '); do
        create_user_and_database $db
    done
    echo "Multiple databases created"
fi
```

### nginx.lab.conf (Crear en raíz del repo)

```nginx
events {
    worker_connections 1024;
}

http {
    upstream n8n_backend {
        server n8n:5678;
    }
    
    upstream dify_backend {
        server dify-web:80;
    }
    
    upstream docs_backend {
        server docs:8001;
    }

    server {
        listen 80;
        server_name 192.168.1.100;

        # n8n
        location /n8n/ {
            proxy_pass http://n8n_backend/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_read_timeout 300s;
            proxy_send_timeout 300s;
        }

        # Dify
        location /dify/ {
            proxy_pass http://dify_backend/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Documentación
        location /docs/ {
            proxy_pass http://docs_backend/;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Health check
        location /health {
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
    }
}
```

---

## Adaptación de Labs por Módulo

### Módulo 1: Fundamentos → Labs Adaptados

| Lab Original | Adaptación Ubuntu 24.04 |
|--------------|-------------------------|
| **Lab 1.1** Identificación procesos | ✅ Sin cambios (papel/digital) |
| **Lab 1.2** Mapa I-P-D-S | ✅ Usar draw.io / Excalidraw online |
| **Lab 1.3** Matriz riesgo/impacto | ✅ Hoja de cálculo compartida (Google Sheets / Excel Online) |

> **Nota**: Módulo 1 es teórico, no requiere acceso a n8n/Dify aún.

---

### Módulo 2: Primer Workflow n8n → Labs Adaptados

| Lab Original | Adaptación Ubuntu 24.04 |
|--------------|-------------------------|
| **Lab 2.1** Workflow solicitud técnica | **Acceso n8n**: `http://192.168.1.100:5678` (user: admin / pass: n8n_lab_2026)<br>**Mock API**: Usar `https://httpbin.org/post` o `https://webhook.site/#!/view/<uuid>`<br>**Credenciales n8n**: Crear "HTTP Header Auth" genérica para labs |
| **Lab 2.2** Condiciones y rutas | **Webhook testing**: `curl -X POST http://192.168.1.100:5678/webhook/lab22 -H "Content-Type: application/json" -d '{"priority":"critical"}'` |
| **Lab 2.3** Debugging errores | **Execution Log**: Ver en UI n8n → Executions<br>**Re-run**: Botón "Re-run" en ejecución fallida<br>**Pin Data**: Click 📌 en output para fijar datos de test |

#### Credenciales de Laboratorio n8n (Pre-crear)

```bash
# En n8n UI → Credentials → New Credential
# 1. HTTP Header Auth - "Lab HTTP Auth"
#    Name: Authorization
#    Value: Bearer lab-token-2026
#
# 2. Slack API - "Lab Slack" (opcional, usar webhook.site en su lugar)
#    Webhook URL: https://webhook.site/#!/view/<uuid>
#
# 3. Jira Basic Auth - "Lab Jira" (opcional, mock)
#    User: lab_user
#    Password: lab_pass
```

---

### Módulo 3: Eventos, Webhooks, APIs → Labs Adaptados

| Lab Original | Adaptación Ubuntu 24.04 |
|--------------|-------------------------|
| **Lab 3.1** Webhook alerta simulada | **Endpoint real**: `http://192.168.1.100:5678/webhook/alertas/monitoring`<br>**Test**: `curl -X POST http://192.168.1.100:5678/webhook/alertas/monitoring -H "Content-Type: application/json" -H "X-Webhook-Token: lab-token-2026" -d @alert-sample.json` |
| **Lab 3.2** Consultar API + enriquecer | **API Mock**: `https://httpbin.org/get` o `https://jsonplaceholder.typicode.com/users/1`<br>**CMDB Mock**: Crear workflow n8n separado que actúe como "CMDB API" en `http://192.168.1.100:5678/webhook/cmdb` |
| **Lab 3.3** Respuesta estructurada + evidencias | **Response Node**: Configurar Webhook en modo "Response Node"<br>**Audit Log**: Escribir a archivo en volumen n8n `/home/node/.n8n/audit.log` via Function node |

#### alert-sample.json (Crear para labs)

```json
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
```

---

### Módulo 4: Asistentes y Workflows Dify → Labs Adaptados

| Lab Original | Adaptación Ubuntu 20.04 |
|--------------|-------------------------|
| **Lab 4.1** Asistente técnico clasificar incidencias | **Acceso Dify**: `http://192.168.1.100:8080`<br>**Setup inicial**: Registrar usuario admin → Crear App tipo "Chat Assistant"<br>**Model Provider**: Configurar en Settings → Model Provider (OpenAI / Azure / Ollama local) |
| **Lab 4.2** Prompts con objetivo/contexto/restricciones | **System Prompt**: Copiar plantilla del módulo 4<br>**Variables**: Definir en Start node: `alert_json`, `cmdb_data`, `runbook_summary` |
| **Lab 4.3** Comparar resultados | **Testing**: Usar "Debug & Preview" panel en Dify<br>**Documentar**: Capturas de pantalla + tabla comparativa en doc compartido |

#### Configuración Model Provider Dify (Obligatorio)

```bash
# Opción A: OpenAI / Azure OpenAI (requiere API Key real)
# En Dify UI → Settings → Model Provider → OpenAI / Azure OpenAI
# API Key: [proporcionada por instructor]
# Base URL: https://api.openai.com/v1  (o endpoint Azure)

# Opción B: Ollama Local (GRATIS, sin API Key, requiere GPU/CPU)
# 1. En servidor lab: docker run -d --name ollama -p 11434:11434 -v ollama_data:/root/.ollama ollama/ollama:latest
# 2. docker exec -it ollama ollama pull llama3.1:8b
# 3. En Dify → Model Provider → Ollama → Base URL: http://192.168.1.100:11434
# 4. Seleccionar modelo: llama3.1:8b
```

---

### Módulo 5: RAG y Bases de Conocimiento → Labs Adaptados

| Lab Original | Adaptación Ubuntu 24.04 |
|--------------|-------------------------|
| **Lab 5.1** Crear KB con docs ficticias | **Docs fuente**: Usar `/docs/modulos/*.md` del propio curso como docs de prueba<br>**Subida**: Dify → Knowledge → Create Knowledge → Upload .md files<br>**Chunking**: Recursive, 800 tokens, 100 overlap |
| **Lab 5.2** Asistente solo con KB | **App tipo**: "Chat Assistant" + Knowledge Base vinculada<br>**Retrieval**: Hybrid Search + Rerank (si modelo lo soporta)<br>**Prompt**: "Responde SOLO usando la base de conocimiento. Si no hay info → 'No tengo información suficiente'" |
| **Lab 5.3** Detectar respuestas no fundamentadas | **Test cases**: Preguntas dentro de alcance, fuera de alcance, ambiguas<br>**Evaluación**: Verificar citas [doc_1], [doc_3] en respuestas<br>**Mejora**: Ajustar chunking / prompt / retrieval settings |

#### Documentos de Prueba para RAG (Usar los propios módulos)

```bash
# Los archivos .md en /docs/modulos/ ya son documentación técnica válida
# Para el lab, subir estos archivos a Dify Knowledge Base:
# - modulo-01-fundamentos.md
# - modulo-02-primer-workflow.md
# - modulo-03-eventos-webhooks.md
# ... etc
```

---

### Módulo 6: Orquestación Agentes → Labs Adaptados

| Lab Original | Adaptación Ubuntu 24.04 |
|--------------|-------------------------|
| **Lab 6.1** Conectar n8n ↔ Dify | **Dify Workflow API**: `http://192.168.1.100:8080/v1/workflows/run`<br>**Auth**: Header `Authorization: Bearer <DIFY_APP_API_KEY>`<br>**n8n HTTP Request**: POST a Dify con JSON input → Parse output JSON |
| **Lab 6.2** Automatización clasifica + propone acción | **Dify Agent**: Crear Agent con tools (HTTP Request a n8n webhook)<br>**n8n**: Workflow "Executor" que recibe action_type + params → ejecuta acción real |
| **Lab 6.3** Aprobación humana antes de ejecutar | **n8n Wait Node**: Webhook URL `http://192.168.1.100:5678/webhook/approval/<execution_id>`<br>**Simular aprobación**: `curl -X POST http://192.168.1.100:5678/webhook/approval/abc123 -d '{"approved":true}'` |

#### Dify App API Key (Obtener)

```bash
# En Dify → App → Settings → API Access → Generate API Key
# Guardar para usar en n8n HTTP Request headers
```

---

### Módulo 7: Seguridad y Gobierno → Labs Adaptados

| Lab Original | Adaptación Ubuntu 24.04 |
|--------------|-------------------------|
| **Lab 7.1** Revisar flujo inseguro | **Workflow exportado**: Proporcionar `.json` con vulnerabilidades (secrets en código, sin validación, sin auth)<br>**Análisis**: Usar checklist del módulo 7 |
| **Lab 7.2** Añadir validaciones + error routes | **Sanitización**: Añadir Function node "Sanitize for Logging" (código en módulo 7)<br>**Error handling**: Error Trigger → Respond to Webhook / Slack alert |
| **Lab 7.3** Política mínima uso seguro | **Documento**: Crear `SECURITY_POLICY.md` en repo del curso<br>**Checklist**: Firmar por todos los participantes |

---

### Módulo 8: Operación y Ciclo de Vida → Labs Adaptados

| Lab Original | Adaptación Ubuntu 24.04 |
|--------------|-------------------------|
| **Lab 8.1** Documentar workflow + dependencias | **Export**: n8n → Workflows → Export (JSON)<br>**Doc**: Plantilla `WORKFLOW_DOC_TEMPLATE.md` en repo<br>**Diagrama**: Mermaid en doc (renderiza en MkDocs) |
| **Lab 8.2** Matriz validación pre-piloto | **Go/No-Go**: Usar plantilla del módulo 8<br>**Evidencias**: Capturas de tests, logs, métricas |
| **Lab 8.3** Métricas éxito + criterios parada | **Métricas**: Definir en n8n → Settings → Metrics (Prometheus endpoint)<br>**Grafana**: Opcional, `docker run -d -p 3000:3000 grafana/grafana` |

---

### Módulo 9: Caso Final Integrado → Labs Adaptados

| Lab Original | Adaptación Ubuntu 24.04 |
|--------------|-------------------------|
| **Lab 9.1** Prototipo integrado Dify + n8n | **Arquitectura completa**: Ver diagrama en módulo 9<br>**Componentes**:<br>1. n8n Webhook: `http://192.168.1.100:5678/webhook/alert-processor`<br>2. n8n Enrichment: CMDB mock + Deployment mock<br>3. Dify Workflow: `http://192.168.1.100:8080/v1/workflows/run`<br>4. n8n Decision/Execution: IF → Actions → Approval → Audit<br>5. Notificaciones: Slack webhook.site |
| **Lab 9.2** Validar, presentar riesgos, siguientes pasos | **Test cases**:<br>- Alerta P1 crítica prod → Escalado PagerDuty<br>- Alerta P3 warning → Ticket Jira<br>- Alerta ruido → Auto-close + log<br>- Fallo Dify → Fallback n8n (ticket genérico)<br>- Fallo n8n action → Alert on-call<br>**Presentación**: 5 min por grupo + 5 min Q&A |

---

## Checklist de Verificación Pre-Curso (Instructor)

### Infraestructura
- [ ] Servidor Ubuntu 24.04 accesible por SSH (`curso@192.168.1.100`)
- [ ] Docker + Docker Compose instalados y funcionando
- [ ] Puertos 5678, 8080, 8001 abiertos en firewall
- [ ] `docker-compose.lab.yml` + `init-multiple-dbs.sh` + `nginx.lab.conf` en repo
- [ ] Stack levantado: `docker-compose -f docker-compose.lab.yml up -d`
- [ ] Todos los contenedores "healthy" (`docker-compose ps`)

### n8n
- [ ] Acceso UI: `http://192.168.1.100:5678` (admin / n8n_lab_2026)
- [ ] Credenciales de lab creadas (HTTP Header Auth, Slack webhook.site, Jira mock)
- [ ] Workflow de prueba "Test Connectivity" funciona
- [ ] Execution mode: Queue (Redis) configurado

### Dify
- [ ] Acceso UI: `http://192.168.1.100:8080` (registro admin inicial)
- [ ] Model Provider configurado (OpenAI / Azure / Ollama)
- [ ] App de prueba "Lab Classifier" creada y funcional
- [ ] Knowledge Base de prueba creada con docs del curso
- [ ] API Key de app generada para integración n8n

### Documentación
- [ ] MkDocs accesible: `http://192.168.1.100:8001`
- [ ] Navegación módulos 1-9 funcional
- [ ] Mermaid diagrams renderizan correctamente

### Datos de Prueba
- [ ] `alert-sample.json` disponible
- [ ] Mock endpoints (httpbin.org, webhook.site, jsonplaceholder) accesibles desde servidor
- [ ] CMDB mock workflow desplegado en n8n (`/webhook/cmdb`)

### Credenciales y Secrets (Distribuir a Alumnos)
- [ ] n8n: URL, user, password
- [ ] Dify: URL, user, password (tras registro)
- [ ] Dify App API Key (para integración)
- [ ] Model Provider API Key (si OpenAI/Azure)
- [ ] Webhook.site URLs únicas por alumno/grupo (para Slack/Jira mock)

---

## Comandos Útiles Durante el Curso

```bash
# Ver logs en tiempo real
docker-compose -f docker-compose.lab.yml logs -f n8n
docker-compose -f docker-compose.lab.yml logs -f dify-api
docker-compose -f docker-compose.lab.yml logs -f dify-worker

# Reiniciar servicio específico
docker-compose -f docker-compose.lab.yml restart n8n
docker-compose -f docker-compose.lab.yml restart dify-api dify-worker

# Backup n8n workflows (export manual via UI o API)
curl -X GET http://192.168.1.100:5678/api/v1/workflows \
  -H "Authorization: Basic $(echo -n 'admin:n8n_lab_2026' | base64)" \
  > n8n-workflows-backup-$(date +%Y%m%d).json

# Backup Dify (via UI: Settings → Backup & Restore)

# Limpiar todo al final
docker-compose -f docker-compose.lab.yml down -v
# -v elimina volúmenes (datos persistentes)
```

---

## Solución de Problemas Comunes

| Problema | Causa Probable | Solución |
|----------|----------------|----------|
| n8n "Database connection failed" | Postgres no ready | `docker-compose logs postgres` → esperar healthy |
| Dify "Redis connection refused" | Redis password mismatch | Verificar `REDIS_PASSWORD` en .env y docker-compose |
| Webhook n8n 404 | Workflow no activo | Activar workflow (toggle "Active") + Save |
| Dify "Model provider error" | API Key inválida / quota | Verificar key / usar Ollama local |
| Out of memory (OOM) | RAM insuficiente | Aumentar swap: `sudo fallocate -l 4G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile` |
| Puertos ocupados | Otro servicio en 5678/8080 | `sudo lsof -i :5678` → matar proceso |

---

## Referencias Rápidas (URLs de Lab)

| Servicio | URL | Credenciales |
|----------|-----|--------------|
| **Documentación Curso** | http://192.168.1.100:8001 | Pública |
| **n8n** | http://192.168.1.100:5678 | admin / n8n_lab_2026 |
| **Dify** | http://192.168.1.100:8080 | Registro inicial |
| **n8n Webhook Base** | http://192.168.1.100:5678/webhook/ | - |
| **Dify API Base** | http://192.168.1.100:8080/v1/ | Bearer <APP_API_KEY> |
| **Mock HTTPBin** | https://httpbin.org | - |
| **Mock Webhook.site** | https://webhook.site | - |

> ⚠️ **IMPORTANTE**: Reemplazar `192.168.1.100` por la **IP real del servidor de laboratorio** en todos los archivos de configuración y documentación distribuida a alumnos.