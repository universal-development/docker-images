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
2. Extract versions of claude-code, codex, and copilot
3. Generate combined tag (e.g., `claude-2.0.36_codex-0.56.0_copilot-0.0.354`)
   - Apps sorted alphabetically: claude, codex, copilot
4. Update `config.sh` with generated tag
5. Create git tag `ai-cli-<TAG>`
6. Display push command for publishing

Then push the tag:
```bash
git push origin ai-cli-<TAG>
```

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
