# Abs (Lambda Abstraction)

## Definition

```
Abs { params :: Params, body :: Expr }
```

## Fields

| Field    | Type     | Description                                        |
| -------- | -------- | -------------------------------------------------- |
| `params` | `Params` | Function parameters (single `Param` or `ParamSet`) |
| `body`   | `Expr`   | Function body expression                           |

## Nix Source ↔ AST

### Single Parameter

```nix
# Nix
x: x + 1

# AST
{
  "tag": "Abs",
  "params": { "tag": "Param", "contents": "x" },
  "body": {
    "tag": "Binary",
    "op": "+",
    "left": { "tag": "Sym", "contents": "x" },
    "right": { "tag": "Constant", "contents": { "tag": "Int", "contents": 1 } }
  }
}
```

### Parameter Set

```nix
# Nix
{ x, y ? 1 }: x + y

# AST
{
  "tag": "Abs",
  "params": {
    "tag": "ParamSet",
    "paramSetName": null,
    "variadic": false,
    "params": [
      ["x", null],
      ["y", { "tag": "Constant", "contents": { "tag": "Int", "contents": 1 } }]
    ]
  },
  "body": {
    "tag": "Binary",
    "op": "+",
    "left": { "tag": "Sym", "contents": "x" },
    "right": { "tag": "Sym", "contents": "y" }
  }
}
```

### Variadic Parameter Set

```nix
# Nix
{ x, ... }: x

# AST
{
  "tag": "Abs",
  "params": {
    "tag": "ParamSet",
    "paramSetName": null,
    "variadic": true,
    "params": [["x", null]]
  },
  "body": { "tag": "Sym", "contents": "x" }
}
```

## Nix Library Access

```nix
syntax.mkAbs (syntax.mkParam "x") (syntax.mkBinary "+" (syntax.mkSym "x") (syntax.mkInt 1))
syntax.mkAbs (syntax.mkParamSet null false [["x" null] ["y" null]]) body
```
