# Verification Patterns

How to verify different types of artifacts are real implementations, not stubs or placeholders. These patterns are used by Step 5 (artifact verification) and Step 6 (anti-pattern scan) of the verify-story workflow.

## Core Principle

**Existence does NOT equal implementation.**

A file existing does not mean the feature works. Verification checks 4 levels:

1. **Exists** — File is present at expected path
2. **Substantive** — Content is real implementation, not placeholder
3. **Wired** — Connected to the rest of the system (imported, called)
4. **Data-Flowing** — Real data flows through the connection (not static/empty)

Levels 1-3 can always be checked programmatically. Level 4 depends on the artifact type.

---

## Universal Stub Patterns

These indicate placeholder code regardless of language:

```bash
# Stub comments
grep -n -E "TODO|FIXME|XXX|HACK|PLACEHOLDER" "$file"
grep -n -i -E "implement|add later|coming soon|will be|not yet|not available" "$file"
grep -n -E "# \.\.\.|// \.\.\.|/\* \.\.\. \*/" "$file"

# Placeholder text in output
grep -n -i -E "placeholder|lorem ipsum|coming soon|under construction" "$file"
grep -n -i -E "sample data|example|test data|dummy" "$file"

# Empty or trivial implementations
grep -n -E "pass$|return None$|return \{\}|return \[\]|raise NotImplementedError" "$file"
```

---

## Python-Specific Patterns

### Module / Package Verification

**Existence check:**
```bash
# File exists and is a proper module
[ -f "$module_path" ]
# Package has __init__.py
[ -f "$(dirname $module_path)/__init__.py" ]
```

**Substantive check:**
```bash
# Has real code, not just pass or imports
grep -c -E "^(def |class |async def )" "$file"   # Function/class count
wc -l < "$file"                                    # Line count (>20 for real modules)
# Check for stub bodies
grep -A 2 "^def \|^class " "$file" | grep -c "pass$\|raise NotImplementedError\|return None$"
```

**Stub patterns specific to Python:**
```python
# RED FLAGS — these are stubs:
def process_data(data):
    pass

def handle_request(req):
    return None

def compute_score(factors):
    raise NotImplementedError

class MyService:
    def run(self):
        ...  # Ellipsis body = stub

def get_results():
    return []  # Empty list with no real logic

def transform(input):
    return input  # Identity function = noop
```

**Wiring check:**
```bash
# Module is imported somewhere
grep -r "from ${module} import\|import ${module}" src/ --include="*.py" | grep -v "$file" | wc -l
# Exported symbols are actually called
grep -r "${function_name}(" src/ --include="*.py" | grep -v "def ${function_name}" | wc -l
```

### Pydantic Model Verification

**Substantive check:**
```bash
# Model has real fields (not just pass)
grep -A 20 "class ${model_name}" "$file" | grep -E "^\s+\w+\s*:" | wc -l
# Has validators or computed fields
grep -E "@validator|@field_validator|@computed_field|@model_validator" "$file"
```

**Stub patterns:**
```python
# RED FLAGS:
class MigrationReport(BaseModel):
    pass  # No fields

class RepoState(BaseModel):
    name: str  # Only one trivial field

class AnalysisResult(BaseModel):
    data: dict = {}  # Catch-all dict instead of real fields
```

**Wiring check:**
```bash
# Model is instantiated somewhere (not just defined)
grep -r "${model_name}(" src/ --include="*.py" | grep -v "class ${model_name}" | wc -l
# Model is used in function signatures
grep -r "${model_name}" src/ --include="*.py" | grep -v "class ${model_name}" | grep -E "def |-> |: ${model_name}" | wc -l
```

### CLI Command Verification (Typer / Click / argparse)

**Existence check:**
```bash
# Command function exists
grep -E "@app\.(command|callback)|@click\.(command|group)|add_parser" "$cli_file"
```

