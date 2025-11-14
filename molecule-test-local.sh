#!/bin/bash
# Helper script to run molecule tests locally
# This uses your host Docker daemon (Docker-in-Docker not needed)

set -e

# Activate virtual environment if it exists
if [ -d ".venv" ]; then
    source .venv/bin/activate
fi

# Set default distro if not set
export MOLECULE_DISTRO=${MOLECULE_DISTRO:-ubuntu2204}

# Fix for ansible-core 2.20.0+ strict conditional checking
export ANSIBLE_ALLOW_BROKEN_CONDITIONALS=True

# Color output
export PY_COLORS=1
export ANSIBLE_FORCE_COLOR=1

# Run molecule command (defaults to 'test' if no args provided)
if [ $# -eq 0 ]; then
    echo "Running: molecule test --scenario-name default"
    molecule test --scenario-name default
else
    echo "Running: molecule $@"
    molecule "$@"
fi

