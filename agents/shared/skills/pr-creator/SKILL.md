---
name: pr-creator
description: This skill should be used when creating pull requests by analyzing local git changes, suggesting appropriate PR templates, and generating comprehensive PR descriptions. Use for workflows involving git diff analysis, template selection, and PR creation with gh CLI. Integrates with JIRA to enrich PR descriptions with ticket context.
allowed-tools: Read, Grep, Glob, Bash(git:*), Bash(gh:*), mcp__jira-atlassian__jira_get_issue
---

# PR Creator

## Overview

This skill enables intelligent pull request creation by analyzing local git changes, fetching JIRA ticket context, suggesting the most appropriate PR template based on change type, and helping fill out comprehensive PR descriptions that accurately reflect the code modifications and business requirements.

**🚨 CRITICAL: ALL PRs MUST be created with `--draft` and `--label "ready-for-review"` flags. No exceptions. 🚨**

## Workflow

### Step 1: Understand Parameters

Extract parameters from the context or ask the user:
- `base_branch`: Branch to compare against (default: `develop`)
- `head_branch`: Branch with changes (default: current branch from `git rev-parse --abbrev-ref HEAD`)
- `working_directory`: Git repository path (default: current working directory)

### Step 2: Extract JIRA ID from Branch Name

Extract the JIRA ticket ID from the current git branch name to fetch ticket context.

**Branch naming convention:**
```
<type>/<JIRA-ID>-<description>
```

**Examples:**
- `feature/ICPRFPPREC-123-user-authentication` → `ICPRFPPREC-123`
- `bugfix/PROJ-456-fix-validation` → `PROJ-456`
- `refactor/APP-789-improve-performance` → `APP-789`

**Commands:**
```bash
# Get current branch name
git rev-parse --abbrev-ref HEAD

# Extract JIRA ID using regex pattern: [A-Z]+-[0-9]+
```

**Handle edge case:** If no JIRA ID is found in branch name, skip JIRA enrichment and proceed with git diff analysis only.

### Step 3: Fetch JIRA Ticket Information

Once the JIRA ID is extracted, fetch the ticket details to enrich the PR description.

**Use the JIRA MCP tool:**
```
mcp__jira-atlassian__jira_get_issue
```

**Parameters:**
- `issue_key`: The extracted JIRA ID (e.g., "ICPRFPPREC-4991")
- `fields`: "summary,description,issuetype,labels,assignee,status,priority,fixVersions,components"

**Extract relevant information:**
1. **Summary**: The ticket title - use for PR title
2. **Issue Type**: Bug, Story, Task, Epic - helps determine PR template
3. **Description**: Detailed context - use for "Motivation" or "Background" sections
4. **Labels**: Additional context for categorization
5. **Components**: Affected system components
6. **Acceptance Criteria**: Often in description - use for testing section

**Mapping JIRA Issue Type to PR Template:**
| JIRA Issue Type | PR Template | Rationale |
|-----------------|-------------|-----------|
| Bug, Defect | `bug.md` | Fixing issues |
| Story, User Story | `feature.md` | New functionality |
| Task | Based on git diff | Could be feature, refactor, or maintenance |
| Technical Debt | `refactor.md` | Code improvements |
| Epic | `feature.md` | Large features |
| Spike | `docs.md` or `refactor.md` | Research work |

**How to use JIRA context in PR:**
- **PR Title**: Use JIRA summary prefixed with ticket ID: `[JIRA-123] Summary from ticket`
- **Motivation/Background**: Extract from JIRA description
- **Acceptance Criteria**: Parse from JIRA description (often marked with headers)
- **Related Issues**: Link to JIRA ticket and any related tickets mentioned
- **Business Context**: Use JIRA description to explain "why" this change matters

**Example:**
```
JIRA ID: ICPRFPPREC-4991
Summary: "Migración BC Assortment"
Issue Type: Task
Description: "BC ASSORTMENT v1 todos los endpoints migrarlos a v2..."
Components: ["Infrastructure", "Integration"]

→ This suggests:
  - PR Title: "[ICPRFPPREC-4991] Migrate BC Assortment Planning integration to v2"
  - Template: feature.md (migration to new version)
  - Motivation: From JIRA description
  - Testing: Focus on endpoint compatibility
```