**Substantive check:**
```bash
# Command has real body (not just print/pass)
grep -A 20 "@app.command" "$cli_file" | grep -v "print\|pass\|typer.echo\|click.echo" | grep -E "^\s+\w+" | wc -l
# Command calls actual logic (not just prints)
grep -A 20 "@app.command" "$cli_file" | grep -E "import|from |result.*=|return "
```

**Stub patterns:**
```python
# RED FLAGS:
@app.command()
def status(repo: str):
    typer.echo("Status: not implemented yet")

@app.command()
def analyze():
    print("Coming soon")
    raise typer.Exit()

@app.command()
def migrate(repo: str):
    pass  # Empty command body
```

**Wiring check:**
```bash
# Command calls functions from core/stage layers (not self-contained)
grep -A 30 "@app.command" "$cli_file" | grep -E "from.*import|^\s+\w+\.\w+("
# Command is registered in the app (for sub-apps)
grep -E "app\.add_typer|include_router" "$cli_file"
```

### Test File Verification

**Existence check:**
```bash
# Test file exists
[ -f "$test_path" ]
# Contains actual test functions
grep -c "^def test_\|^class Test" "$test_path"
```

**Substantive check:**
```bash
# Tests have assertions (not just function stubs)
grep -c "assert \|assert_\|assertEqual\|pytest.raises\|expect(" "$test_path"
# Tests call the code under test (not just pass)
grep -A 5 "def test_" "$test_path" | grep -v "pass$\|...$" | grep -E "^\s+\w+" | wc -l
```

**Stub patterns:**
```python
# RED FLAGS:
def test_status_command():
    pass  # No assertion

def test_analysis():
    assert True  # Always passes

def test_migration():
    # TODO: implement
    pytest.skip("Not yet implemented")

class TestRepoAnalysis:
    def test_placeholder(self):
        ...  # Ellipsis body
```

**Wiring check:**
```bash
# Test file is discovered by pytest (in tests/ directory or matching test_*.py)
# Test imports the module it's testing
grep "^from.*import\|^import" "$test_path" | grep -v "pytest\|unittest\|mock\|fixture"
```

### Dataclass / TypedDict Verification

**Substantive check:**
```bash
# Has meaningful fields
grep -A 15 "@dataclass" "$file" | grep -E "^\s+\w+\s*:" | wc -l
# Has methods beyond __init__ (for dataclasses with behavior)
grep -A 30 "@dataclass" "$file" | grep -E "^\s+def " | wc -l
```

**Stub patterns:**
```python
# RED FLAGS:
@dataclass
class RepoInfo:
    name: str  # Only one field, no real data

@dataclass
class Result:
    data: Any = None  # Catch-all with default None
```

---

## Wiring Verification Patterns

Wiring verification checks that components actually communicate. This is where 80% of stubs hide.

### Pattern: CLI Command -> Core Logic

**Check:** Does the CLI command call functions from the core/stage layers?

```bash
# Find function calls in command body
grep -A 30 "@app.command" "$cli_file" | grep -E "from.*import|^\s+\w+\.\w+\("
# Verify imported functions are actually called (not just imported)
IMPORTS=$(grep "^from.*import" "$cli_file" | sed 's/.*import //' | tr ',' '\n' | tr -d ' ')
for func in $IMPORTS; do
  grep -c "$func(" "$cli_file" | grep -v "^0$"
done
```

**Red flags:**
```python
# Import exists but function not called:
from core.analysis import run_analysis  # imported
# ... but run_analysis() never appears in any command body

# Command calls internal helpers only (no core logic):
@app.command()
def status(repo: str):
    _print_header(repo)  # Only formatting, no core logic
```

### Pattern: Stage -> Core

**Check:** Does the stage function use core modules?

```bash
# Stage imports core modules
grep "from.*core.*import\|from.*models.*import" "$stage_file"
# Stage returns or yields core types
grep -E "-> |return |yield " "$stage_file" | grep -E "[A-Z][a-zA-Z]+(Result|Report|State|Score)"
```

