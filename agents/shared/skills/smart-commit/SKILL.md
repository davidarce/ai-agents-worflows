---
name: smart-commit
description: This skill should be used when creating git commits that follow Conventional Commits specification with JIRA ticket integration. Use this skill when the user requests to create a commit, commit changes, or make a smart commit for the current work. The skill analyzes local file changes, determines the appropriate commit type and scope, detects breaking changes, and creates a properly formatted commit message with the JIRA ticket ID prefix. It also fetches JIRA ticket information to enrich the commit message.
allowed-tools: Read, Grep, Glob, Bash(git add:*), Bash(git status:*), Bash(git diff:*), Bash(git branch:*), Bash(git log:*), Bash(git commit:*), Bash(git rev-parse:*), mcp__jira-atlassian__jira_get_issue
---

# Smart Commit

## Overview

This skill automates the creation of git commits following the Conventional Commits specification with JIRA ticket integration. Analyze local changes, determine commit type and scope, detect breaking changes, and create properly formatted commits automatically.

## Commit Format

All commits must follow this format:

```
[JIRA-ID] <type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

**Breaking changes** use this format:
```
[JIRA-ID] <type>(<scope>)!: <description>
```

## Workflow

### Step 1: Extract JIRA ID from Branch Name

Extract the JIRA ticket ID from the current git branch name.

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

**Extraction pattern:**
- Find the first occurrence of uppercase letters followed by hyphen and numbers
- Pattern: `[A-Z]+[A-Z]+-[0-9]+`

**Handle edge case:** If no JIRA ID is found in branch name, skip the JIRA ID prefix in the commit message and proceed without JIRA context.

### Step 2: Fetch JIRA Ticket Information

Once the JIRA ID is extracted, fetch the ticket details to enrich the commit message with context.

**Use the JIRA MCP tool:**
```
mcp__jira-atlassian__jira_get_issue
```

**Parameters:**
- `issue_key`: The extracted JIRA ID (e.g., "ICPRFPPREC-4991")
- `fields`: "summary,description,issuetype,labels"

**Extract relevant information:**
1. **Summary**: The ticket title/summary - use this to understand the high-level goal
2. **Issue Type**: Bug, Story, Task, Epic, etc. - helps determine commit type
3. **Description**: Detailed context about what needs to be done
4. **Labels**: Additional context about the feature area

**Mapping JIRA Issue Type to Commit Type:**
| JIRA Issue Type | Suggested Commit Type | Notes |
|-----------------|----------------------|-------|
| Bug, Defect | `fix` | Bug fixes |
| Story, User Story | `feat` | New features |
| Task | `feat` or `refactor` | Depends on the nature of work |
| Technical Debt | `refactor` | Code improvements |
| Epic | `feat` | Large features (usually) |
| Spike | `docs` or `refactor` | Research work |

**How to use JIRA context:**
- Use the **summary** as guidance for the commit description
- Check **issue type** to help determine the correct commit type
- Review **description** to understand if it's breaking, adds features, or fixes bugs
- Consider **labels** for determining scope (e.g., "backend", "api", "domain")

**Example:**
```
JIRA ID: ICPRFPPREC-4991
Summary: "Migrate BC Assortment Planning integration to v2"
Issue Type: Task
Description: "Update integration with bc-assortment-planning service to use new v2 API..."

→ This suggests:
  - Type: `feat` (new integration version)
  - Scope: `infrastructure` (external service integration)
  - Description should mention "migrate" and "v2"
```

**Handle errors gracefully:**
- If JIRA API call fails (network, permissions, invalid ticket), log a warning and continue without JIRA context
- Do NOT block the commit if JIRA is unavailable
- The git diff analysis should still be the primary source of truth

### Step 3: Analyze Local Changes

Analyze the current git diff to understand what has changed.

**Commands:**
```bash
# Get list of changed files with status
git diff --name-status

# Get detailed diff
git diff

