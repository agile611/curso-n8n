# Glosario de conceptos

> **Referencia rápida** de términos técnicos usados en el curso. Orden alfabético.

---

## A

| Término | Definición |
|---------|------------|
| **Agente (IA)** | Sistema de IA que planifica, usa herramientas y ejecuta acciones para alcanzar un objetivo. A diferencia de un asistente, tiene autonomía para decidir qué herramienta usar y cuándo. |
| **API (Application Programming Interface)** | Contrato que define cómo dos sistemas se comunican. En el curso: REST + JSON sobre HTTP. |
| **Aprobación (Approval Gate)** | Paso obligatorio donde un humano valida una acción antes de su ejecución. Implementado con JWT + callback Slack/Email. |
| **Automatización determinista** | Workflow cuyas ramas de decisión son reglas fijas (IF/ELSE). Resultado predecible y auditable. Herramienta: n8n. |

## C

| Término | Definición |
|---------|------------|
| **Chunking** | División de documentos en fragmentos (chunks) para indexación vectorial. Tamaño típico: 500-1000 tokens con overlap 10-20%. |
| **Circuit Breaker** | Patrón de resiliencia: tras N fallos consecutivos, deja de llamar al servicio externo y devuelve fallback inmediato. |
| **Correlation ID** | Identificador único que se propaga a través de todos los sistemas (n8n, Dify, Slack, logs) para trazar una ejecución end-to-end. Formato: `corr-YYYYMMDDHHmmssSSS`. |
| **Credential (n8n/Dify)** | Almacén seguro de secretos (API keys, tokens, passwords). Nunca hardcodear en workflows. |

## D

| Término | Definición |
|---------|------------|
| **Dify** | Plataforma LLMOps para crear asistentes, workflows de IA, agentes y bases de conocimiento (RAG). Alternative open-source a LangChain/LangGraph. |
| **DLQ (Dead Letter Queue)** | Cola donde se envían mensajes/ejecuciones que fallaron irreversiblemente para análisis posterior. |

## E

| Término | Definición |
|---------|------------|
| **Embedding** | Representación vectorial de texto (semántica). Modelo típico: `text-embedding-3-large` (OpenAI) o `bge-large` (open source). |
| **Error Budget** | Porcentaje de fallos permitidos en una ventana de tiempo (ej. 0.5%/mes). Base para políticas de freeze deploys. |

## G

| Término | Definición |
|---------|------------|
| **Groundedness** | Métrica (0-1) que indica qué porcentaje de afirmaciones de una respuesta IA están soportadas por fuentes recuperadas. Target: >0.9. |
| **Guardrails** | Reglas de seguridad que limitan el comportamiento de un agente (allowlist de tools, schema validation, approval gates, timeouts). |

## H

| Término | Definición |
|---------|------------|
| **Hallucination** | Respuesta de IA que inventa información no presente en las fuentes. Mitigación: temperature=0, groundedness check, RAG obligatorio. |
| **Human-in-the-loop (HITL)** | Patrón donde un humano interviene en el flujo: aprobación previa, validación post-ejecución, o escalado. |

## I

| Término | Definición |
|---------|------------|
| **Idempotency Key** | Clave única (ej. `alert-12345-20260115`) que garantiza que re-ejecutar una operación no causa efectos secundarios duplicados. |
| **Inference** | Ejecución de un modelo LLM para generar respuesta. Coste medido en tokens (input + output). |

## J

| Término | Definición |
|---------|------------|
| **JSON Schema** | Especificación formal de la estructura de un JSON. Usado para validar inputs/outputs de webhooks, herramientas Dify, y contratos n8n↔Dify. |

## K

| Término | Definición |
|---------|------------|
| **Knowledge Base (KB)** | Base de conocimiento en Dify: documentos indexados + embeddings + metadatos + retrieval config. Soporta RBAC y versionado. |

## L

| Término | Definición |
|---------|------------|
| **LLM (Large Language Model)** | Modelo de lenguaje grande (GPT-4o, Claude, Llama, etc.). En el curso: acceso via API (OpenAI/Azure) o local (Ollama/vLLM). |
| **Low-code / No-code** | Desarrollo visual sin escribir código tradicional. n8n y Dify son herramientas low-code/no-code. |

## M

| Término | Definición |
|---------|------------|
| **Metadata Filtering** | Filtrado en retrieval por campos estructurados (version, product, domain, status). Esencial para multi-producto y RBAC. |
| **MTTD / MTTR** | Mean Time To Detect / Resolve. Métricas clave de operación. |

## N

