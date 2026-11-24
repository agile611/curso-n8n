# Recursos y referencias

> **Enlaces curados** para profundizar: documentación oficial, comunidades, certificaciones, lecturas recomendadas.

---

## Documentación oficial

### n8n
| Recurso | Enlace | Descripción |
|---------|--------|-------------|
| **Docs oficiales** | https://docs.n8n.io/ | Referencia completa: nodos, expresiones, hosting, API |
| **API Reference** | https://docs.n8n.io/api/ | REST API para gestión programática de workflows, credenciales, ejecuciones |
| **Nodos built-in** | https://docs.n8n.io/integrations/builtin/ | Catálogo de 400+ nodos: HTTP, Slack, Jira, AWS, DB, etc. |
| **Expresiones** | https://docs.n8n.io/code/expressions/ | Sintaxis `{{ $json.field }}`, funciones, helpers |
| **Self-hosting** | https://docs.n8n.io/hosting/ | Docker, Kubernetes, npm, Coolify, Portainer |
| **Seguridad** | https://docs.n8n.io/security/ | Credenciales, RBAC, network policies, secrets |

### Dify
| Recurso | Enlace | Descripción |
|---------|--------|-------------|
| **Docs oficiales** | https://docs.dify.ai/ | Guía completa: apps, workflows, agents, knowledge base |
| **API Reference** | https://docs.dify.ai/reference/ | REST API: chat, workflows, datasets, documents |
| **Plugins/Tools** | https://docs.dify.ai/plugins/ | Crear tools custom, OAuth providers, model providers |
| **Self-hosting** | https://docs.dify.ai/getting-started/install-self-hosted/ | Docker Compose, Kubernetes, variables de entorno |
| **RAG Guide** | https://docs.dify.ai/guides/knowledge-base/ | Chunking, retrieval, rerank, evaluation |

---

## Comunidades y soporte

| Plataforma | Enlace | Actividad |
|------------|--------|-----------|
| **n8n Community Forum** | https://community.n8n.io/ | Muy activa: workflows compartidos, troubleshooting, feature requests |
| **n8n Discord** | https://discord.gg/n8n | Chat tiempo real, canales #help, #showcase, #jobs |
| **Dify GitHub Discussions** | https://github.com/langgenius/dify/discussions | Q&A, feature requests, bug reports |
| **Dify Discord** | https://discord.gg/dify | Comunidad creciente, canales en español |
| **Stack Overflow** | https://stackoverflow.com/questions/tagged/n8n | Preguntas técnicas etiquetadas |

---

## Certificaciones y formación oficial

| Certificación | Proveedor | Coste | Validez |
|---------------|-----------|-------|---------|
| **n8n Certification** | n8n | Gratuito | Permanente |
| **Dify Advanced Workshops** | Dify | Variable | Según edición |

> 💡 **n8n Certification**: Examen online ~2h, cubre: workflow design, expressions, error handling, security, best practices. Recomendado tras completar el curso.

---

## Lecturas recomendadas

### Libros técnicos

| Título | Autor | Por qué leerlo |
|--------|-------|----------------|
| **Building LLM Applications for Production** | Chip Huyen | Mejores prácticas: eval, RAG, agents, deployment, monitoring |
| **Designing Machine Learning Systems** | Chip Huyen | Arquitectura end-to-end: data, features, training, serving, monitoring |
| **Site Reliability Engineering** | Google (Beyer et al.) | Cap. Monitoring, Alerting, On-call, Incident Response |
| **Team Topologies** | Skelton & Pais | Organización de equipos: stream-aligned, platform, enabling, complicated-subsystem |
| **Building Secure & Reliable Systems** | Google | Seguridad y fiabilidad en sistemas distribuidos |
| **Fundamentals of Software Architecture** | Richards & Ford | Patrones, estilos, decision records, evolutionary architecture |

### Papers y artículos clave

