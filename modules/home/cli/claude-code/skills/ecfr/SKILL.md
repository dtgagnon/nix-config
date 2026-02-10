---
name: ecfr
description: Query US Code of Federal Regulations via eCFR API (agencies, search, structure, XML)
---

# eCFR API - US Code of Federal Regulations

Base URL: `https://www.ecfr.gov`

## Admin Service

### GET /api/admin/v1/agencies.json
Returns all agencies with their CFR references.

**Parameters:** None

**Response fields:** `name`, `short_name`, `display_name`, `sortable_name`, `slug`, `children[]`, `cfr_references[{title, chapter}]`

### GET /api/admin/v1/corrections.json
Returns all eCFR corrections.

**Parameters:**
| Name | Type | Description |
|------|------|-------------|
| date | string (query) | Restricts to corrections on/before this date AND corrected on/after. Format: YYYY-MM-DD |
| title | string (query) | Title number: '1', '2', '50', etc |
| error_corrected_date | string (query) | Only corrections corrected on this date. Format: YYYY-MM-DD |

**Response fields:** `ecfr_corrections[{id, cfr_references[], corrective_action, error_corrected, error_occurred, fr_citation, position, display_in_toc, title, year, last_modified}]`

### GET /api/admin/v1/corrections/title/{title}.json
Returns corrections for a specific title.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| title | string (path) | Yes | Title number: '1', '2', '50', etc |

## Search Service

All search endpoints share these common parameters:

| Name | Type | Description |
|------|------|-------------|
| query | string (query) | Search term; searches headings and full text |
| agency_slugs[] | array[string] (query) | Limit to agencies (get slugs from agencies endpoint) |
| date | string (query) | Limit to content present on this date (YYYY-MM-DD) |
| last_modified_after | string (query) | Content modified after this date (YYYY-MM-DD) |
| last_modified_on_or_after | string (query) | Content modified on or after this date (YYYY-MM-DD) |
| last_modified_before | string (query) | Content modified before this date (YYYY-MM-DD) |
| last_modified_on_or_before | string (query) | Content modified on or before this date (YYYY-MM-DD) |

### GET /api/search/v1/results
Search results with pagination.

**Additional parameters:**
| Name | Type | Description |
|------|------|-------------|
| per_page | integer (query) | Results per page (max 1000) |
| page | integer (query) | Page number (can't paginate beyond 10,000 total results) |
| order | string (query) | Order of results |
| paginate_by | string (query) | 'date' groups results by date on same page (requires last_modified_* param) |

**Response:** `{results[], meta: {description, current_page, total_count, total_pages, max_score, min_date, max_date}}`

### GET /api/search/v1/count
Returns count of matching results.

### GET /api/search/v1/summary
Returns search summary details.

### GET /api/search/v1/counts/daily
Returns result counts grouped by date.

### GET /api/search/v1/counts/titles
Returns result counts grouped by CFR title.

### GET /api/search/v1/counts/hierarchy
Returns result counts grouped by hierarchy level.

### GET /api/search/v1/suggestions
Returns search suggestions/autocomplete.

## Versioner Service

### GET /api/versioner/v1/titles.json
Summary information about each title.

**Parameters:** None

**Response:** `{titles[{number, name, latest_amended_on, latest_issue_date, up_to_date_as_of, reserved, processing_in_progress?}], meta: {date, import_in_progress}}`

### GET /api/versioner/v1/structure/{date}/title-{title}.json
Complete structure of a title as JSON (no content, just hierarchy).

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| date | string (path) | Yes | YYYY-MM-DD (use 'current' for latest) |
| title | string (path) | Yes | Title number: '1', '2', '50', etc |

**Response:** Nested structure with `{type, label, label_level, label_description, identifier, reserved?, children[], section_range?}`

### GET /api/versioner/v1/full/{date}/title-{title}.xml
Source XML for a title or subset. Returns downloadable XML for full titles, processed XML for subsets.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| date | string (path) | Yes | YYYY-MM-DD |
| title | string (path) | Yes | Title number: '1', '2', '50', etc |
| subtitle | string (query) | No | Uppercase letter: 'A', 'B', 'C' |
| chapter | string (query) | No | Roman numerals or digits: 'I', 'X', '1' |
| subchapter | string (query) | No | **Requires chapter.** Uppercase letters: 'A', 'B', 'I' |
| part | string (query) | No | Part identifier |
| subpart | string (query) | No | **Requires part.** Generally uppercase letter: 'A', 'B', 'C' |
| section | string (query) | No | **Requires part.** Format: '121.1', '13.4', '1.9' |
| appendix | string (query) | No | **Requires subtitle, chapter, or part.** Formats: 'A', 'III', 'App. A' |

### GET /api/versioner/v1/ancestry/{date}/title-{title}.json
Returns complete hierarchy path from leaf node to title root.

**Parameters:** Same as full XML endpoint above.

**Response:** Array of ancestors from title down to requested node, each with `{type, label, label_level, label_description, identifier, reserved?, section_range?}`

### GET /api/versioner/v1/versions/title-{title}.json
Returns all sections and appendices in a title with version history.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| title | string (path) | Yes | Title number: '1', '2', '50', etc |
| issue_date[on] | string (query) | No | Content added on this issue date |
| issue_date[lte] | string (query) | No | Content added on or before this date |
| issue_date[gte] | string (query) | No | Content added on or after this date |
| subtitle | string (query) | No | Uppercase letter: 'A', 'B', 'C' |
| chapter | string (query) | No | Roman numerals or digits: 'I', 'X', '1' |
| subchapter | string (query) | No | **Requires chapter.** |
| part | string (query) | No | Part identifier |
| subpart | string (query) | No | **Requires part.** |
| section | string (query) | No | **Requires part.** |
| appendix | string (query) | No | **Requires subtitle, chapter, or part.** |

**Response:** `{content_versions[{date, amendment_date, issue_date, identifier, name, part, substantive, removed, subpart, title, type}], meta: {title, result_count, issue_date, latest_amendment_date, latest_issue_date}}`

**Error codes:** 400 (bad request with message), 503 (title being processed, check Retry-After header)

## CFR Title Reference

| # | Subject |
|---|---------|
| 1 | General Provisions |
| 2 | Federal Financial Assistance |
| 3 | The President |
| 7 | Agriculture |
| 10 | Energy |
| 12 | Banks and Banking |
| 14 | Aeronautics and Space |
| 17 | Commodity and Securities Exchanges |
| 20 | Employees' Benefits |
| 21 | Food and Drugs |
| 26 | Internal Revenue |
| 29 | Labor |
| 40 | Protection of Environment |
| 42 | Public Health |
| 45 | Public Welfare |
| 47 | Telecommunication |
| 49 | Transportation |
| 50 | Wildlife and Fisheries |

## Hierarchy Dependency Rules

- `subchapter` requires `chapter`
- `subpart` requires `part`
- `section` requires `part`
- `appendix` requires `subtitle`, `chapter`, or `part`
