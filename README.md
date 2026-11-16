<p align="center">
  <img src="https://raw.githubusercontent.com/storytold/figcraft/main/assets/app-icon/hicolor/256x256/apps/ai.storyteller.figcraft.png" width="128" height="128" alt="FigCraft icon">
</p>

<h1 align="center">FigCraft Web — Docker Image</h1>
<p align="center">
  Community-maintained Docker packaging for the browser version of
  <a href="https://github.com/storytold/figcraft">FigCraft</a>.<br>
  Automated WebAssembly builds and publication to GitHub Container Registry (GHCR).
</p>

<p align="center">
  <a href="https://github.com/MikaPST/figcraft-web/actions/workflows/publish-image.yml"><img src="https://github.com/MikaPST/figcraft-web/actions/workflows/publish-image.yml/badge.svg" alt="Build"></a>
  <a href="https://github.com/MikaPST/figcraft-web/releases/latest"><img src="https://img.shields.io/github/v/release/MikaPST/figcraft-web?label=Release&logo=github&color=blue" alt="Release"></a>
  <a href="https://github.com/MikaPST/figcraft-web/pkgs/container/figcraft-web"><img src="https://ghcr-badge.egpl.dev/mikapst/figcraft-web/latest_tag?trim=major&label=GHCR" alt="GHCR"></a>
  <a href="docker-compose.yml"><img src="https://img.shields.io/badge/Docker%20Compose-ready-2496ED?logo=docker&logoColor=white" alt="Docker Compose"></a>
</p>

---

## Why this repository?

