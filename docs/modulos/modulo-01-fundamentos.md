# Módulo 1: Fundamentos de automatización y agentes sin código

> **Duración:** 2 horas | **Formato:** Teoría (45 min) + Labs (60 min) + Repaso (15 min)

---

## 🎯 Objetivos del módulo

Al finalizar, los participantes podrán:

- ✅ Diferenciar **automatización determinista** vs **agente con IA** y elegir según el caso
- ✅ Identificar **procesos técnicos candidatos** a automatización en su entorno
- ✅ Entender el **ecosistema de herramientas** (n8n, Dify, Make) y criterios de selección
- ✅ Aplicar **clasificación de riesgo/impacto** para priorizar automatizaciones

---

## 1.1 Conceptos esenciales

### Qué es una automatización no-code/low-code y qué problemas resuelve

> **Definición:** Una **automatización no-code/low-code** es una secuencia de pasos lógicos configurada visualmente (sin escribir código tradicional) que ejecuta tareas repetitivas, integra sistemas o procesa datos entre aplicaciones.

| Problema que resuelve | Ejemplo técnico | Impacto estimado |
|----------------------|-----------------|------------------|
| **Tareas repetitivas manuales** | Crear tickets en Jira desde alertas de monitoring | 5h/semana ahorradas |
| **Integración entre sistemas sin API nativa** | Sincronizar CMDB ↔ Active Directory | Elimina trabajo manual |
| **Procesos multi-paso propensos a error humano** | Onboarding de servidor: DNS + monitoring + backup + CMDB | Reduce errores 90% |
| **Cuellos de botella en equipos especializados** | Auto-clasificación de alertas de seguridad Nivel 1 | Libera senior para tareas complejas |
| **Falta de trazabilidad en operaciones ad-hoc** | Registro automático de cambios en Confluence | Auditoría completa |

> 💡 **Ejemplo para clase:** "Imaginad que cada vez que salta una alerta de disco lleno en vuestro monitoring, alguien tiene que: 1) leer el mail, 2) entrar al servidor, 3) limpiar logs, 4) cerrar la alerta, 5) documentar en Confluence. Eso son 15 min × 20 alertas/semana = **5h/semana automatizables**."

### Diferencias entre workflow, integración, bot, asistente y agente

| Concepto | Definición | Ejemplo n8n/Dify | Nivel de autonomía | Cuándo usar |
|----------|------------|------------------|-------------------|-------------|
| **Workflow** | Secuencia determinista de pasos predefinidos | n8n: Webhook → HTTP Request → IF → Slack | Bajo (sigue reglas fijas) | Procesos predecibles, repetibles |
| **Integración** | Conexión punto-a-punto entre 2 sistemas | n8n: GitLab webhook → Jira create issue | Bajo | Conectar 2 sistemas |
| **Bot** | Script automatizado que simula acciones de usuario | n8n: Scraper web + API legacy | Bajo-Medio | Automatizar UI sin API |
| **Asistente** | IA conversacional especializada en un dominio | Dify: Chat con prompt de sistema + contexto | Medio (responde, no ejecuta) | Soporte, clasificación, generación |
| **Agente** | IA que **planifica, usa herramientas y decide** | Dify Agent: recibe meta → elige tools → ejecuta → valida | Alto (toma decisiones) | Tareas abiertas, ambiguas |

> 💬 **Pregunta de discusión:** "¿Dónde ponéis el límite entre un workflow complejo con muchos IFs y un agente? ¿Es el número de ramas o la capacidad de *elegir* la herramienta?"

### Casos de uso técnicos: ITSM, operaciones cloud, soporte, reporting y ciberseguridad

