# CLI

```
nix-ast - Nix AST tool

Usage: nix-ast COMMAND [-v|--version]

  nix-ast: Parse and generate Nix expressions

Available options:
  -h,--help                Show this help text
  -v,--version             Show version

Available commands:
  eval                     Evaluate AST JSON and output result
  parse                    Parse Nix expression to AST JSON
  render                   Render AST JSON to Nix source
```

The CLI has three subcommands: `eval`, `parse`, `render`. Each operates in two modes:

- **Direct mode**: supply input via `--expr` or `--json` flag for single-item operation
- **Batch mode**: pipe a JSON array through stdin for bulk processing (one item per array element)

When stdin is a TTY and no direct flag is given, the CLI shows the subcommand's help text instead of hanging.

---

## Eval

Evaluate AST values and output the results as JSON. This is the CLI equivalent of `nix eval` but operates on AST JSON rather than source code.

```
Usage: nix-ast eval [--json JSON]

  Evaluate AST JSON and output result

Available options:
  --json JSON              AST in JSON format
  -h,--help                Show this help text
```

**Modes:**

| Mode          | Flag          | Input source                | Output                      |
| ------------- | ------------- | --------------------------- | --------------------------- |
| Direct        | `--json JSON` | Single AST as JSON string   | Single JSON value to stdout |
| Batch (stdin) | _(none)_      | `[AST]` JSON array on stdin | `[a]` JSON array to stdout  |

**How it works:** Each AST is deserialized, evaluated using the built-in evaluator with basic filesystem effects, and the result is serialized to JSON.

**Error handling:** Parse errors, conversion errors, evaluation errors, and IO exceptions are all caught and reported with appropriate prefixes ("Decode error", "Conversion error", "Eval error").

### Examples

```bash
# Evaluate a single AST from a JSON string
nix-ast eval --json '{"tag":"Set","recursive":false,"bindings":[{"tag":"NamedVar","attrPath":[{"tag":"StaticKey","contents":"x"}],"value":{"tag":"Constant","contents":{"tag":"Int","contents":1}}}]}'

# Pipe ASTs from a file (JSON array, one element per line in the array)
cat asts.json | nix-ast eval

# Pipe from parse: parse then evaluate
nix-ast parse --expr '{ x = 1 + 2; }' | nix-ast eval
```

---

## Parse

Parse Nix source code into AST JSON.

```
Usage: nix-ast parse [--expr EXPR]

  Parse Nix expression to AST JSON

Available options:
  --expr EXPR              Nix expression string
  -h,--help                Show this help text
```

**Modes:**

| Mode          | Flag          | Input source                     | Output                       |
| ------------- | ------------- | -------------------------------- | ---------------------------- |
| Direct        | `--expr EXPR` | Single Nix expression string     | Single AST JSON to stdout    |
| Batch (stdin) | _(none)_      | `[FilePath]` JSON array on stdin | `[AST]` JSON array to stdout |

**How it works:**

- **Direct mode:** The expression string is parsed into an AST, converted to our `Expr` type, and serialized to JSON.
- **Batch mode:** Stdin is read as a JSON array of file paths. Each file is read concurrently using `mapConcurrently` with a semaphore limiting concurrency to 50. Each file is parsed separately; if any file fails, the entire command exits with an error.

### Examples

```bash
# Parse a single expression from string
nix-ast parse --expr '{ x = 1; }' > ast.json

# Parse multiple files from stdin (one path per JSON array element)
echo '["/path/to/a.nix", "/path/to/b.nix"]' | nix-ast parse > asts.json

# Pipe from jq for dynamic path selection
nix build 2>&1 | grep "error:" | jq -R -s -c 'split("\n") | map(select(length > 0))' | nix-ast parse
```

### Output Format

The AST is a JSON object with a `tag` field identifying the node type, plus type-specific fields:

```json
{
  "tag": "Set",
  "recursive": false,
  "bindings": [
    {
      "tag": "NamedVar",
      "attrPath": [{ "tag": "StaticKey", "contents": "x" }],
      "value": {
        "tag": "Constant",
        "contents": { "tag": "Int", "contents": 1 }
      }
    }
  ]
}
```

For a complete reference of all node types with their JSON shapes, see the [AST Reference](../ast/README.md).

---

## Render

Convert AST JSON back to formatted Nix source code.

```
Usage: nix-ast render [--json JSON] [--out-dir DIR]

  Render AST JSON to Nix source

Available options:
  --json JSON              AST in JSON format
  --out-dir DIR            Output directory for rendered files (default: stdout)
  -h,--help                Show this help text
```

**Modes:**

| Mode          | Flag                      | Input source                | Output                               |
| ------------- | ------------------------- | --------------------------- | ------------------------------------ |
| Direct        | `--json JSON`             | Single AST as JSON string   | Formatted Nix source to stdout       |
| Batch (stdin) | _(none)_, no `--out-dir`  | `[AST]` JSON array on stdin | `[Text]` JSON array to stdout        |
| Batch to disk | _(none)_, `--out-dir DIR` | `[AST]` JSON array on stdin | Files `0.nix`, `1.nix`, ... in `DIR` |

**How it works:** Each AST is deserialized and pretty-printed back to formatted Nix source code.

- **Direct mode (`--json` only, no `--out-dir`):** Single AST → single line of Nix source to stdout.
- **Batch to stdout (stdin only, no `--out-dir`):** Array of ASTs → JSON array of Nix source strings to stdout.
- **Batch to disk (stdin + `--out-dir`):** Array of ASTs → individual files named `<index>.nix` in the specified directory. Files are numbered sequentially starting from 0.
- **Forbidden combination:** `--json` + `--out-dir` is not supported and raises an error.

### Examples

```bash
# Render a single AST from string to stdout
nix-ast render --json '{"tag":"Set","recursive":false,"bindings":[...]}'

# Pipe from parse: parse then render back to source
nix-ast parse --expr '{ x = 1; }' | nix-ast render

# Render batch to individual files
cat asts.json | nix-ast render --out-dir ./rendered
# Creates: ./rendered/0.nix, ./rendered/1.nix, ...

# Render batch to stdout (as JSON array of strings)
cat asts.json | nix-ast render
```

### Output Format

```nix
{
  x = 1;
}
```

For list/multiline outputs, each AST is pretty-printed independently.

---

## Shell Workflow Examples

```bash
# Parse, transform via jq, and render back
nix-ast parse --expr '{ x = 1; }' \
  | jq '.bindings[0].value.contents.contents *= 2' \
  | nix-ast render

# Evaluate and query results
nix-ast parse --expr '{ inherit (builtins) map filter; }' | nix-ast eval | jq 'keys'

# Batch process multiple files
echo '["file1.nix", "file2.nix", "file3.nix"]' \
  | nix-ast parse \
  | nix-ast render --out-dir ./out
```
