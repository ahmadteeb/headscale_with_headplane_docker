server {
  server_name vpn.example.com;

  access_log /var/log/nginx/vpn.example.com.access.log;
  error_log /var/log/nginx/vpn.example.com.error.log;

  listen 80;
  listen [::]:80;

  location / { # Headscale runs on the root path
        proxy_pass http://172.18.1.2:8080; # Adjust if Headscale runs on a different port
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Host $host;
        proxy_redirect http:// https://;
        proxy_buffering off;

        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        add_header Strict-Transport-Security "max-age=15552000; includeSubDomains" always;
    }

    location /admin/ { # Headplane is served under /admin
        proxy_pass http://172.18.1.3:3000; # Adjust if Headplane runs on a different port
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Host $host;
        proxy_redirect http:// https://;
        proxy_buffering off;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}