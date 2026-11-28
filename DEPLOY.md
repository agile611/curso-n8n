# Guía de Despliegue - Curso n8n en Ubuntu 24.04

## Opciones de Despliegue

### 1. Docker Compose (Recomendado)
```bash
# Clonar repositorio
git clone https://github.com/agile611/curso-n8n.git
cd curso-n8n

# Levantar servicios
docker compose up -d

# Ver logs
docker compose logs -f

# Detener
docker compose down
```

**Servicios incluidos:**
- `curso-n8n`: MkDocs Material en puerto 8000
- `nginx`: Reverse proxy en puerto 80/443
- `certbot`: Renovación automática de certificados SSL (opcional)

---

### 2. Despliegue Nativo con Script
```bash
# Clonar repositorio
git clone https://github.com/agile611/curso-n8n.git
cd curso-n8n

# Ejecutar script de despliegue (requiere sudo)
sudo ./deploy-ubuntu.sh --native
```

**Qué hace el script:**
- Instala Python 3, pip, venv, git, nginx, ufw
- Crea usuario `mkdocs` sin privilegios
- Clona/actualiza el repositorio en `/opt/curso-n8n`
- Crea entorno virtual e instala dependencias
- Construye el sitio con `mkdocs build --strict`
- Configura servicio systemd para auto-inicio
- Configura nginx como reverse proxy
- Configura firewall (UFW)

---

### 3. Despliegue con Docker (Script)
```bash
sudo ./deploy-ubuntu.sh --docker
```

---

## Requisitos Previos

### Ubuntu 24.04 LTS
```bash
# Actualizar sistema
sudo apt-get update && sudo apt-get upgrade -y

# Instalar Docker (si no está)
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
newgrp docker

# Instalar Docker Compose
sudo apt-get install -y docker-compose-plugin
```

---

## Configuración de Dominio y SSL

### Con Certbot (Let's Encrypt)
```bash
# 1. Configurar dominio en nginx.conf
# Cambiar server_name _; por server_name tudominio.com;

# 2. Obtener certificado
sudo docker compose run --rm certbot certonly \
    --webroot -w /var/www/certbot \
    -d tudominio.com \
    --email admin@tudominio.com \
    --agree-tos --no-eff-email

# 3. Descomentar bloque HTTPS en nginx.conf y recargar
sudo docker compose exec nginx nginx -s reload
```

### Renovación automática
El servicio `certbot` en docker-compose.yml renueva automáticamente cada 12 horas.

---

## Variables de Entorno

| Variable | Descripción | Default |
|----------|-------------|---------|
| `COURSE_NAME` | Nombre del curso | "Curso Automatización y agentes sin código" |
| `COURSE_VERSION` | Versión | "1.0" |
| `MKDOCS_PORT` | Puerto interno MkDocs | 8000 |

---

## Estructura de Directorios en Producción

```
/opt/curso-n8n/           # Código fuente (despliegue nativo)
├── venv/                 # Entorno virtual Python
├── site/                 # Sitio generado (mkdocs build)
├── docs/                 # Documentos fuente
├── mkdocs.yml            # Configuración MkDocs
└── requirements.txt      # Dependencias Python

/var/www/certbot/         # Webroot para Certbot
/etc/letsencrypt/         # Certificados SSL
/var/log/nginx/           # Logs de Nginx
```

---

## Comandos Útiles

### Ver estado de servicios
```bash
# Docker Compose
docker compose ps
docker compose logs -f curso-n8n

# Systemd (despliegue nativo)
sudo systemctl status curso-n8n
sudo journalctl -u curso-n8n -f

# Nginx
sudo systemctl status nginx
sudo nginx -t
```

### Reconstruir sitio
```bash
# Docker
docker compose build --no-cache curso-n8n
docker compose up -d curso-n8n

# Nativo
cd /opt/curso-n8n
source venv/bin/activate
mkdocs build --strict
sudo systemctl restart curso-n8n
```

### Backup
```bash
# Backup del sitio generado
tar -czf backup-$(date +%Y%m%d).tar.gz /opt/curso-n8n/site

# Backup de certificados
tar -czf certs-backup-$(date +%Y%m%d).tar.gz /etc/letsencrypt
```

---

## Solución de Problemas

### Puerto 8000 no accesible
```bash
# Verificar firewall
sudo ufw status
sudo ufw allow 8000/tcp

# Verificar servicio
sudo systemctl status curso-n8n
# o
docker-compose logs curso-n8n
```

### Error 502 Bad Gateway
```bash
# Verificar que MkDocs está corriendo
curl http://localhost:8000/

# Verificar nginx config
sudo nginx -t
sudo systemctl reload nginx
```

### Certificados SSL no renuevan
```bash
# Forzar renovación
docker compose run --rm certbot renew --force-renewal

# Verificar logs
docker compose logs certbot
```

---

## Seguridad

### Headers de seguridad (ya configurados en nginx.conf)
- X-Frame-Options: SAMEORIGIN
- X-Content-Type-Options: nosniff
- X-XSS-Protection: 1; mode=block
- Referrer-Policy: strict-origin-when-cross-origin

### Firewall (UFW)
```bash
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable
```

### Usuario no-root
El contenedor y el servicio systemd corren como usuario `mkdocs` (UID 999).

---

## Actualizaciones

```bash
# 1. Obtener últimos cambios
git pull origin main

# 2. Reconstruir y reiniciar
# Docker:
docker compose build --no-cache && docker compose up -d

# Nativo:
cd /opt/curso-n8n
source venv/bin/activate
pip install -r requirements.txt
mkdocs build --strict
sudo systemctl restart curso-n8n
```

---

## Monitoreo

### Health Check
```bash
# Endpoint de salud
curl http://localhost/health
# Respuesta: healthy
```

### Logs centralizados
```bash
# Nginx access logs
tail -f /var/log/nginx/access.log

# MkDocs logs (systemd)
journalctl -u curso-n8n -f

# Docker logs
docker compose logs -f --tail=100
```

---

## Contacto y Soporte

- **Repositorio**: https://github.com/agile611/curso-n8n
- **Issues**: https://github.com/agile611/curso-n8n/issues
- **Documentación**: https://docs.agile611.com/curso-n8n/