[FigCraft](https://github.com/storytold/figcraft) is a Rust-based interface design, prototyping, and vector-editing application with an official browser edition. This repository packages its **official WebAssembly build** as a static site served by NGINX.

The goals are to:

- Build FigCraft Web from an **official upstream release tag**, not an arbitrary development commit.
- Publish ready-to-run `linux/amd64` and `linux/arm64` Docker images to GHCR.
- Check for new official releases daily and support manual or forced rebuilds.
- Publish a matching GitHub Release **only after** the Docker image has been pushed successfully.
- Keep the `Dockerfile`, `nginx.conf`, `.dockerignore`, and workflow independently version-controlled.
- Include the required shared fonts from `storytold/craft-fonts`.
- Preserve upstream license and font attribution notices.
- Provide Docker Compose and a separately maintained Unraid Community Applications template.

This is independent community packaging, **not an official FigCraft distribution**.

## How it works

FigCraft Web runs directly in the user's browser using WebAssembly. The Docker container serves static files: it is **not** a remote desktop, a rendering server, or a document-storage backend.

- **Design and prototyping:** interface layouts, components, variants, vector graphics, prototypes, and developer inspection tools.
- **WebAssembly rendering:** application logic executes locally in the browser.
- **GPU:** WebGPU where available, with WebGL2 fallback. WebAssembly SIMD is required.
- **Fonts:** the build embeds selected shared fonts. Chromium-family browsers can optionally request permission to use locally installed fonts.
- **File handling:** browser edition capabilities differ from the desktop application; consult the upstream hosting documentation for supported open/save workflows.
- **Collaboration:** the browser edition can join desktop-hosted live sessions and use a separately deployed `figcraft-server`. This Docker image **does not bundle or launch** that server.

The upstream web edition does not expose the desktop TCP control server. It can be embedded into another website, and advanced host integrations are documented upstream.

> [!IMPORTANT]
> FigCraft is in early alpha. Keep separate copies of important design files. Do not assume this static image stores or backs up user projects.

### Browser and HTTPS requirements

WebGPU and some clipboard features require a secure context: `https://` or `http://localhost`. On ordinary HTTP LAN addresses, the browser may fall back to WebGL2. Modern browsers with WebAssembly SIMD support are required; upstream notes specify Safari 16.4 or later.

For remote access, use HTTPS through a reverse proxy such as Traefik. The upstream application does not require `SharedArrayBuffer` isolation headers.

## Docker image

Published to GHCR after successful workflow execution:

```text
ghcr.io/mikapst/figcraft-web:latest
```

To pin a published upstream version, use its exact official tag, for example `ghcr.io/mikapst/figcraft-web:v0.18.1` **if that tag has been published in this repository**.

The `latest` tag is mutable. A forced rebuild can also update a versioned tag; pin an image digest for exact binary reproducibility.

### Option 1 — Docker Compose (recommended)

The repository's `docker-compose.yml` contains:

```yaml
services:
  figcraft-web:
    image: ghcr.io/mikapst/figcraft-web:latest
    container_name: figcraft-web
    ports:
      - "8080:8080"
    restart: unless-stopped
```

Start it from the repository root:

```bash
docker compose up -d
```

Open `http://YOUR_SERVER_IP:8080`, or `http://localhost:8080` on the Docker host.

#### Useful Compose commands

```bash
# Follow application server logs
docker compose logs -f

# Download an updated image and recreate the container
docker compose pull
docker compose up -d

# Stop and remove the container
docker compose down
```

No `.env` file or server-side document volume is needed for the default configuration. Change the **left** side of `"8080:8080"` to customize the host port, e.g. `"8081:8080"`.

### Option 2 — Run directly with Docker

```bash
docker pull ghcr.io/mikapst/figcraft-web:latest

docker run -d \
  --name figcraft-web \
  --restart unless-stopped \
  -p 8080:8080 \
  ghcr.io/mikapst/figcraft-web:latest
```

The container serves HTTP on port `8080`. For external use, configure an HTTPS reverse proxy and suitable access controls.

### Network access and reverse proxies

The NGINX configuration:

- Serves `.wasm` as `application/wasm` and `.js` as `text/javascript`.
- Enables gzip compression for WebAssembly and JavaScript.
- Revalidates `index.html`, while allowing long-lived immutable caching of content-hashed static assets.
- Provides `GET /healthz` for Docker health checks.
- Sends `X-Content-Type-Options: nosniff`.
- Runs NGINX as the unprivileged `nginx` user.

FigCraft's upstream Trunk configuration uses `public_url = "./"` and content-hashed output. The generated site can work under a subpath, provided the reverse proxy correctly strips any configured prefix before forwarding.

**Live sessions:** a browser page served over HTTPS cannot normally connect to an insecure `ws://` endpoint on another host. Use a compatible `wss://` standalone server, or follow the official guidance for desktop-hosted sessions on a trusted network. The `figcraft-server` is a **separate service**, not part of this container.

### Embedding FigCraft in another website

The official web build supports iframe embedding:

```html
<iframe
  src="https://YOUR_DOMAIN/"
  title="FigCraft interface design tool"
  style="width:100%; height:720px; border:0;"
  allow="fullscreen; clipboard-read; clipboard-write"
  allowfullscreen>
</iframe>
```

Embedding requires appropriate browser and proxy policies. Sandboxed iframes need script, same-origin, and popup permissions. The upstream also documents **same-origin `?host=parent` integration** using `postMessage`, plus a same-document host mode. These modes allow a host page to exchange files and receive unsaved-change notifications; they are not automatically enabled by this Docker image.

See [official web hosting documentation](https://github.com/storytold/figcraft/blob/main/packaging/web/README.md) for host-mode events, collaboration, iframe restrictions, and browser compatibility.

## Repository structure

```text
figcraft-web/
├── .github/
│   └── workflows/
│       └── publish-image.yml
├── .dockerignore
├── Dockerfile
├── nginx.conf
├── docker-compose.yml
└── README.md
```

| File | Purpose |
|---|---|
| `Dockerfile` | Lightweight NGINX runtime image, unprivileged execution, health check. |
| `nginx.conf` | WebAssembly MIME types, compression, caching, security headers, health endpoint. |
| `.dockerignore` | Restricts the Docker context to compiled assets and required packaging files. |
| `docker-compose.yml` | Self-hosted deployment. |
| `.github/workflows/publish-image.yml` | Upstream release detection, Rust/Trunk compilation, GHCR publication, GitHub Release creation. |
| `README.md` | Architecture, deployment, maintenance, and attribution. |

### Docker build architecture

The official FigCraft WebAssembly application is compiled **once on the GitHub Actions runner**, not separately for each Docker CPU architecture.

```text
GitHub Actions workspace/
├── packaging/            # MikaPST/figcraft-web
│   ├── Dockerfile
│   ├── nginx.conf
│   └── .dockerignore
├── upstream/             # storytold/figcraft at selected release tag
├── craft-fonts/          # storytold/craft-fonts main branch
└── docker-context/       # generated, not committed
    ├── Dockerfile
    ├── nginx.conf
    ├── .dockerignore
    ├── site/             # upstream/dist/web
    └── legal/            # upstream and font license notices
```

The workflow:

1. Resolves the latest official upstream release or a manually requested `upstream_tag`.
2. Checks whether that release is already packaged, skipping it unless a rebuild is required.
3. Checks out the **exact official FigCraft release tag** and the independent `craft-fonts` `main` branch.
4. Records the FigCraft and fonts source commits.
5. Installs Rust, the `wasm32-unknown-unknown` target, and Trunk.
6. Runs `trunk build --release` from `upstream/apps/figcraft-web`, using `CRAFT_FONTS_DIR` and `CRAFT_FONTS_REQUIRED=1`.
7. Uses the upstream **`web-release` Rust profile** configured in `index.html`, optimized for WebAssembly size.
8. Validates the generated `upstream/dist/web` output, relative URLs, and `.wasm` file sizes.
9. Copies the generated static files, versioned Docker configuration, and available legal notices into `docker-context/`.
10. Builds and pushes the NGINX image for `linux/amd64` and `linux/arm64`.
11. Creates or updates the matching GitHub Release **after** GHCR publication succeeds.

**WASM size check:** the workflow applies the upstream web-packaging limit of **25 MiB per `.wasm` file (26,214,400 bytes)**. This is relevant to static hosting limits; Docker itself does not impose that same limit.

**Shared fonts:** FigCraft's build script requires Inter Regular, Inter SemiBold, and Noto Sans Georgian Regular for a required web build. Optional CJK and other script fonts can be embedded using upstream build variables, but are not enabled by this packaging workflow. The fonts checkout follows its own `main` branch, and its commit is recorded in GitHub Release notes.

The `upstream/`, `craft-fonts/`, and `docker-context/` folders are temporary workflow workspaces and are **not** committed to this packaging repository.

## Automated builds

| Trigger | Behaviour |
|---|---|
| Daily schedule (`03:17 UTC`) | Checks the latest official FigCraft release and skips it if already packaged. |
| Manual workflow dispatch | Builds the latest official release or a specified `upstream_tag`. |
| Force rebuild | Rebuilds an already published version using `force_rebuild: true`. |
| Packaging changes on `main` | Rebuilds the current upstream release when monitored packaging or documentation files change. |

### Published tags

Each successful GHCR publication includes:

- `latest` — most recently published image.
- `<upstream-version>` — official release tag.
- `upstream-<commit>` — first 12 characters of the upstream source commit.

The image supports `linux/amd64` and `linux/arm64`. The same compiled WebAssembly site is packaged for both architectures.

### GitHub Releases

After the GHCR push succeeds, the workflow creates or updates a matching [FigCraft Web GitHub Release](https://github.com/MikaPST/figcraft-web/releases).

Release notes include the official upstream release name, publication date and notes, source reference, the fonts commit, published Docker tags, supported architectures, and image manifest digest.

> [!IMPORTANT]
> GitHub Releases are created or updated **only after** a successful Docker image push. A forced rebuild may replace existing versioned image tags. For exact reproducibility, use the image digest.

## Unraid Community Applications

FigCraft Web is intended for the separately maintained [MikaPST/unraid-community-apps](https://github.com/MikaPST/unraid-community-apps) repository.

- **Template:** [figcraft-web.xml](https://github.com/MikaPST/unraid-community-apps/blob/main/templates/figcraft-web.xml)
- **Container image:** `ghcr.io/mikapst/figcraft-web:latest`
- **Container port:** `8080`

The Unraid XML template is maintained independently of this repository. Its host-port mapping may differ from the Docker Compose example.

## Upstream project

FigCraft is developed by the ArtCraft Team and contributors.

- **Source:** [storytold/figcraft](https://github.com/storytold/figcraft)
- **Official website:** [FigCraft](https://getartcraft.com/apps/figcraft)
- **Official releases:** [FigCraft releases](https://github.com/storytold/figcraft/releases)
- **Official web hosting guide:** [packaging/web/README.md](https://github.com/storytold/figcraft/blob/main/packaging/web/README.md)
- **Shared fonts:** [storytold/craft-fonts](https://github.com/storytold/craft-fonts)

This repository builds the official browser application from source but is **not an official FigCraft distribution**.

## License and attribution

The upstream FigCraft source is dual-licensed under **MIT OR Apache-2.0**. The workflow copies available upstream `LICENSE-MIT`, `LICENSE-APACHE`, `NOTICE`, `ATTRIBUTION.md`, and `ASSETS.md` files into the image's `/licenses/` directory, together with available third-party and shared-font license notices.

Upstream licenses do not automatically determine the license of the independent packaging files in this repository. Consult a separate packaging `LICENSE`, if one is present. FigCraft and ArtCraft names, artwork, and trademarks remain subject to their owners' rights.

## Disclaimer

FigCraft is early-alpha software. Features, browser compatibility, collaboration, and file workflows may change between releases. Test upgrades and keep independent copies of important projects.

This is independently maintained community packaging, not affiliated with or endorsed by the official project maintainers.
