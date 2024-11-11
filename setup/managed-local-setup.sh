#!/bin/bash

# Default values
backend_url="localhost"
frontend_url="localhost"
container_runtime="docker"

# Parse named parameters
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --backend-repo) backend_repo="$2"; shift ;;
        --frontend-repo) frontend_repo="$2"; shift ;;
        --backend-addons) IFS=',' read -r -a backend_addons <<< "$2"; shift ;;
        --frontend-addons) IFS=',' read -r -a frontend_addons <<< "$2"; shift ;;
        --backend-url) backend_url="$2"; shift ;;
        --frontend-url) frontend_url="$2"; shift ;;
        --runtime) container_runtime="$2"; shift ;;
        --backend-builder) backend_builder="$2"; shift ;;
        --frontend-builder) frontend_builder="$2"; shift ;;
        --backend-ref) backend_ref="$2"; shift ;;
        --backend-context-dir) backend_context_dir="$2"; shift ;;
        --frontend-ref) frontend_ref="$2"; shift ;;
        --frontend-context-dir) frontend_context_dir="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Verify required parameters
if [[ -z "$backend_repo" || -z "$frontend_repo" || -z "$backend_builder" || -z "$frontend_builder" ]]; then
    echo "Error: Required parameters are missing."
    echo "Usage: $0 --backend-repo <repo> --frontend-repo <repo> --backend-builder <image> --frontend-builder <image> [other options]"
    exit 1
fi

# Set up the S2I command, conditionally add -U parameter for podman
s2i_command="s2i build"
if [[ "$container_runtime" == "podman" ]]; then
    s2i_command+=" -U unix:///run/podman/podman.sock"
fi

# S2I build functions with optional --ref and --context-dir parameters
function s2i_build_backend() {
    echo "Starting S2I build for backend..."
    $s2i_command "$backend_repo" "$backend_builder" plone-backend-image \
        --env BACKEND_ADDONS="${backend_addons[@]}" \
        ${backend_ref:+--ref "$backend_ref"} \
        ${backend_context_dir:+--context-dir "$backend_context_dir"}
}

function s2i_build_frontend() {
    echo "Starting S2I build for frontend..."
    $s2i_command "$frontend_repo" "$frontend_builder" volto-frontend-image \
        --env FRONTEND_ADDONS="${frontend_addons[@]}" \
        ${frontend_ref:+--ref "$frontend_ref"} \
        ${frontend_context_dir:+--context-dir "$frontend_context_dir"}
}

# Run backend and frontend containers
function start_backend() {
    echo "Running backend container..."
    $container_runtime run -d --name plone-backend \
        -e RAZZLE_API_PATH="$backend_url" \
        plone-backend-image
}

function start_frontend() {
    echo "Running frontend container..."
    $container_runtime run -d --name volto-frontend \
        -e CLIENT_PUBLIC_PATH="$frontend_url" \
        volto-frontend-image
}

# Automate VS Code connection setup
function setup_vscode() {
    echo "Setting up VS Code connection to backend and frontend containers..."
    code --folder-uri=vscode-remote://$container_runtime/plone-backend .
    code --folder-uri=vscode-remote://$container_runtime/volto-frontend .
}

function install_addons() {
	echo "Installing Plone addons..."
	# for each addon do below
	cd ./frontend
	sed -i 's|const theme = '\'''\'';|const theme = "@kitconcept/volto-light-theme";|g' volto.config.js
	# end foreach
}

# Execute the steps
s2i_build_backend
s2i_build_frontend
start_backend
start_frontend
setup_vscode
