---
allowed-tools: Read, Write, Write(.user-stories/*)
argument-hint: [jira_ticket_id] [transcript]
description: Create a user story based on the provided requirements.
model: inherit
---

## Your task

## Steps:

1. **Analyze the provided $ARGUMENTS transcript, then:**
   - Based on the provided $ARGUMENTS transcript, your task is to create the user story in the format "As a <type of user>, I want <an action> so that <a benefit>" and in `Markdown` format.
   - The user story must be written in English.
   - Ensure clarity and completeness in the user story to facilitate understanding and implementation.
   - Create the user story directory in `.user-stories/<jira_ticket_id>`
   - Create the file `user-story.md` inside that directory containing the user story in Markdown format.

2. **Generate acceptance criteria in Gherkin format:**
   - Based on the user story created in step 1 `.user-stories/<jira_ticket_id>/user-story.md`, generate scenarios using Gherkin syntax.
   - Create the file `scenarios.md` inside the same directory as the user story.
   - Ensure the scenarios are clear, testable, and cover all aspects of the user story.
   - Format:

    ```markdown
    ### Feature: <Feature Name>
    
    ### Scenario: <Scenario Name>
      **Given** <initial context>
      **And** <additional outcomes>  
      **When** <event occurs>
      **Then** <outcome is expected>
      **And** <additional outcomes>
    ```

**Success Criteria**
- A user story is created in `.user-stories/<jira_ticket_id>/user-story.md` based on the provided requirements.
- Scenarios in Gherkin format are created in `.user-stories/<jira_ticket_id>/scenarios.md`.
- Both files are well-structured, clear, and facilitate understanding and implementation of the user story.