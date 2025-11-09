#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="ai-cli-temp-version"

echo "Building temporary image to extract versions..."
docker build -t "${IMAGE_NAME}:temp" "${SCRIPT_DIR}" --no-cache

echo "Extracting tool versions..."

# Extract Claude Code version
CLAUDE_VERSION=$(docker run --rm "${IMAGE_NAME}:temp" bash -c "npm list -g @anthropic-ai/claude-code --depth=0 2>/dev/null | grep @anthropic-ai/claude-code | sed 's/.*@anthropic-ai\/claude-code@//' | sed 's/ .*//' || echo 'unknown'")
echo "  Claude: ${CLAUDE_VERSION}"

# Extract OpenAI Codex version
CODEX_VERSION=$(docker run --rm "${IMAGE_NAME}:temp" bash -c "npm list -g @openai/codex --depth=0 2>/dev/null | grep @openai/codex | sed 's/.*@openai\/codex@//' | sed 's/ .*//' || echo 'unknown'")
echo "  Codex: ${CODEX_VERSION}"

# Extract GitHub Copilot version
COPILOT_VERSION=$(docker run --rm "${IMAGE_NAME}:temp" bash -c "npm list -g @github/copilot --depth=0 2>/dev/null | grep @github/copilot | sed 's/.*@github\/copilot@//' | sed 's/ .*//' || echo 'unknown'")
echo "  Copilot: ${COPILOT_VERSION}"

# Clean up temporary image
docker rmi "${IMAGE_NAME}:temp" >/dev/null 2>&1 || true

# Generate combined tag (alphabetically sorted: claude, codex, copilot)
TAG="claude-${CLAUDE_VERSION}_codex-${CODEX_VERSION}_copilot-${COPILOT_VERSION}"

echo ""
echo "Generated tag: ${TAG}"

# Write to config.sh
cat > "${SCRIPT_DIR}/config.sh" <<EOF
#!/usr/bin/env bash

export TAG=${TAG}
EOF

echo "config.sh updated with TAG=${TAG}"

# Create git tag
GIT_TAG="ai-cli-${TAG}"
echo ""
echo "Creating git tag: ${GIT_TAG}"
git tag "${GIT_TAG}" 2>/dev/null && echo "Git tag created: ${GIT_TAG}" || echo "Git tag already exists: ${GIT_TAG}"

echo ""
echo "To push to remote, run:"
echo "  git push origin ${GIT_TAG}"
