#!/usr/bin/env bash

################################################################################
# Factory Agent Installation Script
#
# Defines resource mappings from agents/shared to ~/.factory workspace
#
# Usage: Called by setup.sh
################################################################################

set -euo pipefail

# Agent-specific configuration
AGENT_NAME="factory"
AGENT_WORKSPACE=".factory"
AGENT_EXCLUSIVE_DIRS=("droids")  # Factory-specific resources

# Shared resource mappings: "source:dest" pairs
# For Factory, commands are flattened: commands/git -> commands (as git:*.md)
# Note: SDD workflow (commands/templates) in separate sdd/ directory
SHARED_MAPPINGS_PAIRS=(
    "commands/git:commands"
    "commands/jira:commands"
    "commands/frontend:commands"
    "commands/qa:commands"
    "skills:skills"
)

# Special naming convention for Factory commands: convert / to :
# Example: commands/git/commit.md -> commands/git:commit.md
FLATTEN_COMMANDS=true
COMMAND_SEPARATOR=":"

# Export configuration for setup.sh
export AGENT_NAME AGENT_WORKSPACE
export AGENT_EXCLUSIVE_DIRS
export SHARED_MAPPINGS_PAIRS
export FLATTEN_COMMANDS COMMAND_SEPARATOR
