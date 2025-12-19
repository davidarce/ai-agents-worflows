---
allowed-tools: Skill(pr-creator), Bash, Read
argument-hint: [project-name]
description: Create a pull request for my changes
model: bedrock/claude-haiku-4.5
---

### Task

- Identify the project directory from the argument $ARGUMENTS
- Ensure you are in the correct project directory
- Use the `pr-creator` skill to create a pull request for my changes