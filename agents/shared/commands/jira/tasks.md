---
allowed-tools: Read, mcp__jira-atlassian__jira_get_issue
argument-hint: [jira_ticket_id]
description: Create jira sub-tasks based on the provided user story and jira ticket id.
model: inherit
---

## Context

- Get the details of a Jira ticket using the provided [jira_ticket_id] and `mcp__jira-atlassian__jira_get_issue` tool
- Analyze the user story and scenarios provided:
  - user story path `.user-stories/<jira_ticket_id>/user-story.md`
  - scenarios path `.user-stories/<jira_ticket_id</scenarios.md`
- To create subtasks, uses the `mcp__atlassian__jira_create_issue` as shown below:
    Backend subtask creation example:
    ```json
    {"tool":"jira_create_issue","args":{"project_key":"ICPRFPPREC","summary":"[BACK] short summary", "issue_type":"Sub-tarea","assignee":null,"description":"detailed description","components":null,"additional_fields":{"parent":"jira_ticket_id"}}}
    ```
    Frontend subtask creation example:
    ```json
    {"tool":"jira_create_issue","args":{"project_key":"ICPRFPPREC","summary":"[FRONT] short summary", "issue_type":"Sub-tarea","assignee":null,"description":"detailed description","components":null,"additional_fields":{"parent":"jira_ticket_id"}}}
    ```
  
- All subtasks must be written in English, even if the main ticket is in another language.

## Your task

Based on the provided [jira-ticket-id] and detailed user story, your task is to create detailed Jira subtasks that break down the implementation work needed to fulfill the requirements.
