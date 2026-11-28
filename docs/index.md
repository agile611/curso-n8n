# Curso: Automatización y agentes sin código para perfiles técnicos

> **Guión de clase** — Estructura completa con ejemplos prácticos para impartir el curso de 18 horas.

---

## 🚀 Primer paso: Preparar el entorno de laboratorio

**Antes de empezar el Módulo 1**, necesitas el entorno funcionando en la máquina Ubuntu 24.04 del laboratorio.

> 📖 **Guía completa**: [Guía Laboratorios Ubuntu 24.04](guia_laboratorios_ubuntu24.md)

### Resumen rápido (ejecutar en el servidor de lab)

```bash
# 1. Conectar al servidor Ubuntu 24.04
ssh curso@<IP_DE_TU_SERVIDOR>

# 2. Clonar repositorio y preparar variables
cd ~
git clone https://github.com/agile611/curso-n8n.git
cd curso-n8n

cat > .env.lab << 'EOF'
# ⚠️ Reemplaza <IP_DE_TU_SERVIDOR> por la IP real de tu máquina Ubuntu 24.04
LAB_HOST=<IP_DE_TU_SERVIDOR>
POSTGRES_PASSWORD=n8n_lab_2026
REDIS_PASSWORD=redis_lab_2026
N8N_BASIC_AUTH_PASSWORD=n8n_lab_2026
N8N_ENCRYPTION_KEY=clave_secreta_32_chars_minimo!!
DIFY_SECRET_KEY=dify_secret_key_32_chars_minimo!!
EOF

# 3. Levantar stack completo (n8n + Dify + PostgreSQL + Redis + Docs)
chmod +x init-multiple-dbs.sh envsubst.sh
docker compose -f docker-compose.lab.yml --env-file .env.lab up -d

# 4. Verificar que todo está "healthy" (2-3 min)
docker compose -f docker-compose.lab.yml ps
```

### Verificar accesos (desde TU navegador local)

| Servicio | URL | Credenciales |
|----------|-----|--------------|
| **Documentación del curso** | `http://<IP_DE_TU_SERVIDOR>/docs/` | Pública |
| **n8n** | `http://<IP_DE_TU_SERVIDOR>/n8n/` | `admin` / `n8n_lab_2026` |
| **Dify** | `http://<IP_DE_TU_SERVIDOR>/dify/` | `admin@lab.local` / `dify_lab_2026` |

> 🔔 **Dify primera vez**: Al abrir `http://<IP_DE_TU_SERVIDOR>/dify/` verás *"Dify has not been initialized..."*. **Es normal** → Completa el [Setup Wizard](guia_laboratorios_ubuntu24.md) (crear admin, workspace, skip model provider si no tienes API Key).

> 🌐 **Comportamiento esperado del navegador**: sin sesión iniciada, Dify termina en `http://<IP_DE_TU_SERVIDOR>/signin?redirect_url=%2F`. Una página de login estable sin bucles de `redirect_url` indica que la ruta está correcta.

> 🔧 **Fixes ya aplicados**: n8n secure cookie, PostgreSQL idempotente, Dify OOM, API URL via nginx, static assets, setup wizard, IP dinámica con LAB_HOST. Ver [Guía Laboratorios §0.7](guia_laboratorios_ubuntu24.md).

---

## Información general

| Aspecto | Detalle |
|---------|---------|
| **Duración** | 18 horas |
| **Formato** | Teoría + Laboratorios guiados (n8n + Dify) |
| **Nivel** | Intermedio técnico |
| **Herramientas** | n8n (orquestación), Dify (IA/RAG/agentes), Make (alternativa) |

---

## Objetivos de aprendizaje

Al finalizar el curso, los participantes serán capaces de:

- ✅ **Diseñar, construir y validar** automatizaciones y agentes sin código aplicados a escenarios técnicos corporativos
- ✅ **Orquestar workflows** con n8n: eventos, webhooks, integraciones vía API
- ✅ **Crear asistentes, workflows de IA, bases de conocimiento y agentes** con Dify
- ✅ **Aplicar criterios de seguridad, trazabilidad, validación humana, gestión de credenciales, control de errores y gobierno técnico**
- ✅ **Pasar de un prototipo a un piloto controlado** con garantías

---

## Perfil del participante

> **Profesionales técnicos** de IT, sistemas, cloud, ciberseguridad, DevOps, operaciones, arquitectura, datos, soporte o automatización que necesiten incorporar flujos no-code/low-code y agentes de IA a procesos internos.

> Especialmente dirigido a personas que **entienden procesos técnicos y sistemas corporativos**, aunque no necesariamente desarrollen software de forma habitual.

---

## Prerrequisitos

