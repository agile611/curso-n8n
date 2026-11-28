# Curso: Automatización y agentes sin código para perfiles técnicos

Sitio web educativo construido con **MkDocs** y **Material for MkDocs**.

> **18 horas** | **9 módulos** | **n8n + Dify** | **Perfiles técnicos**

---

## Preparar el entorno

```bash
# Clonar repositorio
git clone https://github.com/agile611/curso-n8n.git
cd curso-n8n

# Crear entorno virtual
python3 -m venv .venv
source .venv/bin/activate  # Linux/macOS
# .venv\Scripts\Activate.ps1  # Windows PowerShell

# Instalar dependencias
pip install -r requirements.txt
```

## Previsualizar en local

```bash
mkdocs serve
```
Abre `http://127.0.0.1:8000`.

## Compilar y validar

```bash
# Build estricto (falla en warnings)
mkdocs build --strict
```
La web generada queda en `site/`.

## Publicar en GitHub Pages

```bash
mkdocs gh-deploy
```

---

## Estructura del proyecto

```
curso-n8n/
├── mkdocs.yml                 # Configuración y navegación
├── requirements.txt           # Dependencias Python pinneadas
├── Dockerfile                 # Imagen Docker para Ubuntu 24.04
├── docker-compose.yml         # MkDocs + Nginx + Certbot (usando docker compose v2)
├── nginx.conf                 # Reverse proxy con cache/SSL
├── deploy-ubuntu.sh           # Script despliegue nativo/Docker
├── DEPLOY.md                  # Guía completa de despliegue
├── docs/
│   ├── index.md               # Página principal
│   ├── assets/
│   │   ├── css/custom.css     # Estilo corporativo Agile611
│   │   └── js/custom.js       # Sidebar dinámica por módulo
│   └── modulos/               # 9 módulos del curso
│       ├── modulo-01-fundamentos.md
│       ├── modulo-02-primer-workflow.md
│       ├── modulo-03-eventos-webhooks.md
│       ├── modulo-04-asistentes-dify.md
│       ├── modulo-05-rag-conocimiento.md
│       ├── modulo-06-orquestacion-agentes.md
│       ├── modulo-07-seguridad-gobierno.md
│       ├── modulo-08-operacion-ciclo-vida.md
│       └── modulo-09-caso-final.md
└── site/                      # Web compilada (no versionar)
```

---

## Contenido del curso (18 horas)

| Módulo | Título | Horas | Foco principal |
|--------|--------|-------|----------------|
| 1 | Fundamentos de automatización y agentes sin código | 2h | Conceptos, herramientas, clasificación de riesgo |
| 2 | Primer workflow práctico con n8n | 2h | Nodos básicos, expresiones, debugging, buenas prácticas |
| 3 | Eventos, webhooks e integración con sistemas | 2h | Triggers, webhooks sync/async, APIs REST, resiliencia |
| 4 | Asistentes y workflows de IA con Dify | 2h | Prompt engineering, Chat App vs Workflow, evaluación |
| 5 | RAG y bases de conocimiento | 2h | Chunking, hybrid search, groundedness, mantenimiento KB |
| 6 | Orquestación de agentes con Dify y n8n | 3h | Patrones Analyze&Act, tools, approval gates, supervisión |
| 7 | Seguridad, gobierno y calidad | 2h | Secretos, prompt injection, guardrails, checklist piloto |
| 8 | Operación, mantenimiento y ciclo de vida | 2h | Versionado, monitoring, SLOs, handoff, mejora continua |
| 9 | Caso práctico final integrado | 3h | Prototipo end-to-end, validación, presentación, retros |

---

## Despliegue en producción (Ubuntu 24.04)

### Opción A: Docker Compose (recomendado)
```bash
docker compose up -d
# Incluye: MkDocs (8000) + Nginx (80/443) + Certbot (SSL auto)
```

### Opción B: Despliegue nativo con systemd
```bash
sudo ./deploy-ubuntu.sh --native
# Instala: Python, venv, Nginx, UFW, servicio systemd
```

### Opción C: Despliegue con Docker (script)
```bash
sudo ./deploy-ubuntu.sh --docker
```

Ver [DEPLOY.md](DEPLOY.md) para guía completa.

---

## Requisitos

- **Python** 3.10+
- **MkDocs** 1.6.1 + Material 9.8.1
- **Docker** 24+ / **Docker Compose** v2 (opción Docker)
- **Ubuntu 24.04 LTS** (producción)

---

## Licencia y autor

**Autor:** Guillem Hernández Sola  
**Organización:** Agile611  
**Web:** https://docs.agile611.com/curso-n8n/  
**Repositorio:** https://github.com/agile611/curso-n8n