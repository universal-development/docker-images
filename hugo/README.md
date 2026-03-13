# Hugo Builder Docker Image

Docker image with all required tools for building and deploying Hugo static websites.

## Installed Tools

| Tool | Version | Purpose |
|------|---------|---------|
| Ubuntu | 24.04 | Base OS |
| Hugo (extended) | 0.154.5 | Static site generator |
| Go | 1.25.5 | Hugo dependencies, Go modules |
| Node.js | LTS | Theme dependencies, npm packages |
| npm | Latest | Package manager |
| Pagefind | 1.4.0 | Full-text search indexing |
| Python 3 | Latest | Scripting, automation |
| pip | Latest | Python package manager |
| rclone | Latest | Cloud storage sync/deploy |
| restic | Latest | Backup tool |
| Git | Latest | Version control |
| curl, wget | Latest | File downloads |
| jq | Latest | JSON processing |
| vim, mc | Latest | File editing |

## Building the Image

```bash
docker build -t hugo-builder:latest .
```

## Usage Examples

### Interactive shell

```bash
docker run --rm -it \
  -v /path/to/your/hugo/site:/workspace \
  hugo-builder:latest
```

### Build Hugo site

```bash
docker run --rm \
  -v /path/to/your/hugo/site:/workspace \
  hugo-builder:latest \
  bash -c "hugo --minify"
```

### Run Hugo development server

```bash
docker run --rm -it \
  -v /path/to/your/hugo/site:/workspace \
  -p 1313:1313 \
  hugo-builder:latest \
  hugo server --bind 0.0.0.0
```

Then visit http://localhost:1313

### Build with Pagefind search

```bash
docker run --rm \
  -v /path/to/your/hugo/site:/workspace \
  hugo-builder:latest \
  bash -c "hugo && pagefind --site public"
```

### Install npm dependencies

```bash
docker run --rm \
  -v /path/to/your/hugo/site:/workspace \
  hugo-builder:latest \
  npm install
```

### Deploy with rclone

```bash
docker run --rm \
  -v /path/to/your/hugo/site:/workspace \
  -v ~/.rclone.conf:/root/.rclone.conf:ro \
  hugo-builder:latest \
  rclone sync public/ remote:bucket/path
```

### Backup with restic

```bash
docker run --rm \
  -v /path/to/your/hugo/site:/workspace \
  -e RESTIC_REPOSITORY=s3:bucket/path \
  -e RESTIC_PASSWORD=yourpassword \
  hugo-builder:latest \
  restic backup /workspace
```

## Features

* **All tools included**: No need to install additional dependencies
* **Persistent workspace**: Mount your Hugo site at `/workspace`
* **Sudo available**: Install additional packages as needed

## Verification

Check installed versions:

```bash
docker run --rm hugo-builder:latest bash -c '
  echo "Hugo: $(hugo version)"
  echo "Go: $(go version)"
  echo "Node: $(node --version)"
  echo "npm: $(npm --version)"
  echo "Python: $(python3 --version)"
  echo "Pagefind: $(pagefind --version)"
  echo "rclone: $(rclone version | head -1)"
  echo "restic: $(restic version)"
'
```