**Handle errors gracefully:**
- If JIRA API call fails, log a warning and continue without JIRA context
- Do NOT block PR creation if JIRA is unavailable
- Git diff analysis remains the primary source for technical details

### Step 4: Analyze File Changes

Use git commands to gather comprehensive change information:

```bash
# Get current branch
git rev-parse --abbrev-ref HEAD

# Get repository root
git rev-parse --show-toplevel

# Get changed files with status
git diff --name-status <base_branch>...<head_branch>

# Get diff statistics
git diff --stat <base_branch>...<head_branch>

# Get commit messages
git log --oneline <base_branch>..<head_branch>

# Get full diff
git diff <base_branch>...<head_branch>
```

Analyze the output to understand:
1. **Change scope**: Number of files changed, lines added/removed
2. **Change type**: Bug fix, feature, refactor, docs, test, performance, security
3. **Change impact**: Which modules/components are affected
4. **Breaking changes**: API changes, removed functionality

**Combine with JIRA context:**
- Git diff shows WHAT was changed technically
- JIRA ticket shows WHY and the business requirements
- Use BOTH to create a comprehensive PR description
- JIRA description may reveal context not obvious from code (e.g., regulatory requirements, customer requests)

### Step 5: Determine Change Type

Based on the diff analysis, classify the change into one of these types:

- **bug/fix**: Fixes defects, errors, or unexpected behavior
- **feature/enhancement**: Adds new functionality or capabilities
- **docs/documentation**: Documentation-only changes
- **refactor/cleanup**: Code restructuring without behavior changes
- **test/testing**: Test additions or corrections
- **performance/optimization**: Performance improvements
- **security**: Security fixes or hardening

**Type detection patterns:**
- Bug fixes: Keywords like "fix", "bug", "error", "issue" in commits/changes
- Features: New files, classes, or public APIs; keywords like "add", "implement"
- Refactor: Moved code, renamed classes/methods, structural changes
- Docs: Only markdown/documentation files changed
- Tests: Changes primarily in test directories
- Performance: Optimization-related changes, caching, query improvements
- Security: Authentication, authorization, encryption, vulnerability fixes

**Combine git diff analysis with JIRA issue type:**
- Start with JIRA issue type suggestion (from Step 3)
- Validate against actual code changes in git diff
- Final decision: Consider both sources
- Example: JIRA says "Task" + git shows v1→v2 API migration → use `feature` template

### Step 6: Select Template

Map the change type to the appropriate template from `assets/templates/`:

| Change Type | Template File | Description |
|-------------|--------------|-------------|
| bug, fix | `bug.md` | Bug fix template with issue description and fix details |
| feature, enhancement | `feature.md` | New feature template with motivation and implementation |
| docs, documentation | `docs.md` | Documentation change template |
| refactor, cleanup | `refactor.md` | Refactoring template with before/after context |
| test, testing | `test.md` | Test addition template with coverage details |
| performance, optimization | `performance.md` | Performance improvement template with metrics |
| security | `security.md` | Security fix template with vulnerability details |

Read the selected template from `assets/templates/<template-file>`.

### Step 7: Fill Out Template with JIRA Context

Based on the analyzed changes AND JIRA ticket information, help populate each section of the template:

**For bug.md:**
- **Issue Description**: Extract from JIRA description + git diff analysis
- **Root Cause**: Technical reason from code analysis
- **Fix Description**: Changes from git diff + JIRA acceptance criteria
- **Testing**: How the fix was verified + JIRA test requirements
- **Related Issues**: Link to JIRA ticket: `https://jira.example.com/browse/JIRA-ID`

**For feature.md:**
- **Description**: JIRA summary + technical details from git diff
- **Motivation**: Extract from JIRA description (business context, user needs)
- **Implementation**: High-level approach from git diff analysis
- **Acceptance Criteria**: Parse from JIRA description (look for bullet points, numbered lists)
- **Testing**: Test coverage details + JIRA test scenarios
- **Related Issues**: Link to JIRA ticket and any dependencies mentioned

**For refactor.md:**
- **Motivation**: JIRA description (technical debt context) + why refactoring needed
- **Changes Made**: What was restructured from git diff
- **Impact**: How behavior is preserved or improved
- **Related Issues**: Link to JIRA technical debt ticket