# Get diff statistics
git diff --stat
```

**Analyze the diff output to identify:**
1. **Files changed**: Which files were modified, added, or deleted
2. **Change magnitude**: How many lines added/removed
3. **Change location**: Which modules/packages affected (domain, application, infrastructure, api-rest, etc.)
4. **Change nature**: What kind of changes (new features, bug fixes, refactoring, etc.)

**Combine with JIRA context:**
- The git diff shows WHAT was actually changed in code
- The JIRA ticket shows WHY and the intended outcome
- Use BOTH sources to create an accurate commit message
- If there's a mismatch (e.g., JIRA says "bug" but code shows new features), trust the git diff but consider mentioning the JIRA context

### Step 4: Determine Commit Type

Based on the analyzed changes, determine the commit type using these patterns:

| Type | When to Use | Keywords in Changes |
|------|------------|---------------------|
| `feat` | New functionality or feature | "add", "implement", "introduce", "create" |
| `fix` | Bug fix or error correction | "fix", "resolve", "correct", "repair", "patch" |
| `refactor` | Code restructuring without behavior change | "refactor", "rename", "extract", "move", "simplify" |
| `docs` | Documentation only changes | Changes only to .md files, Javadoc |
| `test` | Test additions or modifications | Changes only to *Test.java, *IT.java files |
| `style` | Code formatting, no logic change | "format", "style", "lint", whitespace only |
| `perf` | Performance improvements | "cache", "optimize", "performance", "efficient" |
| `build` | Build system or dependencies | Changes to pom.xml, build config |
| `ci` | CI/CD pipeline changes | Changes to .github/workflows, pipelines |
| `chore` | Maintenance tasks | Configuration updates, cleanup |

**Priority when multiple types apply:**
1. Breaking changes (always mark with '!')
2. `feat` (new functionality)
3. `fix` (bug fixes)
4. `perf` (performance)
5. `refactor` (code improvements)
6. Other types

**Combine git diff analysis with JIRA issue type:**
- Start with the JIRA issue type suggestion (from Step 2)
- Validate against the actual code changes in git diff
- Final decision: git diff takes priority, but JIRA provides context
- Example: JIRA says "Task" but code adds new API endpoints → use `feat`

**Reference:** For detailed detection patterns and examples, read `references/commit-patterns.md` when needed.

### Step 5: Determine Scope

Extract the scope from the changed files to indicate which part of the codebase is affected.

**Scope detection strategies:**

#### Strategy 1: By Module (preferred for Clean Architecture projects)
- Changes in `domain/` → `domain`
- Changes in `application/` → `application`
- Changes in `infrastructure/` → `infrastructure`
- Changes in `api-rest/` → `api` or `rest`
- Changes in `boot/` → `boot`

#### Strategy 2: By Domain Concept
- Extract common prefix from changed files:
  - `OrderService.java`, `OrderRepository.java` → `order`
  - `UserEntity.java`, `UserMapper.java` → `user`
  - `PaymentProcessor.java`, `PaymentValidator.java` → `payment`

#### Strategy 3: By Feature Area
- Authentication-related files → `auth`
- Validation-related files → `validation`
- Security-related files → `security`

#### Strategy 4: Multiple Scopes
- If changes affect multiple unrelated areas, either:
  - Omit scope entirely
  - Use the most significant scope
  - Consider this indicates multiple commits might be needed

**Examples:**
```
domain/entities/Order.java → scope: domain or order
api-rest/controllers/UserController.java → scope: api or user
infrastructure/repositories/ProductRepositoryImpl.java → scope: infrastructure or product
```

**Consider JIRA labels for scope:**
- If JIRA ticket has labels like "backend", "api", "infrastructure", use them to validate scope
- Labels can help when changes span multiple modules

### Step 6: Detect Breaking Changes

Identify if the changes include breaking changes that require the '!' marker.

**Breaking change indicators:**
1. Removed public API methods or endpoints
2. Changed method signatures (parameters, return types)
3. Changed API contracts (request/response models)
4. Removed or renamed configuration properties
5. Changed database schema (breaking migrations)
6. Changed behavior that clients depend on

**Keywords in diff:**
- "remove", "delete" (of public APIs)
- "rename" (for public interfaces)
- "change signature"
- "breaking"
- "incompatible"

**If breaking change detected:** Add '!' after type and scope:
- `feat(api)!: remove deprecated endpoint`
- `fix(domain)!: change order status validation`

**Check JIRA description for breaking change mentions:**
- JIRA ticket may explicitly mention "breaking change" or "incompatible"
- Use this as additional signal, but verify with code changes

### Step 7: Generate Commit Description

Create a concise, imperative description of the change.

**Description guidelines:**
- Use imperative mood: "add feature" not "added feature" or "adds feature"
- Start with lowercase letter (exception: proper nouns)
- No period at the end
- Be specific but concise (50 characters or less preferred)
- Focus on WHAT changed, not HOW

**Incorporate JIRA summary:**
- Use the JIRA summary as inspiration for the description
- Extract key terms from JIRA summary (e.g., "Migrate BC Assortment Planning to v2" → "migrate BC Assortment Planning integration to v2")
- Combine with git diff insights to be more specific
- Example:
  - JIRA: "Update purchase variable integration"
  - Git diff: Shows migration from v1 to v2 API
  - Result: "migrate BC Assortment Planning integration to v2"

**Good examples:**
- `add user authentication service`
- `fix null pointer in order validation`
- `refactor payment processing logic`
- `improve query performance with caching`
- `migrate BC Assortment Planning integration to v2` (from JIRA + git context)

**Bad examples:**
- `Added new stuff` (too vague, wrong tense)
- `Fixed a bug.` (too vague, has period)
- `I have updated the code to use a better algorithm for processing orders` (too long, wrong perspective)

### Step 8: Create the Commit

Generate the final commit message and create the commit.

**Commit message format:**
```
[JIRA-ID] <type>(<scope>): <description>
```

**Examples:**
```
[ICPRFPPREC-123] feat(domain): add order creation validation
[PROJ-456] fix(api): handle null pointer in user lookup
[APP-789] refactor(infrastructure): simplify repository implementation
[TASK-321] perf(application)!: change caching strategy for performance
```

**Commands to create commit:**
```bash
# Stage all changes
git add .

