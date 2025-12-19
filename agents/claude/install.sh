#!/usr/bin/env bash

################################################################################
# Claude Agent Installation Script
#
# Defines resource mappings from agents/shared to ~/.claude workspace
#
# Usage: Called by setup.sh
################################################################################

set -euo pipefail

# Agent-specific configuration
AGENT_NAME="claude"
AGENT_WORKSPACE=".claude"
AGENT_EXCLUSIVE_DIRS=("agents")  # Claude-specific subagents

# Shared resource mappings: "source:dest" pairs
# Format: each entry is "source_dir:dest_dir"
# Note: SDD workflow (commands/templates) in separate sdd/ directory
SHARED_MAPPINGS_PAIRS=(
    "commands:commands"
    "skills:skills"
)

# Export configuration for setup.sh
export AGENT_NAME AGENT_WORKSPACE
export AGENT_EXCLUSIVE_DIRS
export SHARED_MAPPINGS_PAIRS