**For docs.md:**
- **Documentation Updates**: What was changed/added from git diff
- **Impact**: Who benefits (from JIRA context if available)
- **Related Issues**: Link to JIRA documentation task

**For test.md:**
- **Test Coverage**: What scenarios are now tested
- **Test Type**: Unit, integration, or end-to-end tests
- **Coverage Improvements**: Metrics if available
- **Related Issues**: Link to JIRA test task

**For performance.md:**
- **Performance Issue**: What was slow (from JIRA if mentioned)
- **Optimization**: Changes made from git diff
- **Metrics**: Before/after measurements if available
- **Related Issues**: Link to JIRA performance ticket

**For security.md:**
- **Vulnerability**: Security issue from JIRA + technical details
- **Fix**: How the vulnerability was mitigated
- **Impact**: Severity and affected versions from JIRA
- **Related Issues**: Link to JIRA security ticket

**Example PR description combining JIRA + git context:**
```markdown
# [ICPRFPPREC-4991] Migrate BC Assortment Planning integration to v2

## Description
Migrates the BC Assortment Planning service integration from v1 to v2 API endpoints. This update is required to support the new data model where color and campaign are now separate entities instead of being nested within categories.

## Motivation
The BC Assortment Planning team has deprecated v1 endpoints and requires all consumers to migrate to v2. The new version provides better separation of concerns and improved data modeling.

**JIRA Context**: BC ASSORTMENT v1 endpoints are being migrated to v2 across all services (REC and NEG). This is part of the larger initiative tracked in IOPCOMPRAS-5139.

## Implementation
- Updated rest client dependency to `bc-assortment-planning-rest` v2.0.0
- Refactored `PurchaseVariable` domain model to accommodate new API contract
- Updated repository adapters and mappers for v2 endpoints
- Extracted color and campaign handling as separate entities
- Updated configuration across all environments (pre, pre-int, pro)
- Updated tests to reflect new data model

## Acceptance Criteria
- [x] All v1 endpoints replaced with v2 equivalents
- [x] Contracts maintained (no breaking changes to our API)
- [x] Color and campaign extracted from categories
- [x] Configuration updated for all environments
- [x] All tests passing with new data model

## Testing
- Unit tests updated for new domain model
- Integration tests updated for v2 API contract
- All existing tests passing
- Manual testing in standalone environment

## Related Issues
- JIRA: [PROJ-4991](https://jira.example.com/browse/PROJ-4991)
- Initiative: [PROJ-5139](https://jira.example.com/browse/PROJ-5139)

## Files Changed
- 20 files modified
- 84 insertions, 172 deletions
```

### Step 8: Create Pull Request

**CRITICAL REQUIREMENTS (NON-NEGOTIABLE):**
1. **MUST use `--draft` flag** - Draft mode is required for team metrics and workflow
2. **MUST include `--label "ready-for-review"` flag** - This label triggers team notifications

**❌ NEVER create a PR without BOTH flags ❌**

Use `gh pr create` with the following MANDATORY command structure:

```bash
gh pr create \
  --base <base_branch> \
  --draft \
  --label "ready-for-review" \
  --title "<title>" \
  --body "<filled-template>"
```

**Validation checklist before running command:**
- [ ] `--draft` flag is present
- [ ] `--label "ready-for-review"` flag is present
- [ ] Title starts with `[JIRA-ID]`
- [ ] Body includes JIRA link in "Related Issues" section

**Important guidelines:**
- **Title format**: `[JIRA-ID] <Summary from JIRA or descriptive title>`
  - Example: `[ICPRFPPREC-4991] Migrate BC Assortment Planning integration to v2`
  - Use JIRA summary as the base, refined if needed for clarity
- Do NOT include Claude Code co-authorship
- Ensure body includes link to JIRA ticket in "Related Issues" section
- If JIRA has acceptance criteria, include them as checkboxes in PR description

**Why these flags are mandatory:**
- `--draft`: Prevents automatic CI/CD triggers and affects team metrics tracking
- `--label "ready-for-review"`: Triggers notifications to reviewers and updates team dashboards
- Missing either flag causes workflow disruptions and incorrect metrics

