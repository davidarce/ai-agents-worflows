# AI Agent Workflows

AI-powered development tools configuration, supporting multiple AI agents with shared resources and extensible architecture.

## 🎯 Overview

A unified configuration system for AI development assistants, featuring:

- **Multi-Agent Support** - Claude Code and Factory AI (extensible for future agents)
- **Shared Resources** - Commands, skills, and templates reused across agents
- **Agent-Specific Features** - Specialized subagents and droids per platform
- **Interactive Setup** - Zero-config installation with smart defaults
- **Flexible Deployment** - Global or project-local, copy or symlink

## 🚀 Quick Start

```bash
# Run interactive setup
./setup.sh

# Choose your agent (Claude or Factory)
# Select workspace location
# Pick installation method
# Done! 🎉
```

## 📁 Architecture

```
agents/
├── shared/                    # Common resources for all agents
│   ├── commands/              # Git, Jira, frontend, QA workflows
│   ├── sdd/                   # Spec-Driven Development
│   │   ├── commands/          # explore, plan, implement
│   │   └── templates/         # Structured development templates
│   └── skills/                # Reusable capabilities
│
├── claude/                    # Claude Code configuration
│   ├── install.sh             # Resource mappings
│   └── agents/                # Backend & frontend specialists
│
└── factory/                   # Factory AI configuration
    ├── install.sh             # Resource mappings & flattening
    └── droids/                # Specialized AI assistants
```

## 🤖 Supported Agents

### Claude Code

**Documentation**: https://code.claude.com/docs

Professional coding assistant with subagent architecture for specialized tasks.

**Features:**
- Custom slash commands with `:` separator (`/git:commit`, `/jira:tasks`)
- Specialized subagents (backend-architect, api-first-designer)
- Hierarchical command organization

**Workspace:** `~/.claude/` or `./.claude/`

### Factory AI

**Documentation**: https://docs.factory.ai/cli/getting-started/overview

Enterprise-grade development platform with droid-based automation.

**Features:**
- Flat command structure with `-` separator (`/git-commit`, `/jira-tasks`)
- Custom droids for architecture, API design, and QA
- Automated workflow integration

**Workspace:** `~/.factory/` or `./.factory/`

## 🛠️ Installation Options

### Workspace Location

| Location | Path | Scope |
|----------|------|-------|
| **Global** | `~/.claude/` or `~/.factory/` | Available in all projects |
| **Local** | `./.claude/` or `./.factory/` | Current project only |

**Recommendation:** Global for shared workflows, local for project-specific customization.

### Installation Method

| Method | Description | Updates |
|--------|-------------|---------|
| **Copy** | Independent file copies | Manual re-run to update |
| **Symlink** | Linked to repository | Automatic updates |

**Recommendation:** Symlinks for active development, copies for stable deployments.

## 📦 What's Included

### Common Commands

Available for both agents with platform-specific syntax:

#### Git Workflows
- Conventional commits with JIRA integration
- Automated PR creation and management

#### Jira Integration
- Task and user story management
- Sprint planning assistance

#### Quality Assurance
- Unit test generation and verification
- Code review workflows

#### Frontend Development
- Component planning and scaffolding
- Code review for React/TypeScript

### Shared Skills

Reusable capabilities invoked across agents:

- **smart-commit** - Conventional commits with automatic ticket detection
- **pr-creator** - Pull request generation with JIRA context
- **skill-creator** - Scaffold new skills with templates

### Agent-Specific Resources

#### Claude Subagents
- `backend-architect` - Clean architecture and DDD patterns
- `api-first-designer` - OpenAPI specification and REST design
- `qa-unit-test-verifier` - Test quality assurance

#### Factory Droids
- `backend-architect` - System design and architecture
- `api-first-designer` - API design and governance
- `qa-unit-test-verifier` - Unit test validation
- `qa-integration-test-specialist` - Integration test expertise

