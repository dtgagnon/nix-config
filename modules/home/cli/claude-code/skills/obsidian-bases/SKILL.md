---
name: obsidian-bases
description: Create Obsidian database views (Bases) using YAML syntax for note organization and tracking
---

# Obsidian Bases - Database Views for Notes

Create database-like views to organize, filter, and visualize notes by their properties.

## Creating Bases

**Standalone file** (`.base` extension): `![[filename.base]]` or `![[filename.base#ViewName]]`

**Embedded code block**:
````markdown
```base
filters:
  file.hasTag("example")
views:
  - type: table
    name: Table
```
````

## Minimal Example

```yaml
views:
  - type: table
    name: All Files
```

## Core Structure

```yaml
filters:           # Optional - global file filters
  and/or/not: ...

formulas:          # Optional - computed properties
  name: "expression"

properties:        # Optional - display config
  prop:
    displayName: "Name"

views:             # Required - at least one
  - type: table    # table, list, cards, map
    name: "View"
    filters: ...   # View-specific filters
    order: [prop1, prop2]
    groupBy:
      property: status
      direction: ASC
    summaries:
      prop: Sum
    limit: 50
```

## Property Types

Properties come from three sources:
- `status`, `author` - note frontmatter (no prefix)
- `file.name`, `file.mtime` - file metadata (`file.` prefix)
- `formula.days_old` - computed in base definition (`formula.` prefix)

File properties: `file.name` (name without extension), `file.path`, `file.folder`, `file.ctime` (created), `file.mtime` (modified), `file.size`, `file.tags`, `file.links`

## Filters

```yaml
filters:
  and:                           # All must match
    - file.hasTag("project")
    - 'status != "done"'
  or:                            # Any must match
    - file.inFolder("Work")
    - file.hasLink("Important")
  not:                           # Exclude
    - file.hasTag("archived")
```

**Operators**: `==`, `!=`, `>`, `<`, `>=`, `<=`, `&&`, `||`, `!`

**Common patterns**:
```yaml
file.hasTag("tag")              # Has tag
file.inFolder("Path")           # In folder
file.hasLink("Note")            # Links to note
file.mtime > now() - "7d"       # Modified in last week
'property != null'              # Has property value
```

**Context reference**: Use `this.file` to reference the containing note (useful for backlinks view).

## Formulas

```yaml
formulas:
  # Age tracking - days since creation/modification
  days_old: '(now() - file.ctime) / (1000 * 60 * 60 * 24)'
  days_since_update: 'Math.floor((now() - file.mtime) / (1000*60*60*24))'

  # Deadline tracking
  days_until_due: '(due - now()) / (1000 * 60 * 60 * 24)'
  is_overdue: 'due < now()'

  # Visual status - adapt values to your workflow
  status_icon: 'if(status == "done", "✅", if(status == "in-progress", "🔄", "⏳"))'

  # Display helpers
  rating_stars: 'if(rating, "⭐".repeat(rating), "")'
  formatted_date: 'file.mtime.format("YYYY-MM-DD")'

  # Calculations
  total: 'price * quantity'
  backlink_count: 'file.backlinks.length'
```

## Date Arithmetic

```yaml
now() + "1d"                    # Tomorrow
today() - "1M"                  # One month ago
file.mtime > now() - "7d"       # Within last week

# Units: y/year, M/month, w/week, d/day, h/hour, m/minute, s/second
```

## Summaries

**Built-in**: `Average`, `Sum`, `Min`, `Max`, `Median`, `Earliest`, `Latest`, `Unique`, `Filled`, `Empty`

```yaml
views:
  - type: table
    summaries:
      file.name: Unique
      estimate: Sum
      due: Earliest
```

## Complete Template

Adapt this template for different use cases by changing the tag filter and properties.

```yaml
# Note frontmatter should include:
# - Tasks: status, priority, due, assignee, tags: [project]
# - Reading: type, author, rating, status, tags: [reading]
# - Notes: topic, stage, tags: [notes]

filters:
  and:
    - file.hasTag("project")    # Change tag: project, reading, notes, etc.
    - 'status != "done"'

formulas:
  days_until_due: '(due - now()) / (1000 * 60 * 60 * 24)'
  is_overdue: 'due < now()'
  status_icon: 'if(status == "done", "✅", if(status == "in-progress", "🔄", "⏳"))'

properties:
  formula.status_icon:
    displayName: ""
  formula.days_until_due:
    displayName: Days Left

views:
  - type: table
    name: Active Tasks
    order: [priority, due]
    groupBy:
      property: status
      direction: ASC
    summaries:
      file.name: Unique

  - type: cards
    name: Board
    groupBy:
      property: status
```

**For embedded use**: Remove `formulas` and `properties` sections, keep just `filters` and `views`.

## Functions

File functions: `file.hasTag("t")`, `file.hasLink("n")`, `file.inFolder("p")`

String: `.length`, `.toUpperCase()`, `.toLowerCase()`, `.contains("x")`

Number: `.toFixed(2)`, `Math.floor()`, `Math.ceil()`, `Math.round()`

Date: `now()`, `today()`, `date("2025-01-15")`, `.format("YYYY-MM-DD")`, `.date()`

Array: `.length`, `.contains(v)`, `.join(", ")`, `.filter(v => ...)`, `.mean()`

Logic: `if(cond, trueVal, falseVal)`, `link("file")`, `icon("name")`

Full reference: https://help.obsidian.md/bases/functions

## Performance Tips

- Prefer `file.links` over `file.backlinks` (faster)
- Filter at global level when possible
- Avoid `file.properties` in large vaults
- Use `limit:` for large result sets