**PR creation with JIRA context:**
```bash
# Title from JIRA summary
PR_TITLE="[ICPRFPPREC-4991] Migración BC Assortment"

# Body includes JIRA context + git analysis
gh pr create \
  --base develop \
  --draft \
  --label "ready-for-review" \
  --title "$PR_TITLE" \
  --body "$FILLED_TEMPLATE_WITH_JIRA_CONTEXT"
```

### Step 9: Handle Special Cases

**Multiple change types:**
- If changes span multiple types, choose the dominant type
- List other changes as "Additional changes" in PR description

**Breaking changes:**
- Add `BREAKING CHANGE:` section to description
- Clearly document what breaks and migration path

**Follow-up items:**
- If issues are discovered that need separate PRs, list them as action items
- Use checkboxes for clarity: `- [ ] Follow-up: Add unit tests for edge cases`

## Template Assets

Available templates in `assets/templates/`:
- `bug.md`: Bug fix template
- `feature.md`: New feature template
- `docs.md`: Documentation template
- `refactor.md`: Refactoring template
- `test.md`: Test addition template
- `performance.md`: Performance optimization template
- `security.md`: Security fix template

## Project-Specific Conventions

**Standard conventions:**
- Always prefix PR titles with JIRA ticket ID: `[PROJ-123] Description`
- Use JIRA summary as the base for PR title
- Base branch is typically `develop`
- Follow Conventional Commits in individual commits: `type(scope): description`
- Include relevant labels based on change type
- **Always link to JIRA ticket** in "Related Issues" section:
  - Format: `https://jira.example.com/browse/JIRA-ID`
- Extract acceptance criteria from JIRA description (look for sections marked with "Acceptance Criteria", "AC:", "*Acceptance Criteria*")
- Include JIRA business context in "Motivation" section
- Reference any related JIRA tickets mentioned in the description

**GitHub Flow:**
- Create feature branches from main/develop
- Use descriptive branch names: `feature/add-user-auth`, `fix/login-timeout`
- Keep PRs focused and reasonably sized
- Reference related issues in PR description

## Error Handling

**If git commands fail:**
- Verify working directory is a git repository
- Check that base and head branches exist
- Ensure user has proper git configuration

**If gh CLI is not available:**
- Provide instructions to install: `brew install gh` (macOS) or download from GitHub
- Suggest manual PR creation with the filled template

**If analysis is ambiguous:**
- Ask user to clarify the change type
- Provide reasoning for suggested template
- Offer to show multiple template options

**If JIRA integration fails:**
- Log a warning but continue with PR creation
- Use git diff analysis and commit messages as fallback
- Suggest manual addition of JIRA context if needed

## Notes

### Critical PR Creation Rules
- **🚨 MANDATORY FLAGS 🚨**: ALWAYS use both `--draft` and `--label "ready-for-review"` flags
- **NO EXCEPTIONS**: These flags are required for ALL PRs regardless of size, type, or urgency
- **Company policy**: Missing these flags violates team workflow and metrics tracking
- **Validation**: Before executing `gh pr create`, verify both flags are present in the command

### JIRA Integration
- **JIRA integration is optional**: If JIRA API is unavailable or fails, the skill continues with git diff analysis only
- **Git diff is the source of truth for technical details**: JIRA provides business context and requirements
- **Acceptance Criteria parsing**: Look for common markers in JIRA description:
  - "*Acceptance Criteria*" (formatted text)
  - "AC:" or "Acceptance Criteria:"
  - Bullet points or numbered lists following these markers
- **Related tickets**: Check JIRA description for links to other tickets (initiatives, dependencies, blockers)
- The JIRA MCP tool (`mcp__jira-atlassian__jira_get_issue`) requires proper authentication and network access to Jira instance
- **PR Title**: Prefer JIRA summary but refine if needed for clarity (e.g., translate to English if JIRA is in Spanish)
- **Always include JIRA link**: Even if JIRA API fails, construct the link from the extracted JIRA ID

### Command Template (Always Use This)
```bash
gh pr create \
  --base develop \
  --draft \
  --label "ready-for-review" \
  --title "[JIRA-ID] Description" \
  --body "$(cat <<'EOF'
<PR description here>
EOF
)"
```