# Just recipes migrated from old Makefile
# Usage examples:
#   just container ubuntu-ssh-server
#   just push ubuntu-ssh-server
#   just update-workflow-options

set shell := ["/bin/bash", "-euo", "pipefail", "-c"]

DOCKER_REPO := "universaldevelopment"

# Build image directory and tag as :local (like Makefile 'container')
container image:
    IMAGE_TAG=$(image={{image}} ./.cicd/image-tag.sh) ; \
    echo "Image Tag: $IMAGE_TAG" ; \
    test -f {{image}}/Dockerfile || { echo "Dockerfile not found in {{image}}" >&2; exit 2; } ; \
    cd {{image}} && docker build . -t {{image}}:local

# Tag local image with computed tag & push (like Makefile 'push')
push image:
    IMAGE_TAG=$(image={{image}} ./.cicd/image-tag.sh) ; \
    echo "Image Tag: $IMAGE_TAG" ; \
    docker tag {{image}}:local {{DOCKER_REPO}}/{{image}}:$IMAGE_TAG ; \
    docker push {{DOCKER_REPO}}/{{image}}:$IMAGE_TAG

# Regenerate workflow_dispatch options list in GitHub workflow
update-workflow-options:
    wf=".github/workflows/docker-image.yml" ; \
    tmp=$(mktemp) ; \
    options_list=$(find . -maxdepth 1 -mindepth 1 -type d -printf '%P\n' \
        | grep -Ev '^(.git|.github|.cicd|.idea)$' \
        | while read d; do [ -f "$d/Dockerfile" ] && echo "  - $d"; done) ; \
    awk -v repl="$options_list" ' /# BEGIN IMAGE OPTIONS/ {print; print repl; skip=1; next} /# END IMAGE OPTIONS/ {skip=0} skip!=1 {print} ' "$wf" > "$tmp" ; \
    mv "$tmp" "$wf" ; \
    echo "Updated image options:" ; echo "$options_list" ; \
    test -n "$options_list" || { echo "WARNING: No options generated" >&2; }
