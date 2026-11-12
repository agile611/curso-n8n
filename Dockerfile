# Dockerfile para Curso n8n - Ubuntu 24.04
# Uso: docker build -t curso-n8n . && docker run -p 8000:8000 curso-n8n

FROM ubuntu:24.04

# Evitar prompts interactivos durante la instalación
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Variables de entorno para el curso
ENV COURSE_NAME="Curso Automatización y agentes sin código"
ENV COURSE_VERSION="1.0"
ENV MKDOCS_PORT=8000

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    git \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Crear usuario no-root para seguridad
RUN groupadd -r mkdocs && useradd -r -g mkdocs -m -d /home/mkdocs -s /bin/bash mkdocs

# Directorio de trabajo
WORKDIR /app

# Copiar requirements primero para aprovechar cache de Docker
COPY requirements.txt ./

# Instalar dependencias Python
RUN pip3 install --no-cache-dir --break-system-packages -r requirements.txt

# Copiar el resto del proyecto
COPY . .

# Cambiar ownership al usuario mkdocs
RUN chown -R mkdocs:mkdocs /app

# Cambiar a usuario no-root
USER mkdocs

# Exponer puerto
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/ || exit 1

# Comando por defecto: servir con mkdocs
CMD ["mkdocs", "serve", "--dev-addr=0.0.0.0:8000"]