# Create commit with generated message
git commit -m "[JIRA-ID] type(scope): description"

# Verify commit was created
git log -1 --oneline
```

**Important:**
- **Do NOT include** "Co-Authored-By: Claude <noreply@anthropic.com>" or any references to AI in the commit message
- Do NOT ask for user confirmation, create the commit automatically
- Stage ALL local changes with `git add .`
- Use the exact message format generated

**Commit body (optional but recommended for complex changes):**
If the change is complex or involves multiple aspects, use the commit body to provide more context:
```
[JIRA-ID] type(scope): description

- Detail 1 from git diff
- Detail 2 from git diff
- Detail 3 from git diff
```

Example incorporating JIRA context:
```
[ICPRFPPREC-4991] feat(infrastructure): migrate BC Assortment Planning integration to v2

- Update rest client to use bc-assortment-planning-rest v2.0.0
- Refactor PurchaseVariable domain model and mapper
- Update repository implementation for new API contract
- Remove deprecated campaign fields from purchase variables
- Add new configuration properties for v2 endpoints
```

### Step 9: Verify and Report

After creating the commit, verify it was successful and report to the user.

**Verification commands:**
```bash
# Show the created commit
git log -1 --format="%h %s"

# Show commit details
git show --stat HEAD
```

**Report to user:**
- Confirm commit was created
- Show the commit hash and message
- Show brief statistics of what was committed

## Complete Example Workflow

**Scenario:** User says "commit my changes"

**Step-by-step execution:**

1. **Extract JIRA ID:**
   ```bash
   $ git rev-parse --abbrev-ref HEAD
   feature/ICPRFPPREC-456-add-order-validation
   ```
   JIRA ID: `ICPRFPPREC-456`

2. **Fetch JIRA ticket information:**
   ```
   mcp__jira-atlassian__jira_get_issue(
     issue_key: "ICPRFPPREC-456",
     fields: "summary,description,issuetype,labels"
   )
   ```
   Response:
   ```json
   {
     "key": "ICPRFPPREC-456",
     "fields": {
       "summary": "Add custom validation rules for purchase orders",
       "issuetype": {"name": "Story"},
       "labels": ["backend", "validation"],
       "description": "Implement validation logic for order creation..."
     }
   }
   ```

3. **Analyze git changes:**
   ```bash
   $ git diff --name-status
   A    domain/entities/OrderValidation.java
   M    domain/services/OrderService.java
   A    domain/valueobjects/ValidationResult.java
   M    application/usecases/CreateOrderUseCase.java
   ```

4. **Determine type:**
   - JIRA suggests: `feat` (Story type)
   - Git diff confirms: `feat` (new files added with business logic)
   - Final: `feat` ✓

5. **Determine scope:**
   - Git diff shows: mostly `domain/` changes
   - JIRA labels: "backend", "validation"
   - Final: `domain` (primary location)

6. **Check breaking changes:** None detected

7. **Generate description:**
   - JIRA summary: "Add custom validation rules for purchase orders"
   - Git changes: new validation entities and use case updates
   - Final: `add order validation with custom rules`

8. **Create commit:**
   ```bash
   $ git add .
   $ git commit -m "[ICPRFPPREC-456] feat(domain): add order validation with custom rules"
   ```

9. **Verify and report:**
   ```bash
   $ git log -1 --format="%h %s"
   a3f5d21 [ICPRFPPREC-456] feat(domain): add order validation with custom rules
   ```

   Report: "✓ Created commit a3f5d21: [ICPRFPPREC-456] feat(domain): add order validation with custom rules"

## Advanced Scenarios

### Scenario: Multiple Unrelated Changes

If the diff shows multiple unrelated changes (e.g., domain changes + documentation + CI fixes), consider the dominant change type or suggest the user commit separately.

**Approach:**
1. Identify the most significant change
2. Use that for the commit type
3. Optionally mention other changes in commit body

**Example:**
```
[PROJ-123] feat(domain): add user preferences

