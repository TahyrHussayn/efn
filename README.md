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
# Install dependencies
pnpm install

# Start the development server
pnpm dev
```

Open [http://localhost:3000](http://localhost:3000) to view the app.

## Docker

The project ships with a production-optimized, multi-stage [Dockerfile](./Dockerfile).

```bash
# Build the image
docker build -t efn .

# Run the container
docker run -p 3000:3000 efn
```

## Project Structure

```
src/
└── app/
    ├── globals.css    # Tailwind imports + CSS custom properties
    ├── layout.tsx     # Root layout (fonts, metadata)
    └── page.tsx       # Home page
```

## Scripts

| Command | Description |
| --- | --- |
| `pnpm dev` | Start development server |
| `pnpm build` | Create production build |
| `pnpm start` | Run production server |
| `pnpm lint` | Lint with Biome |
| `pnpm format` | Format with Biome |