## 🎯 Spec-Driven Development (SDD)

Structured workflow for exploratory programming and implementation planning.

### Workflow

```bash
# Claude syntax
/spec:explore feature-name "Understand authentication flow"
/spec:plan feature-name
/spec:implement feature-name

# Factory syntax
/spec-explore feature-name "Understand authentication flow"
/spec-plan feature-name
/spec-implement feature-name
```

### Process

1. **Explore** - Discover codebase, gather context, identify patterns
2. **Plan** - Create detailed implementation strategy
3. **Implement** - Execute plan with confidence

### Output Structure

```
.spec/
├── templates/
│   ├── exploration_template.md
│   └── plan_template.md
└── [feature-name]/
    ├── exploration.md
    └── plan.md
```

## 📚 Usage Examples

### Multi-Project Setup

```bash
# Global Claude for all projects
cd ~/lib-purchaseai && ./setup.sh
# Select: claude → global → symlink

# Project-specific Factory
cd ~/my-project && /path/to/lib-purchaseai/setup.sh
# Select: factory → local → copy
```

### Hybrid Configuration

```bash
# Use both agents in the same project
cd ~/my-project

# Install Claude locally
./setup.sh  # claude → local

# Install Factory locally
./setup.sh  # factory → local
```

### Command Reference

| Task | Claude | Factory |
|------|--------|---------|
| Smart commit | `/git:commit` | `/git-commit` |
| Create PR | `/git:pull-request` | `/git-pull-request` |
| Jira tasks | `/jira:tasks` | `/jira-tasks` |
| Spec explore | `/spec:explore` | `/spec-explore` |
| Unit test | `/qa:unit-test` | `/qa-unit-test` |

## 🔧 Advanced Configuration

### Command-Line Options

```bash
./setup.sh --help          # Show all options
./setup.sh --dry-run       # Preview without changes
```

### Adding New Agents

To support additional AI platforms:

1. Create `agents/{agent-name}/install.sh`
2. Define mappings in `SHARED_MAPPINGS_PAIRS`
3. Add agent-exclusive resources
4. Test with `./setup.sh`

Example structure:

```bash
# agents/newagent/install.sh
AGENT_NAME="newagent"
AGENT_WORKSPACE=".newagent"
SHARED_MAPPINGS_PAIRS=(
    "commands:commands"
    "skills:skills"
)
```

The setup script auto-detects new agents—no core modifications needed!

### Updating Configurations

**Symlinked installations:** Automatic on `git pull`

**Copied installations:** Re-run `./setup.sh` and confirm overwrite

## 🤝 Contributors

### Core Team
- **David Arce** - [@davidarces](https://github.com/davidarces)
- **David Rodríguez Miranda** - [@davidrmi-ind](https://github.com/davidrmi-ind)
- **Lluis Pitarch**

### Infrastructure
- Automation and provisioning
- GitHub Watcher - Repository monitoring

## 🔍 Troubleshooting

### Setup Script Won't Execute
```bash
chmod +x ./setup.sh
```

### Commands Not Available After Install

**Claude:**
```bash
# Verify installation
ls -la ~/.claude/commands/
# or
ls -la ./.claude/commands/
```

**Factory:**
```bash
# Verify installation
ls -la ~/.factory/commands/
# or
ls -la ./.factory/commands/
```

### Symlinks Not Working

Ensure repository is in a stable location (not temporary directory).

## 📖 Documentation

- **Claude Code**: https://code.claude.com/docs
- **Factory AI**: https://docs.factory.ai/cli/getting-started/overview
- **Architecture Details**: `agents/README.md`

## 🎨 Design Principles

- **Zero Duplication** - Single source of truth for shared resources
- **Extensibility** - New agents require minimal configuration
- **Flexibility** - Support diverse deployment scenarios
- **Simplicity** - One command to rule them all

## 📝 License

Apache License 2.0

---

**Version:** 2.0.0
