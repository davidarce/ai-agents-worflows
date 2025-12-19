#!/usr/bin/env bash

################################################################################
# Agent Configuration Setup Script v1.0
#
# Simplified setup using shared resources (agents/shared/) and per-agent
# install scripts that define resource mappings.
#
# Usage:
#   ./setup.sh                 # Interactive mode
#   ./setup.sh --help          # Show help
#
# Author: David Arce
# Version: 1.0.0
################################################################################

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

readonly SCRIPT_VERSION="2.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly AGENTS_DIR="${SCRIPT_DIR}/agents"
readonly SHARED_DIR="${AGENTS_DIR}/shared"

# Available agents (auto-detect from agents/ directory)
declare -a AVAILABLE_AGENTS=()
for agent_dir in "${AGENTS_DIR}"/*; do
    if [[ -d "${agent_dir}" ]] && [[ "$(basename "${agent_dir}")" != "shared" ]]; then
        AVAILABLE_AGENTS+=("$(basename "${agent_dir}")")
    fi
done

# Agent configuration loaded from install.sh
AGENT_NAME=""
AGENT_WORKSPACE=""
declare -a AGENT_EXCLUSIVE_DIRS=()
declare -a SHARED_MAPPINGS_PAIRS=()
FLATTEN_COMMANDS=false
COMMAND_SEPARATOR=":"

# Default workspace paths
readonly DEFAULT_CLAUDE_PATH="${HOME}/.claude"
readonly DEFAULT_FACTORY_PATH="${HOME}/.factory"

# Statistics
STATS_FILES_COPIED=0
STATS_DIRS_CREATED=0
STATS_SYMLINKS_CREATED=0

# ============================================================================
# COLORS
# ============================================================================

if [[ -t 1 ]] && command -v tput &>/dev/null; then
    readonly C_RESET="$(tput sgr0)"
    readonly C_BOLD="$(tput bold)"
    readonly C_RED="$(tput setaf 1)"
    readonly C_GREEN="$(tput setaf 2)"
    readonly C_YELLOW="$(tput setaf 3)"
    readonly C_BLUE="$(tput setaf 4)"
    readonly C_CYAN="$(tput setaf 6)"
else
    readonly C_RESET="" C_BOLD="" C_RED="" C_GREEN="" C_YELLOW="" C_BLUE="" C_CYAN=""
fi

# Icons
readonly I_OK="✅" I_ERR="❌" I_WARN="⚠️" I_INFO="ℹ️" I_ASK="❓" I_ROCKET="🚀"

# ============================================================================
# LOGGING
# ============================================================================

log_info()    { echo -e "${C_BLUE}${I_INFO}${C_RESET} $*"; }
log_success() { echo -e "${C_GREEN}${I_OK}${C_RESET} $*"; }
log_warn()    { echo -e "${C_YELLOW}${I_WARN}${C_RESET} $*"; }
log_error()   { echo -e "${C_RED}${I_ERR}${C_RESET} $*" >&2; }
log_step()    { echo ""; echo -e "${C_BOLD}${C_CYAN}▶ $*${C_RESET}"; echo ""; }

print_header() {
    echo ""
    echo -e "${C_BOLD}${C_CYAN}╔═══════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_BOLD}${C_CYAN}║     ${I_ROCKET} Agent Configuration Setup v${SCRIPT_VERSION} ${I_ROCKET}     ║${C_RESET}"
    echo -e "${C_BOLD}${C_CYAN}╚═══════════════════════════════════════════════════════╝${C_RESET}"
    echo ""
}

# ============================================================================
# USER INTERACTION
# ============================================================================

prompt_yes_no() {
    local prompt="$1"
    local default="${2:-n}"

    local suffix="[y/N]"
    [[ "${default}" == "y" ]] && suffix="[Y/n]"

    while true; do
        read -r -p "$(echo -e "${C_CYAN}${I_ASK} ${prompt} ${suffix}: ${C_RESET}")" response
        response=$(echo "${response}" | tr '[:upper:]' '[:lower:]')
        [[ -z "${response}" ]] && response="${default}"

        case "${response}" in
            y|yes) return 0 ;;
            n|no) return 1 ;;
            *) log_warn "Please answer 'yes' or 'no'" ;;
        esac
    done
}

prompt_choice() {
    local prompt="$1"
    shift
    local options=("$@")

    echo "" >&2
    echo -e "${C_CYAN}${I_ASK} ${prompt}${C_RESET}" >&2
    echo "" >&2

    for i in "${!options[@]}"; do
        echo -e "  ${C_BOLD}$((i + 1)))${C_RESET} ${options[i]}" >&2
    done
    echo "" >&2

    while true; do
        read -r -p "$(echo -e "${C_CYAN}Choice [1-${#options[@]}]: ${C_RESET}")" choice
        if [[ "${choice}" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= ${#options[@]})); then
            echo "$((choice - 1))"
            return 0
        fi
        log_warn "Invalid choice" >&2
    done
}

# ============================================================================
# AGENT CONFIGURATION
# ============================================================================

load_agent_config() {
    local agent="$1"
    local install_script="${AGENTS_DIR}/${agent}/install.sh"

    if [[ ! -f "${install_script}" ]]; then
        log_error "Install script not found: ${install_script}"
        return 1
    fi

    # Source agent configuration
    # shellcheck source=/dev/null
    source "${install_script}"

    # Validate exports
    if [[ -z "${AGENT_NAME:-}" ]] || [[ -z "${AGENT_WORKSPACE:-}" ]]; then
        log_error "Install script must export AGENT_NAME and AGENT_WORKSPACE"
        return 1
    fi

    log_info "Loaded configuration for agent: ${AGENT_NAME}"
    return 0
}

# ============================================================================
# FILE OPERATIONS
# ============================================================================

ensure_dir() {
    local dir="$1"
    [[ -d "${dir}" ]] && return 0

    mkdir -p "${dir}" || {
        log_error "Failed to create directory: ${dir}"
        return 1
    }
    ((STATS_DIRS_CREATED++))
    return 0
}

copy_files_recursive() {
    local src="$1"
    local dest="$2"
    local pattern="${3:-*}"

    ensure_dir "${dest}" || return 1

    local count=0
    while IFS= read -r -d '' file; do
        local rel_path="${file#${src}/}"
        local dest_file="${dest}/${rel_path}"
        local dest_dir
        dest_dir="$(dirname "${dest_file}")"

        ensure_dir "${dest_dir}" || return 1

        if cp "${file}" "${dest_file}"; then
            ((count++))
            ((STATS_FILES_COPIED++))
        else
            log_error "Failed to copy: ${rel_path}"
            return 1
        fi
    done < <(find "${src}" -type f -name "${pattern}" -print0)

    [[ ${count} -gt 0 ]] && log_success "Copied ${count} file(s)"
    return 0
}

create_symlink() {
    local src="$1"
    local dest="$2"

    # Remove existing
    [[ -e "${dest}" ]] || [[ -L "${dest}" ]] && rm -rf "${dest}"

    if ln -s "${src}" "${dest}"; then
        ((STATS_SYMLINKS_CREATED++))
        log_success "Symlink: $(basename "${dest}") → ${src}"
        return 0
    fi

    log_error "Failed to create symlink: ${dest}"
    return 1
}

# ============================================================================
# AGENT INSTALLATION
# ============================================================================

install_agent() {
    local agent="$1"
    local workspace="$2"
    local use_symlinks="$3"

    log_step "Installing ${agent} agent to ${workspace}"

    ensure_dir "${workspace}" || return 1

    # Install exclusive agent resources (agents/, droids/, etc.)
    for exclusive_dir in "${AGENT_EXCLUSIVE_DIRS[@]}"; do
        local src="${AGENTS_DIR}/${agent}/${exclusive_dir}"
        local dest="${workspace}/${exclusive_dir}"

        [[ ! -d "${src}" ]] && continue

        echo ""
        log_info "Installing exclusive: ${exclusive_dir}/"

        if [[ "${use_symlinks}" == "true" ]]; then
            create_symlink "${src}" "${dest}" || return 1
        else
            copy_files_recursive "${src}" "${dest}" "*.md" || return 1
        fi
    done

    # Install shared resources with mappings
    for mapping in "${SHARED_MAPPINGS_PAIRS[@]}"; do
        # Parse "source:dest" pair
        local source_key="${mapping%%:*}"
        local dest_key="${mapping##*:}"
        local src="${SHARED_DIR}/${source_key}"
        local dest="${workspace}/${dest_key}"

        [[ ! -d "${src}" ]] && continue

        echo ""
        log_info "Installing shared: ${source_key}/ → ${dest_key}/"

        if [[ "${use_symlinks}" == "true" ]]; then
            # For symlinks, just link the directory
            create_symlink "${src}" "${dest}" || return 1
        else
            # Handle command flattening for Factory
            if [[ "${FLATTEN_COMMANDS}" == "true" ]] && [[ "${source_key}" =~ ^commands/ ]]; then
                local category
                category="$(basename "${source_key}")"

                ensure_dir "${dest}" || return 1

                local count=0
                while IFS= read -r -d '' file; do
                    local filename
                    filename="$(basename "${file}")"

                    # Flatten: commands/git/commit.md → commands/git:commit.md
                    local dest_filename="${category}${COMMAND_SEPARATOR}${filename}"
                    local dest_file="${dest}/${dest_filename}"

                    if cp "${file}" "${dest_file}"; then
                        ((count++))
                        ((STATS_FILES_COPIED++))
                    else
                        log_error "Failed to copy: ${dest_filename}"
                        return 1
                    fi
                done < <(find "${src}" -maxdepth 1 -type f -name "*.md" -print0)

                [[ ${count} -gt 0 ]] && log_success "Copied ${count} file(s) (flattened)"
            else
                # Regular copy
                copy_files_recursive "${src}" "${dest}" "*" || return 1
            fi
        fi
    done

    return 0
}

# ============================================================================
# SDD WORKFLOW (OPTIONAL)
# ============================================================================

install_sdd_workflow() {
    local agent="$1"
    local workspace="$2"

    local sdd_dir="${SHARED_DIR}/sdd"
    local sdd_commands="${sdd_dir}/commands"
    local sdd_templates="${sdd_dir}/templates"

    [[ ! -d "${sdd_commands}" ]] && [[ ! -d "${sdd_templates}" ]] && return 0

    echo ""
    log_info "Spec-Driven Development (SDD) workflow is available"

    prompt_yes_no "Install SDD workflow?" "y" || {
        log_info "Skipping SDD workflow"
        return 0
    }

    log_step "Installing SDD Workflow"

    # Install spec commands
    if [[ -d "${sdd_commands}" ]]; then
        local dest_commands="${workspace}/commands"

        # Check if commands is already a symlink
        if [[ -L "${dest_commands}" ]]; then
            log_success "Commands already symlinked (spec commands included)"
        else
            ensure_dir "${dest_commands}" || return 1

            if [[ "${agent}" == "factory" ]]; then
                # Factory: flatten spec commands
                local count=0
                while IFS= read -r -d '' file; do
                    local filename
                    filename="$(basename "${file}")"
                    local dest_file="${dest_commands}/spec${COMMAND_SEPARATOR}${filename}"

                    if cp "${file}" "${dest_file}"; then
                        ((count++))
                        ((STATS_FILES_COPIED++))
                    fi
                done < <(find "${sdd_commands}" -maxdepth 1 -type f -name "*.md" -print0)

                [[ ${count} -gt 0 ]] && log_success "Installed ${count} spec command(s)"
            else
                # Claude: maintain spec/ subdirectory
                copy_files_recursive "${sdd_commands}" "${dest_commands}/spec" "*.md" || return 1
            fi
        fi
    fi

    # Install spec templates (always to project .spec/)
    if [[ -d "${sdd_templates}" ]]; then
        local dest_templates="$(pwd)/.spec/templates"
        copy_files_recursive "${sdd_templates}" "${dest_templates}" "*" || return 1

        # Add .spec/ to .gitignore if needed
        if [[ -f "$(pwd)/.gitignore" ]]; then
            if ! grep -q "^\.spec/$" "$(pwd)/.gitignore" 2>/dev/null; then
                if prompt_yes_no "Add .spec/ to .gitignore?" "y"; then
                    echo ".spec/" >> "$(pwd)/.gitignore"
                    log_success "Added .spec/ to .gitignore"
                fi
            fi
        fi
    fi

    return 0
}

# ============================================================================
# MAIN WORKFLOW
# ============================================================================

main() {
    print_header

    # Validate environment
    if [[ ! -d "${SHARED_DIR}" ]]; then
        log_error "Shared directory not found: ${SHARED_DIR}"
        log_error "Run this script from the repository root"
        exit 1
    fi

    if [[ ${#AVAILABLE_AGENTS[@]} -eq 0 ]]; then
        log_error "No agents found in ${AGENTS_DIR}"
        exit 1
    fi

    # Step 1: Select agent
    log_step "Step 1: Select Agent"

    local agent_choice
    if [[ ${#AVAILABLE_AGENTS[@]} -eq 1 ]]; then
        agent_choice=0
        log_info "Agent: ${C_BOLD}${AVAILABLE_AGENTS[0]}${C_RESET} (only option)"
    else
        agent_choice=$(prompt_choice "Select agent:" "${AVAILABLE_AGENTS[@]}")
    fi

    local agent="${AVAILABLE_AGENTS[${agent_choice}]}"
    echo ""
    log_success "Selected: ${C_BOLD}${agent}${C_RESET}"

    # Load agent configuration
    load_agent_config "${agent}" || exit 1

    # Step 2: Select workspace
    log_step "Step 2: Select Workspace"

    local default_workspace=""
    case "${agent}" in
        claude) default_workspace="${DEFAULT_CLAUDE_PATH}" ;;
        factory) default_workspace="${DEFAULT_FACTORY_PATH}" ;;
        *) default_workspace="${HOME}/${AGENT_WORKSPACE}" ;;
    esac

    local workspace_choice
    workspace_choice=$(prompt_choice "Where to install?" \
        "Global (${default_workspace}) - All projects" \
        "Local ($(pwd)/${AGENT_WORKSPACE}) - This project only")

    local workspace
    if ((workspace_choice == 0)); then
        workspace="${default_workspace}"
    else
        workspace="$(pwd)/${AGENT_WORKSPACE}"
    fi

    echo ""
    log_success "Workspace: ${C_BOLD}${workspace}${C_RESET}"

    # Step 3: Installation method
    log_step "Step 3: Installation Method"

    local method_choice
    method_choice=$(prompt_choice "How to install?" \
        "Copy files - Independent copies" \
        "Symlinks - Stay in sync with repository")

    local use_symlinks="false"
    ((method_choice == 1)) && use_symlinks="true"

    echo ""
    if [[ "${use_symlinks}" == "true" ]]; then
        log_success "Method: ${C_BOLD}Symlinks${C_RESET} (synced)"
    else
        log_success "Method: ${C_BOLD}Copy${C_RESET} (independent)"
    fi

    # Step 4: Confirm
    log_step "Ready to Install"

    echo ""
    log_info "Summary:"
    echo -e "  Agent:     ${C_CYAN}${agent}${C_RESET}"
    echo -e "  Workspace: ${C_CYAN}${workspace}${C_RESET}"
    echo -e "  Method:    ${C_CYAN}$([ "${use_symlinks}" == "true" ] && echo "Symlinks" || echo "Copy")${C_RESET}"
    echo ""

    prompt_yes_no "Proceed with installation?" "y" || {
        log_warn "Installation cancelled"
        exit 0
    }

    # Step 5: Install
    log_step "Installing..."

    if install_agent "${agent}" "${workspace}" "${use_symlinks}"; then
        # Optional: SDD workflow
        install_sdd_workflow "${agent}" "${workspace}"

        # Summary
        echo ""
        echo ""
        echo -e "${C_BOLD}${C_GREEN}╔════════════════════════════════════════════════╗${C_RESET}"
        echo -e "${C_BOLD}${C_GREEN}║   ${I_OK}  Installation Completed Successfully!   ║${C_RESET}"
        echo -e "${C_BOLD}${C_GREEN}╚════════════════════════════════════════════════╝${C_RESET}"
        echo ""
        echo -e "${C_BOLD}Statistics:${C_RESET}"
        echo -e "  Files copied:    ${C_GREEN}${STATS_FILES_COPIED}${C_RESET}"
        echo -e "  Directories:     ${C_GREEN}${STATS_DIRS_CREATED}${C_RESET}"
        echo -e "  Symlinks:        ${C_GREEN}${STATS_SYMLINKS_CREATED}${C_RESET}"
        echo ""
        echo -e "${C_BOLD}Location:${C_RESET} ${C_CYAN}${workspace}${C_RESET}"
        echo ""
        log_success "Your agent configuration is ready!"
        echo ""
        exit 0
    else
        log_error "Installation failed"
        exit 1
    fi
}

# ============================================================================
# HELP
# ============================================================================

if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    cat << EOF
${C_BOLD}Agent Configuration Setup v${SCRIPT_VERSION}${C_RESET}

${C_BOLD}USAGE:${C_RESET}
    ./setup.sh              Interactive installation
    ./setup.sh --help       Show this help

${C_BOLD}DESCRIPTION:${C_RESET}
    Configures AI agents (Claude, Factory) using shared resources from
    agents/shared/ with agent-specific customizations defined in each
    agent's install.sh script.

${C_BOLD}FEATURES:${C_RESET}
    - Shared resource management (commands, skills, templates)
    - Per-agent customization via install.sh scripts
    - Copy or symlink installation modes
    - Automatic SDD workflow integration
    - Simplified codebase (500 lines vs 1400+)

${C_BOLD}DIRECTORY STRUCTURE:${C_RESET}
    agents/
      ├── shared/          # Common resources
      │   ├── commands/    # Regular commands (git, jira, qa, frontend)
      │   ├── sdd/         # Spec-Driven Development workflow
      │   │   ├── commands/
      │   │   └── templates/
      │   └── skills/
      ├── claude/
      │   ├── install.sh   # Claude-specific config
      │   └── agents/      # Exclusive: Claude subagents
      └── factory/
          ├── install.sh   # Factory-specific config
          └── droids/      # Exclusive: Factory droids

${C_BOLD}EXAMPLES:${C_RESET}
    # Install Claude agent globally
    ./setup.sh
    > Select: claude
    > Workspace: Global
    > Method: Copy

    # Install Factory agent locally with symlinks
    ./setup.sh
    > Select: factory
    > Workspace: Local
    > Method: Symlinks

${C_BOLD}VERSION:${C_RESET}
    ${SCRIPT_VERSION}

EOF
    exit 0
fi

# Run main
main "$@"