| Dominio | Caso de uso | Herramienta sugerida | Complejidad | ROI estimado |
|---------|-------------|---------------------|-------------|--------------|
| **ITSM** | Auto-clasificación y enrutamiento de tickets | n8n + Dify (clasificador) | Media | Alto |
| **ITSM** | Creación automática de cambios estandarizados | n8n | Baja | Alto |
| **Cloud Ops** | Auto-remediation: reiniciar servicio, escalar ASG | n8n + AWS CLI / SDK | Media | Muy alto |
| **Cloud Ops** | Inventario de recursos sin etiquetas (tagging) | n8n (scheduled) | Baja | Medio |
| **Soporte** | Respuesta automática a FAQs con RAG | Dify (RAG) | Media | Alto |
| **Soporte** | Resumen de hilos largos de tickets para escalado | Dify (workflow IA) | Media | Medio |
| **Reporting** | Consolidación diaria de métricas multi-cloud | n8n (scheduled + HTTP) | Media | Medio |
| **Ciberseguridad** | Enriquecimiento de IOCs (VirusTotal, AbuseIPDB) | n8n + APIs externas | Media | Alto |
| **Ciberseguridad** | Análisis de logs sospechosos con IA | Dify Agent (tools: SIEM query) | Alta | Alto |

> 🧪 **🧪 Lab 1.1 - Identifica tus procesos:** Cada participante trae **3 procesos reales** de su entorno y los clasifica usando la tabla anterior. Compartid en grupo: ¿cuál automatizaríais primero y por qué?

### Criterios para elegir entre automatización determinista y agente con IA

> 📝 **Regla práctica para la clase:** "Si podéis escribir el diagrama de flujo en una pizarra con **solo decisiones SÍ/NO**, es determinista → **n8n**. Si necesitáis **'depende del contexto', 'interpreta esto', 'elige la mejor opción'**, es agente → **Dify**."

| Criterio | Automatización determinista (n8n) | Agente con IA (Dify) |
|----------|-----------------------------------|----------------------|
| **Lógica** | Reglas explícitas, predecibles | Inferencia, razonamiento, ambigüedad |
| **Entradas** | Estructuradas, validadas | Naturales, no estructuradas, ruidosas |
| **Salidas** | Deterministas, verificables | Probabilísticas, requieren validación |
| **Mantenimiento** | Cambio de reglas = cambio de nodo | Cambio de comportamiento = prompt engineering |
| **Auditoría** | Fácil: cada paso tiene input/output | Compleja: caja negra, necesita logging extra |
| **Coste** | Predecible (ejecuciones) | Variable (tokens, modelo, latencia) |
| **Riesgo** | Controlado (solo hace lo programado) | Emergente (puede alucinar, desviarse) |

> ⚠️ **Punto crítico:** "Nunca uséis un agente para algo que un `IF` resuelve. El coste (tokens, latencia, riesgo) no compensa."

### 🧪 Lab 1.2 - Matriz de decisión: ¿n8n o Dify?

Para cada escenario, decidid qué herramienta usar y justificad:

| Escenario | ¿n8n o Dify? | Justificación |
|-----------|--------------|---------------|
| "Cada día a las 6am, consulta API de AWS y genera reporte de costes en Slack" | | |
| "Usuario pregunta en Slack: '¿Cómo configuro webhook en n8n?' y bot responde" | | |
| "Alerta de disco lleno → enriquece con CMDB → clasifica P1/P2 → crea ticket Jira → notifica on-call" | | |
| "Usuario sube PDF de 50 páginas → extrae requisitos → genera user stories en Jira" | | |
| "Cada hora, consulta API de GitHub y sincroniza issues con Jira" | | |
| "Usuario pregunta: '¿Por qué falló el deploy?' → analiza logs → propone causa raíz" | | |

> 💡 **Solución al final del módulo** (no miréis antes de decidir)

---

## 1.2 Ecosistema de herramientas: n8n, Dify, Make

### Comparativa rápida

| Característica | **n8n** | **Dify** | **Make** |
|----------------|---------|----------|----------|
| **Foco principal** | Orquestación workflows | IA, RAG, Agentes | Integraciones SaaS |
| **Self-hosted** | ✅ Docker, npm, K8s | ✅ Docker Compose | ❌ Solo cloud |
| **Nodos/Integrations** | 400+ built-in | Plugins + Tools | 1500+ apps |
| **IA nativa** | Básica (Function node) | Nativa (RAG, Agent, Workflow) | Básica |
| **Precio self-hosted** | Gratis (open source) | Gratis (open source) | Solo cloud |
| **Curva aprendizaje** | Media | Media-Alta | Baja |
| **Comunidad** | Muy activa | Creciente | Muy activa |

