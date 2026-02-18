#!/bin/bash
set -e

# 1. Instalar Nginx (El servidor web que hará de Gateway)
apt-get update
apt-get install -y nginx

# 2. Configurar Nginx
# Terraform va a reemplazar ${auth_ip}, ${core_ip}, etc. con las IPs reales antes de enviar este script.
cat <<EOF > /etc/nginx/conf.d/gateway.conf
upstream auth_service {
    server ${auth_ip}:3001;
}

upstream core_service {
    server ${core_ip}:3002;
}

upstream dashboard_service {
    server ${dashboard_ip}:3003;
}

server {
    listen 80;

    # --- RUTA AUTH ---
    location /api/auth/ {
        # Borramos el prefijo /api/auth antes de mandarlo al microservicio
        rewrite ^/api/auth/(.*) /\$1 break;
        proxy_pass http://auth_service;
        
        # Cabeceras importantes
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    # --- RUTA CORE ---
    location /api/core/ {
        rewrite ^/api/core/(.*) /\$1 break;
        proxy_pass http://core_service;
        
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    # --- RUTA DASHBOARD ---
    location /api/dashboard/ {
        rewrite ^/api/dashboard/(.*) /\$1 break;
        proxy_pass http://dashboard_service;
        
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

# 3. Borrar la configuración por defecto para que no estorbe
rm -f /etc/nginx/sites-enabled/default

# 4. Reiniciar Nginx para aplicar cambios
systemctl restart nginx