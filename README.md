<p align="center">
  <img src="https://raw.githubusercontent.com/storytold/figcraft/main/assets/app-icon/hicolor/256x256/apps/ai.storyteller.figcraft.png" alt="FigCraft icon" width="128">
</p>

<h1 align="center">FigCraft Web</h1>

<p align="center">
  A self-hosted WebAssembly build of <a href="https://github.com/storytold/figcraft">FigCraft</a>, the open-source interface design and prototyping application built in Rust.
</p>

<p align="center">
  <a href="https://github.com/MikaPST/figcraft-web/actions/workflows/publish-image.yml"><img src="https://github.com/MikaPST/figcraft-web/actions/workflows/publish-image.yml/badge.svg" alt="Build and publish"></a>
  <a href="https://github.com/MikaPST/figcraft-web/pkgs/container/figcraft-web"><img src="https://img.shields.io/badge/GHCR-figcraft--web-blue?logo=docker" alt="GHCR"></a>
</p>

## Why this repository?

This repository packages the official FigCraft WebAssembly application as a Docker image, making it straightforward to deploy on Unraid or any Docker-compatible host.

It does not modify the upstream application. The web application is built from the official `storytold/figcraft` source and served as static files by NGINX.

## How it works

- GitHub Actions checks out the latest upstream `main` branch.
- Rust and the `wasm32-unknown-unknown` target are installed.
- Trunk builds the official web application from `apps/figcraft-web`.
- The generated `dist/web` files are packaged into a lightweight NGINX image.
- The image is published for `linux/amd64` and `linux/arm64` to GitHub Container Registry.

The upstream web application uses eframe's browser runner, with WebGPU and a WebGL2 fallback. The web build is the FigCraft editor running in the browser; it is not the desktop application or the separate `figcraft-server`.

## Docker image

```bash
docker pull ghcr.io/mikapst/figcraft-web:latest
```

| Setting | Value |
| --- | --- |
| Image | `ghcr.io/mikapst/figcraft-web:latest` |
| Container port | `8080` |
| Architectures | `linux/amd64`, `linux/arm64` |
| Web server | NGINX |

### Docker Compose

```yaml
services:
  figcraft-web:
    image: ghcr.io/mikapst/figcraft-web:latest
    container_name: figcraft-web
    ports:
      - "8080:8080"
    restart: unless-stopped
```

## Automated builds

The GitHub Actions workflow publishes the container image:

- On changes to this repository's README, Compose file or workflow.
- On manual dispatch.
- On a weekly schedule, to pick up upstream changes.

Published tags:

- `latest` — most recent successful build.
- `upstream-<commit>` — the upstream commit used for the build.

## Build pipeline

1. Checkout `storytold/figcraft` (`main`).
2. Install the Rust stable toolchain and `wasm32-unknown-unknown`.
3. Install Trunk and build with `trunk build --release` from `apps/figcraft-web`.
4. Create a temporary Docker build context containing the generated `dist/web` output and an NGINX configuration.
5. Build and push a multi-platform image to GHCR.

The upstream `Trunk.toml` configures the output directory as `dist/web` relative to the repository root and enables content-hashed asset names. The generated NGINX configuration serves `index.html` without caching and gives hashed assets long-lived immutable caching.

## Unraid Community Applications

This image can be used as the basis for an Unraid Community Applications template. Configure the container port as `8080` and map it to a host port of your choice.

## Upstream project and attribution

- **Project:** [FigCraft](https://getartcraft.com/apps/figcraft)
- **Source code:** [storytold/figcraft](https://github.com/storytold/figcraft)
- **Publisher:** ArtCraft Team and contributors
- **License:** FigCraft is dual-licensed under [MIT](https://github.com/storytold/figcraft/blob/main/LICENSE-MIT) or [Apache-2.0](https://github.com/storytold/figcraft/blob/main/LICENSE-APACHE), at your option. Bundled assets and branding may have separate terms; consult the upstream `NOTICE`, `ATTRIBUTION.md` and brand license.

This repository is an independent container packaging project. It is not affiliated with or endorsed by the upstream maintainers.

## License / Disclaimer

The packaging files in this repository are provided under the MIT License. The FigCraft application remains subject to its upstream licenses and notices.

FigCraft is currently in alpha. The upstream project notes that `.fig` import is best effort and that live collaboration is a preview feature. Consult the [official project page](https://getartcraft.com/apps/figcraft) and [upstream README](https://github.com/storytold/figcraft#readme) for current status and limitations.
