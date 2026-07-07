# CLI

```
nix-ast - Nix AST tool

Usage: nix-ast COMMAND
  Parse and generate Nix expressions via hnix

Available commands:
  parse    Parse a Nix expression to AST
  render   Generate Nix expression from AST

Options:
  -h, --help     Show this help text
  -v, --version  Show version
```

## Parse

Parse a Nix expression to AST.

```
Usage: nix-ast parse [--expr EXPR] [--file FILE]
  -e, --expr EXPR       Nix expression string
  -f, --file FILE       Input file (default: stdin)
```

### Examples

```bash
# Parse a file
nix-ast parse -f ./config.nix

# Parse from stdin
echo '{ x = 1; }' | nix-ast parse

# Parse from expression string
nix-ast parse --expr '{ x = 1; }'

# Save to file
nix-ast parse -f ./config.nix > ast.json
```

### Output Format

JSON attribute set representing the AST:

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

## Render

Generate Nix expression from AST.

```
Usage: nix-ast render [--json JSON] [--file FILE]
  -j, --json JSON       AST in JSON format
  -f, --file FILE       Input file (default: stdin)
```

### Examples

```bash
# Render from file
nix-ast render -f ast.json

# Render from string
nix-ast render --json '{"tag":"Set","recursive":false,"bindings":[...]}'

# Pipe from parse
nix-ast parse -f ./config.nix | nix-ast render

# Save rendered output
nix-ast render -f ast.json > output.nix
```

### Output Format

Formatted Nix expression:

```nix
{
  x = 1;
}
```

## Shell Workflow

```bash
# Parse, transform via jq, and render
nix-ast parse -f ./config.nix \
  | jq '...' \
  | nix-ast render > output.nix

# Validate AST
nix-ast parse --expr '{ x = 1; }' | jq '.tag'  # => "Set"
```
