# Assert

## Definition

```
Assert { cond :: Expr, body :: Expr }
```

## Fields

| Field  | Type   | Description                                |
| ------ | ------ | ------------------------------------------ |
| `cond` | `Expr` | Condition that must evaluate to `true`     |
| `body` | `Expr` | Expression to evaluate if assertion passes |

## Nix Source ↔ AST

```nix
# Nix
assert x > 0; x + 1

# AST
{
  "tag": "Assert",
  "cond": {
    "tag": "Binary",
    "op": ">",
    "left": { "tag": "Sym", "contents": "x" },
    "right": { "tag": "Constant", "contents": { "tag": "Int", "contents": 0 } }
  },
  "body": {
    "tag": "Binary",
    "op": "+",
    "left": { "tag": "Sym", "contents": "x" },
    "right": { "tag": "Constant", "contents": { "tag": "Int", "contents": 1 } }
  }
}
```

## Nix Library Access

```nix
syntax.mkAssert cond body
```
