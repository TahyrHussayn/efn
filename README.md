# efn

A [Next.js 16](https://nextjs.org) application built with React 19, TypeScript, and Tailwind CSS v4.

## Tech Stack

- **Framework** — Next.js 16 (App Router)
- **UI** — React 19 + React Compiler
- **Language** — TypeScript 5
- **Styling** — Tailwind CSS v4
- **Linting** — Biome
- **Package Manager** — pnpm

## Getting Started

```bash
pnpm install
pnpm dev
```

Open [http://localhost:3000](http://localhost:3000) to view the app.

## Zero-Variables Automated Deployment

All infrastructure and deployments are 100% automated via Terraform and GitHub Actions. There are **no manual variable settings** required on GitHub.

### 1. Provision AWS Infrastructure
Run this locally from the project root:
```bash
cd terraform
terraform init
terraform apply
```
This builds your EC2 server, static Elastic IP, OIDC trust provider, and SSM roles.

### 2. Configure Cloudflare DNS & SSL
*   Point an **A record** for `efn.tahyrhussayn.online` to the `elastic_ip` output printed by Terraform (proxied, orange cloud).
*   Go to **SSL/TLS → Origin Server → Create Certificate**.
*   Save the certificate PEM and private key PEM.
*   Set SSL mode to **Full (Strict)**.

### 3. Save Cloudflare Certs to GitHub
Go to GitHub Repository Settings → **Secrets and variables → Actions → Secrets** (New repository secret):

| Secret Name | Value |
| --- | --- |
| `CLOUDFLARE_CERT` | Your Cloudflare Origin Certificate PEM block |
| `CLOUDFLARE_KEY` | Your Cloudflare Private Key PEM block |

*(Note: There is **no need** to set any Repository Variables like region, roles, or instance IDs. The pipeline resolves them dynamically!)*

### 4. Push to Main
```bash
git add .
git commit -m "Initialize Zero-Variables Deployment"
git push origin main
```
The pipeline will automatically lint your code, build the standalone Docker image, push it to GHCR, install Docker on the server (if missing), write Caddy proxy configurations and SSL certs, and start the app.

---

## Real-Time Monitoring Dashboard

A system-wide **Beszel** monitoring panel is deployed directly inside the container stack.

*   **URL:** `https://monitor-efn.tahyrhussayn.online`

On your first visit, you will be prompted to create your admin username and password. 

### Registering the server in Beszel:
1. Log in to the Beszel dashboard.
2. Click **Add System**.
3. Set **Name** to `efn-server`.
4. Set **Host / IP** to `/beszel_socket/beszel.sock` (this connects to the local agent socket).
5. Click **Add**. The dashboard will instantly start displaying your CPU, RAM, Network, and individual Docker container statistics.


