# 1. Usamos la imagen de Node que ya tenías
FROM node:22-alpine

WORKDIR /app

# 2. Definimos los argumentos que recibirá desde Docker Compose o la terminal
# Esto permite que las IPs de Auth, Core y Dashboard entren al build
ARG VITE_AUTH_URL
ARG VITE_CORE_URL
ARG VITE_DASHBOARD_URL

# 3. Convertimos esos argumentos en variables de entorno del contenedor
ENV VITE_AUTH_URL=$VITE_AUTH_URL
ENV VITE_CORE_URL=$VITE_CORE_URL
ENV VITE_DASHBOARD_URL=$VITE_DASHBOARD_URL

# 4. Instalación de dependencias
COPY package*.json ./
RUN npm install

# 5. Copiamos el resto del código
COPY . .

# 6. Cambiamos el EXPOSE al 3000 (que es el que usas en AWS)
EXPOSE 3000

# 7. Comando para arrancar en modo desarrollo forzando el host
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0", "--port", "3000"]