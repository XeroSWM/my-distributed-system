events {}
http {
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

        location /api/auth/ {
            rewrite ^/api/auth/(.*) /$1 break;
            proxy_pass http://auth_service;
        }
        location /api/core/ {
            rewrite ^/api/core/(.*) /$1 break;
            proxy_pass http://core_service;
        }
        location /api/dashboard/ {
            rewrite ^/api/dashboard/(.*) /$1 break;
            proxy_pass http://dashboard_service;
        }
    }
}