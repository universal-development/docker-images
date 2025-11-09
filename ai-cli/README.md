# AI CLI Tools Docker Image

Ubuntu 24.04 based image with AI CLI tools.

## Installed Tools

- @openai/codex
- @anthropic-ai/claude-code
- @github/copilot

## User

Runs as `user` with UID/GID 1000:1000

## Version Tag Generation

Generate version tag based on installed tool versions:

```bash
./generate-version-tag.sh
```

This will:
1. Build image locally
2. Extract versions of codex, claude-code, and copilot
3. Generate combined tag (e.g., `codex-1.0.0_claude-2.1.0_copilot-1.5.0`)
4. Update `config.sh` with generated tag

## Build

```bash
docker build -t ai-cli:latest .
```

Or use the build script:

```bash
./build.sh
```

## Usage

```bash
docker run -it --rm ai-cli:latest
```

Or with volume mount:

```bash
docker run -it --rm -v $(pwd):/home/user/workspace ai-cli:latest
```