| Título | Enlace | Tema |
|--------|--------|------|
| **Retrieval-Augmented Generation for Knowledge-Intensive NLP Tasks** | [arXiv:2005.11401](https://arxiv.org/abs/2005.11401) | Paper original RAG (Lewis et al., 2020) |
| **Chain-of-Thought Prompting Elicits Reasoning in Large Language Models** | [arXiv:2201.11903](https://arxiv.org/abs/2201.11903) | CoT prompting (Wei et al., 2022) |
| **Constitutional AI: Harmlessness from AI Feedback** | [arXiv:2212.08073](https://arxiv.org/abs/2212.08073) | RLAIF, safety (Bai et al., 2022) |
| **Toolformer: Language Models Can Teach Themselves to Use Tools** | [arXiv:2302.04761](https://arxiv.org/abs/2302.04761) | Tool use via self-supervision |
| **Generative Agents: Interactive Simulacra of Human Behavior** | [arXiv:2304.03442](https://arxiv.org/abs/2304.03442) | Agentes con memoria y planificación |

---

## Herramientas complementarias

### Testing y evaluación

| Herramienta | Uso | Enlace |
|-------------|-----|--------|
| **RAGAS** | Evaluación RAG: faithfulness, answer_relevancy, context_precision | https://github.com/explodinggradients/ragas |
| **LangSmith** | Tracing, evaluation, debugging LLM apps | https://smith.langchain.com/ |
| **Promptfoo** | Testing automatizado de prompts (CI/CD) | https://www.promptfoo.dev/ |
| **DeepEval** | Evaluación LLM: hallucination, bias, toxicity | https://github.com/confident-ai/deepeval |

### Observabilidad

| Herramienta | Uso | Enlace |
|-------------|-----|--------|
| **Grafana + Loki + Tempo** | Logs, métricas, trazas (stack open source) | https://grafana.com/ |
| **OpenTelemetry** | Instrumentación vendor-neutral | https://opentelemetry.io/ |
| **Jaeger** | Distributed tracing | https://www.jaegertracing.io/ |

### Secrets & Config

| Herramienta | Uso | Enlace |
|-------------|-----|--------|
| **HashiCorp Vault** | Secrets management, dynamic secrets | https://www.vaultproject.io/ |
| **SOPS / Age** | Encryptar secrets en Git | https://github.com/getsops/sops |
| **External Secrets Operator** | Sync Vault/AWS Secrets → K8s secrets | https://external-secrets.io/ |

---

## Documentación del curso (repositorio)

| Documento | Ubicación | Descripción |
|-----------|-----------|-------------|
| **Guía Laboratorios Ubuntu 24.04** | `docs/guia_laboratorios_ubuntu24.md` | Setup completo paso a paso: SSH, docker-compose, n8n/Dify config, datos prueba, comandos por módulo, troubleshooting |
| **Temario Adaptado** | `docs/temario_adaptado.md` | Correspondencia 1:1 temario original (18h) ↔ 9 módulos + labs adaptados para Ubuntu 24.04 |
| **Referencia Rápida** | `docs/quick_reference.md` | Hoja de chuleta: URLs, comandos Docker, expresiones n8n, Dify prompts, seguridad, testing, entregables |
| **Plantilla Documentación Workflow** | `docs/workflow_doc_template.md` | Estándar para documentar cada workflow: arquitectura, contratos I/O, dependencias, métricas, runbook, Go/No-Go |
| **Política Seguridad Mínima** | `docs/security_policy_template.md` | Checklist seguridad: credenciales, validación I/O, prompt injection, sanitización logs, approval gates, fases prototipo→piloto→prod |
| **Guía Despliegue** | `docs/deploy.md` | Despliegue nativo/Docker en Ubuntu 24.04 (systemd, nginx, certbot, firewall) |

---

## Plantillas del curso (repositorio)

| Plantilla | Ubicación | Uso |
|-----------|-----------|-----|
| **Workflow n8n base** | `templates/workflow-base.json` | Estructura estándar: webhook → validate → enrich → dify → decision → execute → audit |
| **Dify Workflow Analysis** | `templates/dify-analysis.yml` | DSL para workflow de análisis con classification + enrichment + recommendation |
| **JSON Schema Contract** | `templates/contracts/analysis-output.json` | Contrato compartido n8n↔Dify |
| **Approval Matrix** | `templates/policies/approval-matrix.yaml` | Qué acciones requieren aprobación por entorno |
| **Security Checklist** | `templates/checklists/security-checklist.md` | Gate 2: Prototipo → Piloto |
| **Go/No-Go Template** | `templates/go-no-go.md` | Decisión formal por gate |
| **Runbook Template** | `templates/runbooks/template.md` | Estructura estándar de runbook de incidente |
| **Handoff Package** | `templates/handoff/` | README, ARCHITECTURE, RUNBOOKS, CONFIG, MONITORING, API, SECURITY, CHANGELOG |

---

## Enlaces del proyecto

| Enlace | Descripción |
|--------|-------------|
| **Repositorio GitHub** | https://github.com/agile611/curso-n8n |
| **Sitio publicado** | https://docs.agile611.com/curso-n8n/ |
| **Issues / Bugs** | https://github.com/agile611/curso-n8n/issues |
| **Releases / Changelog** | https://github.com/agile611/curso-n8n/releases |
| **Deploy Guide** | [Guía de despliegue](deploy.md) |

---

## Contacto

| Canal | Detalle |
|-------|---------|
| **Autor** | Guillem Hernández Sola |
| **Organización** | Agile611 |
| **Email** | guillem@agile611.com |
| **Web** | https://agile611.com |
| **LinkedIn** | https://linkedin.com/in/guillemhernandez |

---

> **¿Falta algún recurso?** Abre un [issue](https://github.com/agile611/curso-n8n/issues/new) o PR en el repositorio.