> 💡 **Recomendación:** Usad **n8n** para orquestación, integraciones, webhooks, lógica de control. Usad **Dify** para todo lo que requiera IA: clasificación, extracción, RAG, agentes. Conectadlos vía HTTP/API.

---

## 1.3 Clasificación de riesgo/impacto para priorizar

### Matriz Riesgo vs Impacto

| | **Impacto BAJO** | **Impacto MEDIO** | **Impacto ALTO** |
|---|------------------|-------------------|------------------|
| **Riesgo ALTO** | 🟡 Piloto controlado | 🟠 Requiere aprobación + testing | 🔴 **NO automatizar** sin revisión arquitectura |
| **Riesgo MEDIO** | 🟢 Automatizar con tests | 🟡 Piloto + monitoreo | 🟠 Requiere approval gate |
| **Riesgo BAJO** | 🟢 Automatizar directo | 🟢 Automatizar + monitoring | 🟡 Piloto + approval gate |

### Cálculo de riesgo (ejemplo práctico)

| Factor | Pregunta | Peso |
|--------|----------|------|
| **Reversibilidad** | ¿Se puede deshacer fácilmente? | 30% |
| **Impacto negocio** | ¿Qué pasa si falla? (caída servicio, pérdida datos, multa) | 30% |
| **Complejidad** | ¿Cuántos sistemas/decisiones involucra? | 20% |
| **Frecuencia** | ¿Cuántas veces se ejecuta? | 10% |
| **Madurez proceso** | ¿Está documentado y estandarizado? | 10% |

> 🧪 **Lab 1.3 - Calcula el riesgo:** Cada grupo evalúa 3 procesos reales usando la matriz. Presentad: ¿cuál automatizáis primero?

---

## 📝 Soluciones Lab 1.2

| Escenario | ¿n8n o Dify? | Justificación |
|-----------|--------------|---------------|
| "Cada día a las 6am, consulta API de AWS y genera reporte de costes en Slack" | **n8n** | Schedule + HTTP Request + Slack = determinista |
| "Usuario pregunta en Slack: '¿Cómo configuro webhook en n8n?' y bot responde" | **Dify** | Chat Assistant con KB de docs n8n |
| "Alerta de disco lleno → enriquece con CMDB → clasifica P1/P2 → crea ticket Jira → notifica on-call" | **n8n + Dify** | n8n orquesta, Dify clasifica/enriquece |
| "Usuario sube PDF de 50 páginas → extrae requisitos → genera user stories en Jira" | **Dify** | Workflow IA: extracción → transformación → API Jira |
| "Cada hora, consulta API de GitHub y sincroniza issues con Jira" | **n8n** | Schedule + HTTP Request + Jira = determinista |
| "Usuario pregunta: '¿Por qué falló el deploy?' → analiza logs → propone causa raíz" | **Dify Agent** | Agent con tools: logs, git, k8s |

---

## ✅ Checklist de fin de módulo

- [ ] Puedo explicar la diferencia entre workflow determinista y agente IA
- [ ] Sé identificar 3 procesos de mi entorno automatizables
- [ ] Puedo clasificar riesgo/impacto de un proceso
- [ ] Sé cuándo usar n8n vs Dify vs Make
- [ ] Entiendo los anti-patrones de automatización

---

> **Siguiente:** [Módulo 2: Primer workflow práctico con n8n](modulo-02-primer-workflow.md)

| Anti-patrón | Síntoma | Consecuencia | Solución |
|-------------|---------|--------------|----------|
| **Automatizar el caos** | Proceso sin owner, pasos ambiguos | Automatiza errores más rápido | Documentar + estandarizar **antes** |
| **Sin humano en el bucle** | Acciones irreversibles (borrar, apagar, deploy) | Incidente mayor silencioso | **Approval gate** obligatorio |
| **Credenciales hardcodeadas** | Tokens en workflows, sin vault | Fuga de secretos | n8n Credentials / Dify Secrets |
| **Sin observabilidad** | "Funcionaba ayer, hoy no" | Tiempo de detección = horas | Logs estructurados + alertas |
| **Dependencia de IA no verificada** | Agente decide acción crítica sin validación | Acción incorrecta en prod | **Validación determinista post-IA** |