| Término | Definición |
|---------|------------|
| **n8n** | Orquestador visual de workflows (fair-code). Nodos = triggers, actions, logic. Ejecución: push (webhook), pull (polling), scheduled, manual. |
| **Nodo (n8n)** | Unidad atómica de un workflow: Trigger, HTTP Request, IF, Set, Function, Merge, etc. |

## P

| Término | Definición |
|---------|------------|
| **Prompt Engineering** | Diseño iterativo de instrucciones para LLM: system prompt, variables, few-shot examples, output schema, constraints. |
| **Prompt Injection** | Ataque donde input malicioso intenta sobrescribir instrucciones del system prompt. Defensa: delimitadores, allowlist, detección regex. |

## R

| Término | Definición |
|---------|------------|
| **RAG (Retrieval-Augmented Generation)** | Arquitectura: Embedding → Vector DB → Top-K retrieval → LLM con contexto → Respuesta con citas. |
| **Rerank** | Re-ordenación de chunks recuperados por relevancia semántica (modelo: `bge-reranker-large`, `cohere-rerank-v3`). Mejora precision. |
| **Retry / Backoff** | Reintento automático en fallos transitorios (5xx, 429, timeout). Config: max 3 intentos, 5s intervalo, exponential backoff. |
| **RBAC (Role-Based Access Control)** | Control de acceso por roles: Developer, Operator, Platform Lead, Security Auditor, On-Call. |

## S

| Término | Definición |
|---------|------------|
| **SLA / SLO / SLI** | Service Level Agreement / Objective / Indicator. Compromisos de disponibilidad, latencia, error rate. |
| **SemVer** | Versionado semántico: MAJOR.MINOR.PATCH. Breaking changes = MAJOR. |
| **Safety Gate** | Validación en n8n post-Dify: confidence threshold, action_type allowlist, approval_required check, dry-run. |

## T

| Término | Definición |
|---------|------------|
| **Temperature** | Parámetro LLM que controla aleatoriedad. 0 = determinista (obligatorio en asistentes técnicos). 0.7 = creativo. |
| **Token** | Unidad de facturación LLM (~4 chars en inglés). Input + Output tokens determinan coste. |
| **Tool (Dify Agent)** | Función expuesta al agente: nombre, descripción, JSON Schema params, return schema. Ej: `restart_k8s_deployment`. |

## V

| Término | Definición |
|---------|------------|
| **Vector Database** | BD optimizada para búsqueda por similitud coseno (Weaviate, Qdrant, Milvus, pgvector). Almacena embeddings + metadata. |
| **Versionado GitOps** | Workflows/apps versionados en Git (SemVer), CI/CD para deploy staging→prod, rollback via tag anterior. |

## W

| Término | Definición |
|---------|------------|
| **Webhook** | HTTP POST entrante que dispara un workflow. Modos: Sync (Response Node) / Async (On Received). Seguridad: HMAC, IP allowlist, rate limit. |
| **Workflow (n8n)** | Grafo dirigido de nodos conectados. Ejecución: manual, webhook, schedule, queue. Estado: success/error/running. |

---

## Siglas frecuentes

| Sigla | Significado |
|-------|-------------|
| **AI** | Artificial Intelligence |
| **API** | Application Programming Interface |
| **CI/CD** | Continuous Integration / Continuous Deployment |
| **CMDB** | Configuration Management Database |
| **CNI** | Container Network Interface |
| **CVE** | Common Vulnerabilities and Exposures |
| **DLQ** | Dead Letter Queue |
| **DR** | Disaster Recovery |
| **HA** | High Availability |
| **HITL** | Human-in-the-loop |
| **IaC** | Infrastructure as Code |
| **ITSM** | IT Service Management |
| **KB** | Knowledge Base |
| **LLM** | Large Language Model |
| **MTTD** | Mean Time To Detect |
| **MTTR** | Mean Time To Resolve |
| **PII** | Personally Identifiable Information |
| **PR** | Pull Request |
| **RAG** | Retrieval-Augmented Generation |
| **RBAC** | Role-Based Access Control |
| **RPO** | Recovery Point Objective |
| **RTO** | Recovery Time Objective |
| **SLA** | Service Level Agreement |
| **SLO** | Service Level Objective |
| **SLI** | Service Level Indicator |
| **SSO** | Single Sign-On |
| **SRE** | Site Reliability Engineering |
| **SSH** | Secure Shell |
| **TTL** | Time To Live |
| **ZDR** | Zero Data Retention |

---

## 🔗 Enlaces relacionados

- [Recursos y referencias](recursos.md)
- [Módulo 1: Fundamentos](modulos/modulo-01-fundamentos.md)
- [Módulo 7: Seguridad, gobierno y calidad](modulos/modulo-07-seguridad-gobierno.md)
