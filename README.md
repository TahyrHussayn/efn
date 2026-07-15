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

## Deployment

Push to `main` → GitHub Actions builds the Docker image → pushes to GHCR → deploys to EC2 via AWS SSM.

### Infrastructure

| Component | Detail |
| --- | --- |
| **Compute** | EC2 t3.medium, Ubuntu 24.04 |
| **Reverse Proxy** | Caddy (auto TLS via Cloudflare DNS challenge) |
| **Container Registry** | GitHub Container Registry (ghcr.io) |
| **CI/CD** | GitHub Actions (OIDC → SSM, no static keys) |
| **DNS** | Cloudflare (proxied, Full Strict) |

### EC2 Setup

1. Spin up your Ubuntu 24.04 EC2 instance.
2. Ensure the AWS Systems Manager (SSM) Agent is running (pre-installed by default on Ubuntu AMIs).
3. Configure the OIDC Trust Policy in AWS IAM.
4. That's it! GitHub Actions will automatically install Docker, write the configs/certs, and start the app on your first push.

### GitHub Repository Secrets

Configure these in **Settings → Secrets and variables → Actions → Secrets**:

| Secret | Description |
| --- | --- |
| `CLOUDFLARE_CERT` | The PEM text block of your Cloudflare Origin Certificate |
| `CLOUDFLARE_KEY` | The Private Key text block of your Cloudflare Origin Certificate |

### GitHub Repository Variables

Configure these in **Settings → Secrets and variables → Actions → Variables**:

| Variable | Value |
| --- | --- |
| `AWS_ROLE_ARN` | `arn:aws:iam::<account>:role/<role-name>` |
| `AWS_REGION` | e.g. `ap-south-1` |
| `EC2_INSTANCE_ID` | e.g. `i-0abc123def456` |

## Project Structure

```
src/app/                    # Next.js app
  ├── globals.css
  ├── layout.tsx
  └── page.tsx
infra/                      # EC2 deployment folder
  ├── docker-compose.yml
  ├── Caddyfile
  └── certs/                # Mount folder for Cloudflare Origin Certs (gitignored)
.github/workflows/
  └── deploy.yml            # CI/CD pipeline
Dockerfile                  # Next.js production image
```

## Scripts

| Command | Description |
| --- | --- |
| `pnpm dev` | Start development server |
| `pnpm build` | Create production build |
| `pnpm start` | Run production server |
| `pnpm lint` | Lint with Biome |
| `pnpm format` | Format with Biome |