---

## 1.2 Herramientas del curso

### Uso de n8n como orquestador visual de workflows e integraciones

> **n8n** = **N**ode-based **8** (workflow) **N** (automation)

| Característica | Detalle |
|----------------|---------|
| **Modelo** | Nodos (triggers, actions, logic) conectados visualmente |
| **Ejecución** | Push (webhook), Pull (polling), Scheduled, Manual |
| **Datos** | JSON nativo entre nodos, expresiones `{{ $json.field }}` |
| **Credenciales** | Gestión centralizada (OAuth, API Key, Header Auth, etc.) |
| **Despliegue** | Cloud (n8n.cloud), Self-hosted (Docker, Kubernetes, npm) |
| **Extensibilidad** | Nodos personalizados (TypeScript), código inline (Function node) |

> 💡 **Ejemplo visual para clase:** Mostrar workflow: `Webhook → Set (validación) → IF (prioridad) → HTTP Request (API) → Slack/Email`

### Uso de Dify para asistentes, workflows de IA, agentes y conocimiento documental

> **Dify** = **D**evelop **I**ntelligent **F**lows **Y** (plataforma LLMOps)

| Tipo de app | Uso | Cuándo usar |
|-------------|-----|-------------|
| **Chat Assistant** | Conversación guiada por prompt de sistema | Soporte L1, FAQ, clasificación inicial |
| **Agent** | Planifica + usa tools (API, código, búsqueda) | Tareas abiertas: "investiga y propón solución" |
| **Workflow** | Pasos de IA encadenados (extraer → clasificar → resumir) | Procesamiento documental, pipelines RAG |
| **Knowledge Base** | RAG: indexar docs → recuperar contexto → responder | Documentación técnica, runbooks, políticas |

> 🔗 **Arquitectura Dify:** `App → Prompt/Workflow → Model Provider (OpenAI, Anthropic, local) → Tools → Knowledge Base`

### Make como alternativa opcional

| Aspecto | n8n | Make (ex-Integromat) |
|---------|-----|---------------------|
| **Licencia** | Fair-code (self-hosted gratis) | Propietario (free tier limitado) |
| **UI** | Nodos + canvas | Escenarios + módulos visuales |
| **Expresiones** | JavaScript (n8n expressions) | Funciones propias (map, filter, etc.) |
| **Ejecución** | Propia (queue, workers) | Cloud gestionada |
| **Comunidad** | Muy activa, open source | Madura, muchos templates |
| **IA nativa** | Básica (Function node) | Módulos OpenAI, Anthropic integrados |

> 💡 **Recomendación:** "Usad **n8n** para orquestación técnica, self-hosted, control total. **Make** si necesitáis conectores SaaS muy específicos sin mantener infra."

### Criterios de selección en función de despliegue, gobierno, coste, facilidad de uso e integración

| Criterio | n8n | Dify | Make |
|----------|-----|------|------|
| **Self-hosted** | ✅ Docker/K8s nativo | ✅ Docker Compose/K8s | ❌ Solo cloud |
| **Gobierno de datos** | ✅ Control total | ✅ Control total | ⚠️ Datos en su cloud |
| **Coste fijo** | ✅ Infra propia | ✅ Infra + tokens modelo | ⚠️ Por operaciones |
| **Curva de aprendizaje** | Media | Media-Baja (UI guiada) | Baja |
| **Conectores técnicos** | ✅ HTTP genérico, DB, SSH | ⚠️ Via tools/API | ✅ 1000+ SaaS |
| **IA/RAG nativo** | ❌ (custom) | ✅ Core del producto | ⚠️ Módulos básicos |

> 📝 **Nota:** "En entornos corporativos con requisitos de soberanía de datos, el despliegue **n8n + Dify self-hosted** puede facilitar el control de la información."

