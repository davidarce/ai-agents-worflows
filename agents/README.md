# Agent Configuration Structure

This directory contains AI agent configurations using a **shared resources model** to eliminate duplication.

## Directory Structure

```
agents/
├── shared/              # Common resources used by all agents
│   ├── commands/        # Shared command definitions
│   │   ├── git/
│   │   ├── jira/
│   │   ├── spec/
│   │   └── frontend/
│   ├── skills/          # Shared skills (smart-commit, pr-creator, etc.)
│   └── templates/       # Shared templates (exploration, plan)
│
├── claude/              # Claude agent specific
│   ├── install.sh       # Installation config & resource mappings
│   └── agents/          # Exclusive: Claude subagents (backend, frontend)
│
└── factory/             # Factory agent specific
    ├── install.sh       # Installation config & resource mappings
    ├── droids/          # Exclusive: Factory droids
    └── commands/        # Exclusive: qa:unit-test.md
```

## How It Works

### 1. Shared Resources (`agents/shared/`)

All common resources (commands, skills, templates) are stored once in `agents/shared/`. This eliminates duplication and ensures consistency across agents.

**Contents:**
- **Commands**: Git operations, JIRA integration, spec-driven development, frontend workflows
- **Skills**: Smart commit, PR creator, skill creator
- **Templates**: Exploration and plan templates for spec workflow

### 2. Agent-Specific Configuration (`agents/{agent}/install.sh`)

Each agent has an `install.sh` script that defines:

- **Agent metadata**: Name, workspace directory
- **Exclusive resources**: Agent-only files (e.g., `agents/` for Claude, `droids/` for Factory)
- **Resource mappings**: How to map shared resources to installation paths
- **Special handling**: Command flattening, naming conventions

**Example** (`agents/claude/install.sh`):
```bash
AGENT_NAME="claude"
AGENT_WORKSPACE=".claude"
AGENT_EXCLUSIVE_DIRS=("agents")

SHARED_MAPPINGS_PAIRS=(
    "commands:commands"
    "skills:skills"
    "templates:templates"
)
```

**Example** (`agents/factory/install.sh`):
```bash
AGENT_NAME="factory"
AGENT_WORKSPACE=".factory"
AGENT_EXCLUSIVE_DIRS=("droids" "commands")

SHARED_MAPPINGS_PAIRS=(
    "commands/git:commands"
    "commands/jira:commands"
    "commands/spec:commands"
    "commands/frontend:commands"
    "skills:skills"
    "templates:templates"
)

FLATTEN_COMMANDS=true
COMMAND_SEPARATOR=":"
```

**Note**: Factory uses command flattening to convert `commands/git/commit.md` → `commands/git:commit.md`.

### 3. Agent-Exclusive Resources

Each agent can have resources that are **not shared**:

- **Claude**: `agents/` directory containing backend/frontend subagent definitions
- **Factory**: `droids/` directory containing specialist droids, plus `commands/qa:unit-test.md`

These resources are installed directly from the agent's directory without going through shared.

## Installation Process

The `setup.sh` script orchestrates installation:

1. **Load agent config**: Source `agents/{agent}/install.sh`
2. **Install exclusive resources**: Copy/symlink agent-specific dirs
3. **Install shared resources**: Apply mappings from `SHARED_MAPPINGS_PAIRS`
4. **Optional SDD workflow**: Install spec commands and templates

### Installation Modes

- **Copy**: Independent copies of files
- **Symlink**: Files stay synced with repository

### Workspaces

- **Global**: `~/.claude/` or `~/.factory/` (all projects)
- **Local**: `.claude/` or `.factory/` (current project only)

## Adding a New Agent

To add a new agent (e.g., `cursor`):

1. **Create agent directory**:
   ```bash
   mkdir -p agents/cursor
   ```

2. **Create `install.sh`**:
   ```bash
   cat > agents/cursor/install.sh << 'EOF'
   #!/usr/bin/env bash
   
   AGENT_NAME="cursor"
   AGENT_WORKSPACE=".cursor"
   AGENT_EXCLUSIVE_DIRS=("rules")  # If any
   
   SHARED_MAPPINGS_PAIRS=(
       "commands:commands"
       "skills:skills"
       "templates:templates"
   )
   
   export AGENT_NAME AGENT_WORKSPACE
   export AGENT_EXCLUSIVE_DIRS
   export SHARED_MAPPINGS_PAIRS
   EOF
   
   chmod +x agents/cursor/install.sh
   ```

3. **Add exclusive resources** (if needed):
   ```bash
   mkdir -p agents/cursor/rules
   # Add cursor-specific files
   ```

4. **Run setup**:
   ```bash
   ./setup.sh
   # Select: cursor
   ```

That's it! The agent will automatically use shared resources.

## Benefits

### ✅ No Duplication
- Single source of truth for commands, skills, templates
- Changes propagate to all agents automatically

### ✅ Easy Maintenance
- Update once in `agents/shared/`, affects all agents
- No risk of drift between agent configurations

### ✅ Extensibility
- Adding new agents is trivial (just create `install.sh`)
- Agent-specific customization via mappings

### ✅ Simplified Codebase
- `setup.sh` reduced from 1451 to 573 lines (60% smaller)
- Clear separation of concerns
- Bash 3.2 compatible (macOS)

## Migration from Legacy Structure

The previous structure had full duplication:
```
agents/claude/commands/    # Full copy
agents/factory/commands/   # Duplicate!
```

New structure eliminates this:
```
agents/shared/commands/    # Single source
agents/{agent}/install.sh  # Mappings only
```

All git history was preserved during migration using `git mv`.

## Spec-Driven Development (SDD) Workflow

The SDD workflow provides specialized commands for the spec-driven development process:

- **Commands**: `spec:explore`, `spec:plan`, `spec:implement`
- **Templates**: Exploration and plan templates

During setup, you can optionally install the SDD workflow. Spec commands are:
- Skipped during regular installation (to avoid clutter)
- Explicitly installed when SDD workflow is enabled
- Templates always go to project-local `.spec/templates/`

## Technical Notes

### Bash 3.2 Compatibility

macOS ships with Bash 3.2, which doesn't support associative arrays. The solution uses:

```bash
# Instead of: declare -A MAPPINGS=([key]="value")
# We use: array of "key:value" strings
SHARED_MAPPINGS_PAIRS=(
    "source:dest"
    "source2:dest2"
)

# Parse in setup.sh:
for mapping in "${SHARED_MAPPINGS_PAIRS[@]}"; do
    source="${mapping%%:*}"
    dest="${mapping##*:}"
done
```

### Command Flattening (Factory Only)

Factory uses a flat command structure with `:` separator:
- `git:commit.md` instead of `git/commit.md`
- `jira:tasks.md` instead of `jira/tasks.md`

This is handled automatically by `FLATTEN_COMMANDS=true` in Factory's `install.sh`.

## Troubleshooting

### "Install script not found"
Make sure `install.sh` exists and is executable:
```bash
chmod +x agents/{agent}/install.sh
```

### "Shared directory not found"
Run `setup.sh` from the repository root, not from subdirectories.

### "No agents found"
Ensure agent directories (excluding `shared/`) contain `install.sh` scripts.

## Version History

- **v2.0.0** (2025-12-03): Complete rewrite with shared resources model
- **v1.0.0**: Original implementation with duplicated structures