### Pattern: Function -> Return Value Usage

**Check:** Is the function's return value actually used by callers?

```bash
# Find all call sites
grep -rn "${func_name}(" src/ --include="*.py" | grep -v "def ${func_name}"
# Check if return value is assigned (not discarded)
grep -rn "${func_name}(" src/ --include="*.py" | grep -v "def ${func_name}" | grep -E "=.*${func_name}\(|return.*${func_name}\("
```

**Red flags:**
```python
# Return value ignored:
process_repo(repo_path)  # No assignment, return value lost

# Return value assigned but never used:
result = analyze(repo)
print("Done")  # result never referenced again
```

### Pattern: Model -> Serialization

**Check:** Are Pydantic models actually serialized/deserialized?

```bash
# Model used with .model_dump() or .model_validate()
grep -r "${model_name}\.model_dump\|${model_name}\.model_validate\|${model_name}\.json()\|${model_name}\.dict()" src/ --include="*.py"
# Model used with json.dumps or yaml.dump
grep -r "${model_name}" src/ --include="*.py" | grep -E "json\.(dumps|dump)|yaml\.(dump|safe_dump)"
```

### Pattern: Config -> Usage

**Check:** Are configuration values actually read and used?

```bash
# Config key is accessed
grep -r "config\[.*${key}\]\|config\.${key}\|settings\.${key}" src/ --include="*.py"
# Environment variable is read
grep -r "os\.environ\[.*${var}\]\|os\.getenv.*${var}\|env\.${var}" src/ --include="*.py"
```

---

## Anti-Pattern Quick Reference

| Pattern | Detection | Severity | Notes |
| ------- | --------- | -------- | ----- |
| TODO/FIXME comments | `grep -E "TODO\|FIXME"` | WARNING | May be intentional deferred work |
| Placeholder text | `grep -i "coming soon\|placeholder"` | BLOCKER | Should never ship |
| Empty function body | `pass` / `...` / `return None` | BLOCKER | No implementation |
| Identity function | `return input` | WARNING | May be intentional passthrough |
| Log-only function | Body is only `print()`/`logger.` | WARNING | Missing real logic |
| Catch-all dict | `data: dict = {}` | WARNING | Probably needs real fields |
| Always-true assertion | `assert True` | BLOCKER | Test proves nothing |
| Skipped test | `pytest.skip()` | WARNING | Test not exercised |
| Bare except | `except: pass` | WARNING | Swallows all errors silently |
| Hardcoded return | `return 42` / `return "ok"` | WARNING | Check if dynamic expected |
| Unused import | Import with no usage | INFO | Dead code |
| Dead function | Function with no callers | WARNING | May be orphaned |

---

## Checklist for Verifiers

For each artifact, run through:

### Python Module Checklist
- [ ] File exists at expected path
- [ ] Part of a proper package (parent has `__init__.py`)
- [ ] Has real functions/classes (not just imports or pass)
- [ ] No placeholder text or TODO stubs in production code
- [ ] Functions have real bodies with logic
- [ ] Imported by at least one other module
- [ ] Exported symbols are actually called somewhere

### Test File Checklist
- [ ] File exists in proper test directory
- [ ] Contains `test_` prefixed functions
- [ ] Tests have real assertions (not `assert True` or `pass`)
- [ ] Tests import the module under test
- [ ] Tests actually exercise the code (not just import it)

### CLI Command Checklist
- [ ] Command is registered with `@app.command()`
- [ ] Command has real body (not just echo/print/pass)
- [ ] Command calls core logic functions
- [ ] Command handles expected arguments
- [ ] Command is reachable from the main CLI entry point

### Wiring Checklist
- [ ] CLI -> Stage: Command calls stage functions
- [ ] Stage -> Core: Stage uses core modules and types
- [ ] Function -> Caller: Return values are used (not discarded)
- [ ] Model -> IO: Models are serialized/deserialized (not just defined)
- [ ] Config -> Code: Config values are actually read and used