### Revisión de entornos de laboratorio y datos ficticios autorizados

> 🧪 **Checklist de inicio de clase (5 min):**

```bash
# Verificar acceso a laboratorios
curl -s https://n8n.lab.tuempresa.com/healthz   # → "OK"
curl -s https://dify.lab.tuempresa.com/health   # → {"status":"ok"}

# Verificar credenciales de prueba (proporcionadas para el lab)
# - n8n: API Key de laboratorio
# - Dify: API Key de aplicación de prueba
# - Modelo IA: Endpoint + Key (ej. Azure OpenAI, Ollama local, etc.)
```

> ⚠️ **Recordatorio:** "Todos los datos de labs son **ficticios**. No uséis credenciales reales, datos de clientes, ni conectéis a sistemas productivos."

---

## 1.3 Prácticas (Labs)

### Lab 1.1 - Identificación de procesos técnicos candidatos a automatización

> **Duración:** 20 min | **Entrega:** Tabla completada (individual o parejas)

#### Instrucciones

1. Listad **5 procesos técnicos** que ejecutáis habitualmente en vuestro equipo
2. Para cada uno, completad:

| Proceso | Frecuencia | Tiempo manual | Entradas | Salidas | Sistemas involucrados | Dolor actual (1-5) |
|---------|------------|---------------|----------|---------|----------------------|-------------------|
| Ej: Onboarding VM | 3/semana | 45 min | Ticket, specs | VM lista, DNS, monitoring | vCenter, Infoblox, Datadog, CMDB | 4 |

#### Criterios de selección (puntuad 1-5)

- [ ] **Repetitivo** (se hace igual cada vez)
- [ ] **Basado en reglas** (decisiones SÍ/NO claras)
- [ ] **Multi-sistema** (requiere saltar entre herramientas)
- [ ] **Propenso a error** (olvidan pasos, typos)
- [ ] **Alto volumen** (>2/semana)
- [ ] **Bajo riesgo** (reversible, no crítico)

> 💡 **Puntuación ≥ 20/30** = Buen candidato para Módulo 2

#### Ejemplo resuelto

| Proceso | Frec. | Tiempo | Entradas | Salidas | Sistemas | Dolor | Repet. | Reglas | Multi-sist. | Error | Volumen | Riesgo | **Total** |
|---------|-------|--------|----------|---------|----------|-------|--------|--------|-------------|-------|---------|--------|-----------|
| Onboarding VM | 3/sem | 45 min | Ticket + specs | VM + DNS + Mon + CMDB | 4 | 4 | 5 | 5 | 5 | 4 | 3 | 2 | **24** ✅ |
| Análisis forense | 1/mes | 4h | Alertas SIEM | Informe | 3 | 5 | 2 | 2 | 3 | 3 | 1 | 5 | **16** ❌ |

---

### Lab 1.2 - Diseño del mapa de entrada, procesamiento, decisión y salida de un workflow

> **Duración:** 25 min | **Entrega:** Diagrama en papel/pizarra digital (Miro, Excalidraw, draw.io)

#### Plantilla de mapa de workflow

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────┐     ┌─────────────┐
│   ENTRADA   │────▶│  PROCESAMIENTO   │────▶│  DECISIÓN   │────▶│   SALIDA    │
│  (Trigger)  │     │  (Transformar,   │     │  (IF/Switch)│     │  (Acción,   │
│             │     │   Enriquecer,    │     │             │     │   Notificar,│
│             │     │   Validar)       │     │             │     │   Registrar)│
└─────────────┘     └──────────────────┘     └─────────────┘     └─────────────┘
       │                    │                      │                    │
   Webhook              Set/Function           IF / Switch           HTTP Request
   Schedule             HTTP Request           (condiciones)       Slack/Email
   Manual               Code                   (expresiones)       DB/Notion