- Conocimientos básicos de procesos IT, operación de sistemas o integración de aplicaciones
- Familiaridad básica con **APIs REST, JSON, webhooks, autenticación mediante tokens**
- Navegador actualizado y acceso a los entornos de laboratorio (n8n y Dify)
- Acceso a un modelo de IA o endpoint
- Conocimientos básicos de **Docker/contenedores** (recomendable para self-hosted)
- Documentación, datos y casos de laboratorio **ficticios, anonimizados o autorizados**
- Acceso desde la red del participante a las herramientas y servicios del laboratorio

---

## Estructura del curso (18 horas)

| Módulo | Título | Horas estimadas |
|--------|--------|-----------------|
| 1 | Fundamentos de automatización y agentes sin código | 2h |
| 2 | Primer workflow práctico con n8n | 2h |
| 3 | Eventos, webhooks e integración con sistemas | 2h |
| 4 | Asistentes y workflows de IA con Dify | 2h |
| 5 | RAG y bases de conocimiento para documentación técnica | 2h |
| 6 | Orquestación de agentes con Dify y n8n | 3h |
| 7 | Seguridad, gobierno y calidad en automatizaciones con IA | 2h |
| 8 | Operación, mantenimiento y ciclo de vida | 2h |
| 9 | Caso práctico final integrado | 3h |
| **Total** | | **18h** |

---

## Navegación por módulos

### Módulos teórico-prácticos
- [Módulo 1: Fundamentos](modulos/modulo-01-fundamentos.md)
- [Módulo 2: Primer workflow con n8n](modulos/modulo-02-primer-workflow.md)
- [Módulo 3: Eventos, webhooks e integraciones](modulos/modulo-03-eventos-webhooks.md)
- [Módulo 4: Asistentes y workflows de IA con Dify](modulos/modulo-04-asistentes-dify.md)
- [Módulo 5: RAG y bases de conocimiento](modulos/modulo-05-rag-conocimiento.md)
- [Módulo 6: Orquestación de agentes](modulos/modulo-06-orquestacion-agentes.md)
- [Módulo 7: Seguridad, gobierno y calidad](modulos/modulo-07-seguridad-gobierno.md)
- [Módulo 8: Operación y ciclo de vida](modulos/modulo-08-operacion-ciclo-vida.md)
- [Módulo 9: Caso práctico final](modulos/modulo-09-caso-final.md)

### Documentación de apoyo
- [Guía Laboratorios Ubuntu 24.04](guia_laboratorios_ubuntu24.md) - Setup completo, comandos, troubleshooting
- [Temario Adaptado](temario_adaptado.md) - Correspondencia temario original ↔ módulos
- [Plantilla Documentación Workflow](workflow_doc_template.md) - Estándar para documentar workflows
- [Política Seguridad Mínima](security_policy_template.md) - Checklist seguridad prototipo → piloto
- [Guía Despliegue](deploy.md) - Despliegue nativo/Docker en Ubuntu 24.04
- [Referencia Rápida](quick_reference.md) - Hoja de chuleta: URLs, comandos, expresiones
- [Recursos y referencias](recursos.md) - Enlaces curados: docs oficiales, comunidades, certificaciones, lecturas, plantillas del curso

---

## Metodología

> 🎯 **Cada módulo combina:**
> - **Conceptos** (15-20 min)
> - **Demostración en vivo** (10-15 min)
> - **Laboratorio guiado** (30-45 min)
> - **Revisión y preguntas** (10 min)

> 💡 **Los laboratorios usan datos ficticios** — Nunca información productiva sensible.

---

## Recursos de apoyo

- 📚 [Documentación oficial n8n](https://docs.n8n.io/)
- 📚 [Documentación oficial Dify](https://docs.dify.ai/)
- 🐳 [Docker Hub n8n](https://hub.docker.com/r/n8nio/n8n)
- 🐳 [Docker Hub Dify](https://hub.docker.com/r/langgenius/dify-api)
- 💬 Comunidad n8n: [community.n8n.io](https://community.n8n.io/)
- 💬 Comunidad Dify: [github.com/langgenius/dify/discussions](https://github.com/langgenius/dify/discussions)

---

## Convenciones en este guión

| Símbolo | Significado |
|---------|-------------|
| 💡 | **Tip / Buena práctica** |
| ⚠️ | **Punto de atención** / Error común |
| 🧪 | **Laboratorio** - Actividad práctica |
| 💬 | **Pregunta de discusión** |
| 📝 | **Nota importante** |
| 🔗 | **Enlace a recurso externo** |
| `código` | Código, comandos, JSON, expresiones n8n |
| **negrita** | Conceptos clave / Términos del glosario |

---

> **¿Entorno listo?** → [Módulo 1: Fundamentos](modulos/modulo-01-fundamentos.md)
