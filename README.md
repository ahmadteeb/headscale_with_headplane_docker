# Headscale & Headplane Deployment

This repository provides a docker-compose setup to deploy [Headscale](https://github.com/juanfont/headscale) (an open-source Tailscale control server) with [Headplane](https://github.com/tale/headplane) (a web UI management dashboard for Headscale).

It includes configuration examples and an Nginx reverse proxy template to serve Headscale at the root path (`/`) and Headplane at `/admin/`.

## Prerequisites

- **Docker** and **Docker Compose** installed on your server.
- **Nginx** (or another reverse proxy) to expose the service.
- **Certbot / SSL certificates** to serve the UI and API securely.
- A **Domain Name** (e.g., `vpn.example.com`) pointed to your server's IP address.

## Installation & Setup

### 1. Prepare Configuration Files

First, copy the example configurations provided in the repository to their active locations:

```bash
# Setup Headscale config
cp headscale/config.example.yaml headscale/config.yaml

# Create an empty DNS records file if you plan to use it (required by docker volume mounts)
touch headscale/dns_records

# Setup Headplane config
cp headplane/config.example.yaml headplane/config.yaml
```

### 2. Configure Headscale

Edit `headscale/config.yaml`:
- Change server URl to your chosen domain: `server_url: https://vpn.example.com`
- Configure `listen_addr: 0.0.0.0:8080`
- Adjust other settings like `magic_dns`, `base_domain`, and `prefixes` depending on your network setup.

### 3. Configure Headplane

Edit `headplane/config.yaml`:
- Update `cookie_secret` to a random, secure 32-character string.
- Set `headscale.public_url: "https://vpn.example.com"` to match your Headscale public domain.
- Ensure `headscale.url: "http://headscale:8080"` is kept as-is, since Headplane communicates with Headscale internally over the Docker network.

### 4. Start the Services

Once the configurations are in place, start the containers in detached mode:

```bash
docker compose up -d
```

### 5. Setup Nginx Reverse Proxy

An example Nginx configuration is provided in `nginx/vpn.example.com`.
Copy it to your Nginx sites directory and replace `vpn.example.com` with your actual domain:

```bash
sudo cp nginx/vpn.example.com /etc/nginx/sites-available/vpn.example.com
```

Edit `/etc/nginx/sites-available/vpn.example.com`:
- Change `server_name vpn.example.com;` to your domain.

Enable the site and reload Nginx:
```bash
sudo ln -s /etc/nginx/sites-available/vpn.example.com /etc/nginx/sites-enabled/
sudo nginx -s reload
```

Obtain an SSL certificate (Headscale requires HTTPS for Tailscale clients):
```bash
sudo certbot --nginx -d vpn.example.com
```

## First Login & Usage

The Nginx configuration splits traffic based on the path:
- **Headscale API / Node connection**: `https://vpn.example.com`
- **Headplane Admin Dashboard**: `https://vpn.example.com/admin/`

### Generating an API Key for Headplane

To log into Headplane for the first time, you need an API key from Headscale. Generate one by executing the following command inside the Headscale container:

```bash
docker exec -it headscale headscale apikeys create
```

Copy the generated API key and use it to authenticate on the Headplane web interface at `https://vpn.example.com/admin/`.

From the Headplane dashboard, you can now manage your Tailnet, users, pre-auth keys, and DNS records.
