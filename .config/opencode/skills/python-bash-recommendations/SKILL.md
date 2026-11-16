---
name: python-bash-recommendations
description: "Provide Python and Bash programming recommendations and best practices when users request coding help. Trigger: Python or Bash programming requests, code reviews, or when users ask for language-specific guidance."
license: MIT
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

Load this skill whenever a user requests Python or Bash programming help, code reviews, or language-specific guidance. This skill provides idiomatic recommendations, common patterns, and best practices.

## Voice Rules

| Rule | Requirement |
|------|-------------|
| Match user language | Reply in the user's current language for conversation; technical artifacts default to English |
| Keep it concise | Provide focused recommendations without unnecessary elaboration |
| Language defaults | Generated code defaults to English identifiers and comments unless user requests another language |
| Artifact language | Code comments and UI copy default to English; Spanish technical artifacts only when explicitly requested |
| Neutral tone | Professional and direct without regional slang or dialect-specific grammar |

## Python Recommendations

### Idiomatic Patterns

```python
# Good: use f-strings for string formatting
name = "world"
print(f"Hello, {name}")  # Preferred over "Hello, " + name

# Good: use list comprehensions for simple transformations
squares = [x**2 for x in range(10)]

# Good: use context managers for resource handling
with open("file.txt") as f:
    content = f.read()

# Good: prefer enumerate over range(len())
for i, item in enumerate(items):
    process(item)
```

### Common Pitfalls to Avoid

- Mutable default arguments: `def f(x=[])` — use `def f(x=None)` instead
- Late-binding closures in loops — capture loop variable explicitly
- Integer division vs float division: `/` vs `//`
- `is` vs `==` for comparisons — use `==` for value equality
- Forgetting to handle empty states in loops or collections

### Standard Library Focus

Prefer stdlib modules over third-party when possible:
- `os.path` or `pathlib` for file paths
- `collections` module (Counter, defaultdict, OrderedDict)
- `pathlib` for path operations (Python 3.4+)
- `json` for JSON parsing/writing
- `argparse` for command-line interfaces

## Bash Recommendations

### Shebang and Header

```bash
#!/bin/bash
# Always use bash, never dash/posix-only assumptions
set -euo pipefail  # Good practice for robust scripts
# Disable locally when a failing command is expected: set +e
```

### Variable Handling

```bash
# Good: always quote expansions
"$var"
"$@"

# Good: use arrays for containers
arr=(a b c)
for x in "${arr[@]}"; do
    process "$x"
done

# Good: prefer $(...) over backticks for command substitution
result="$(some_command)"
```

### Common Pitfalls to Avoid

- `set -e` in long scripts — can silently truncate runs; use explicit status checks
- Unquoted expansions — the #1 bug class in this user's scripts
- Arrays without proper iteration: `for x in "${arr[@]}"`
- Using `set -e` + automation scripts without per-step status files
- Parameter expansion without quotes: `"$var"` not just `$var`

### Script Structure

- Use `#!/bin/bash` (never `#!/usr/bin/env bash` for Gentoo scripts)
- Quote all variable expansions
- Use `set -euo pipefail` in robust scripts
- Prefer `$(...)` over backticks for nesting
- Exit status: check immediately after the command (`$?`), never after another command ran

## Cross-Language Guidelines

### When User Requests Programming Help

1. **Read the existing code first** — inspect what's already written before suggesting changes
2. **Match the project's style** — respect existing conventions, naming, and patterns
3. **Provide minimal, targeted recommendations** — focus on the specific issue, not a complete rewrite
4. **Explain the "why"** — technical reasoning for each recommendation
5. **Keep artifacts in English** — code identifiers, comments in generated artifacts default to English

### Skill Loading

This skill loads automatically when the task context includes Python or Bash programming. The orchestrator detects the language from file extensions and task context, then passes relevant recommendations.

## Example Output Format

```text
## Python Recommendations

**Idiomatic pattern**: Use `pathlib` for path operations instead of `os.path`.

**Common pitfall**: Mutable default arguments — use `None` and handle inside function.

**Stdlib preference**: `json.loads()` over third-party parsing when possible.

## Bash Recommendations

**Shebang**: Always `#!/bin/bash` with `set -euo pipefail` for robust scripts.

**Variable quoting**: Quote all expansions: `"$var"`, `"$@"`.

**Common pitfall**: `set -e` in long scripts can silently truncate execution.
```

## Skill Resolution Feedback

After delegation that returns results, check the `skill_resolution` field:
- `paths-injected` → all good; exact skill paths were passed and loaded
- `fallback-registry`, `fallback-path`, or `none` → skill cache was lost; re-read the registry immediately