- Add domain entity and value objects
- Update API documentation
- Fix CI pipeline warning
```

### Scenario: Breaking Change

When a breaking change is detected:

```
[PROJ-123] feat(api)!: remove deprecated authentication endpoint

BREAKING CHANGE: The /auth/legacy endpoint has been removed.
Use /auth/v2 instead.
```

### Scenario: No JIRA ID in Branch

If branch name doesn't contain JIRA ID (e.g., `main`, `develop`, or malformed branch name):

**Option 1:** Omit JIRA ID prefix
```
feat(domain): add order validation
```

**Option 2:** Ask user for JIRA ID (if context suggests it's needed)

### Scenario: JIRA Context Improves Commit Message

**Without JIRA integration:**
```
Branch: dependency/ICPRFPPREC-4991-migracion-bc-
Git diff: Shows changes in infrastructure/, pom.xml updates, config changes
Result: [ICPRFPPREC-4991] refactor(infrastructure): update dependencies
```

**With JIRA integration:**
```
Branch: dependency/ICPRFPPREC-4991-migracion-bc-
JIRA Summary: "Migrate BC Assortment Planning integration to v2"
JIRA Type: Task
Git diff: Shows bc-assortment-planning-rest v1→v2, API contract changes
Result: [ICPRFPPREC-4991] feat(infrastructure): migrate BC Assortment Planning integration to v2
```

The JIRA context reveals:
- The change is a migration (more specific than "update")
- It's specifically about BC Assortment Planning (extracted from JIRA)
- It's version 2 (from JIRA summary)
- It should be `feat` not `refactor` (new version = new functionality)

## References

This skill includes a detailed reference file:

- `references/commit-patterns.md` - Comprehensive patterns for commit type detection, scope determination, and breaking change identification with real examples

Read this reference when encountering ambiguous changes or needing more detailed guidance on commit type selection.

## Best Practices

1. **Be specific but concise** - Describe what changed, not how it was implemented
2. **Use project conventions** - Follow Clean Architecture module naming
3. **One logical change per commit** - If changes are unrelated, suggest separate commits
4. **Focus on user impact** - Describe changes from user/developer perspective
5. **Detect breaking changes carefully** - Only mark as breaking if it truly affects consumers
6. **Keep scope consistent** - Use the same scope naming throughout the project

## Notes

- This skill operates in "local mode" using git commands directly
- No user confirmation is required - analyze and commit automatically
- All changes are staged with `git add .` before committing
- The skill assumes a JIRA ID is always present in branch names (common convention)
- For multi-module Maven projects, prefer module-based scopes (domain, application, infrastructure)
- **JIRA integration is optional**: If JIRA API is unavailable or fails, the skill continues with git diff analysis only
- **Git diff is the source of truth**: JIRA provides context and suggestions, but actual code changes determine the final commit type and scope
- The JIRA MCP tool (`mcp__jira-atlassian__jira_get_issue`) requires proper authentication and network access to Jira instance