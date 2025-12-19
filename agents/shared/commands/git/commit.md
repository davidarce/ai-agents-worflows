---
allowed-tools: Skill(smart-commit), Bash
argument-hint: [project]
description: Create a smart commit for my changes
model: bedrock/claude-haiku-4.5
---

### Task

- Identify the project directory from the argument $ARGUMENTS
- Ensure you are in the correct project directory
- Use the `smart-commit` skill to commit my changes