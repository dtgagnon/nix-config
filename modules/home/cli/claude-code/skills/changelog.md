---
name: changelog
description: Update CHANGELOG.md with new entry
allowed-tools: Bash(git log:*), Bash(git diff:*)
argument-hint: [version] [change-type] [message]
---

Parse the version, change type, and message from the input
and update the CHANGELOG.md file accordingly.