```

#### Ejercicio: Diseñad el mapa para **"Clasificación y enrutamiento de alerta de monitoring"**

**Entrada:** Webhook JSON de Prometheus Alertmanager
```json
{
  "alertname": "DiskSpaceCritical",
  "instance": "prod-web-01",
  "severity": "critical",
  "value": "95%",
  "mountpoint": "/var/log"
}
```

**Procesamiento:**
1. Validar campos obligatorios (`alertname`, `instance`, `severity`)
2. Enriquecer: consultar CMDB por `instance` → obtener `owner_team`, `environment`
3. Normalizar `severity` a escala interna (P1-P4)

**Decisión:**
- SI `severity == critical` Y `environment == prod` → **P1** → Escalado inmediato (PagerDuty)
- SI `severity == warning` → **P3** → Ticket Jira + Slack al equipo
- SINO → **P4** → Log only

**Salida:**
- P1: POST PagerDuty + Slack #critical-alerts + Audit log
- P3: POST Jira + Slack #team-alerts + Audit log
- P4: Insert DB audit + Metric increment

> 💬 **Discusión en clase:** "¿Qué pasa si CMDB no responde? ¿Qué si `instance` no existe en CMDB? → **Rutas de error/fallback** (Módulo 3)"

---

### Lab 1.3 - Clasificación de casos de uso según riesgo, impacto y nivel de intervención humana

> **Duración:** 15 min | **Formato:** Matriz de decisión grupal

#### Matriz de clasificación (Riesgo × Impacto × Intervención)

| Caso de uso | Riesgo (1-5) | Impacto negocio (1-5) | Intervención humana | Clasificación | Aprobación requerida |
|-------------|--------------|----------------------|---------------------|---------------|---------------------|
| Auto-reiniciar servicio fallido | 3 | 4 | Ninguna (auto) | **Alto riesgo** | ❌ No (pero logging + alerta) |
| Crear ticket Jira desde alerta | 1 | 2 | Ninguna (auto) | **Bajo riesgo** | ❌ No |
| Apagar instancia EC2 "zombie" | 5 | 5 | **Obligatoria** | **Crítico** | ✅ Sí (approval gate) |
| Clasificar ticket con IA | 2 | 3 | Revisión opcional | **Medio** | ⚠️ Human-in-loop |
| Desplegar hotfix a prod | 5 | 5 | **Obligatoria** | **Crítico** | ✅ Sí (change advisory) |
| Enriquecer alerta con CMDB | 1 | 2 | Ninguna | **Bajo** | ❌ No |
| Responder cliente con IA (RAG) | 3 | 4 | **Obligatoria** | **Alto** | ✅ Sí (supervisión) |

#### Reglas de decisión para la clase

| Nivel | Intervención humana | Ejemplos |
|-------|---------------------|----------|
| **Nivel 0 - Full Auto** | Ninguna | Logging, notificaciones, enriquecimiento, tickets informativos |
| **Nivel 1 - Human-in-the-loop** | Revisión *post-ejecución* (auditoría) | Clasificación IA, enriquecimiento, resúmenes |
| **Nivel 2 - Human-on-the-loop** | Aprobación *pre-ejecución* (approval gate) | Acciones modificativas: reiniciar, escalar, crear recursos |
| **Nivel 3 - Human-in-command** | Decisión humana, IA solo asiste | Cambios en prod, seguridad, borrado de datos |

> ⚠️ **Regla de oro:** "Todo lo que **modifica estado** (create/update/delete) en sistemas críticos → **Nivel 2 o 3**. Solo lectura/enriquecimiento/notificación → **Nivel 0/1**."

---

## Resumen del Módulo 1

| Concepto clave | Takeaway |
|----------------|----------|
| **No-code ≠ No-logic** | La lógica existe, se expresa visualmente |
| **Determinista vs Agente** | Reglas fijas → n8n. Ambigüedad/contexto → Dify |
| **Riesgo primero** | Clasificad **antes** de construir |
| **Datos ficticios** | Laboratorios seguros = aprendizaje real sin miedo |
| **Mapa I-P-D-S** | Entrada → Procesamiento → Decisión → Salida (siempre) |

---

## 🔗 Siguiente: [Módulo 2: Primer workflow práctico con n8n](modulo-02-primer-workflow.md)

> **Preparad:** Acceso a n8n lab, credenciales de prueba, el mapa del Lab 1.2 listo para implementar.
