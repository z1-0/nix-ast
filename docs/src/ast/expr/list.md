# List

## Definition

```
List [Expr]
```

## Fields

| Field | Type | Description |
|-------|------|-------------|
| `contents` | `[Expr]` | List of element expressions |

## Nix Source ↔ AST

```nix
# Nix
[ 1 2 3 ]

# AST
{
  "tag": "List",
  "contents": [
    { "tag": "Constant", "contents": { "tag": "Int", "contents": 1 } },
    { "tag": "Constant", "contents": { "tag": "Int", "contents": 2 } },
    { "tag": "Constant", "contents": { "tag": "Int", "contents": 3 } }
  ]
}
```

```nix
# Nix
[ (x + 1) (y * 2) ]

# AST
{
  "tag": "List",
  "contents": [
    { "tag": "Binary", "op": "+", "left": { "tag": "Sym", "contents": "x" }, "right": { "tag": "Constant", "contents": { "tag": "Int", "contents": 1 } } },
    { "tag": "Binary", "op": "*", "left": { "tag": "Sym", "contents": "y" }, "right": { "tag": "Constant", "contents": { "tag": "Int", "contents": 2 } } }
  ]
}
```

## Nix Library Access

```nix
syntax.mkList [syntax.mkInt 1, syntax.mkInt 2, syntax.mkInt 3]
```