# If (Conditional)

## Definition

```
If { cond :: Expr, thenExpr :: Expr, elseExpr :: Expr }
```

## Fields

| Field | Type | Description |
|-------|------|-------------|
| `cond` | `Expr` | Condition expression (must evaluate to boolean) |
| `thenExpr` | `Expr` | Expression when condition is `true` |
| `elseExpr` | `Expr` | Expression when condition is `false` |

## Nix Source ↔ AST

```nix
# Nix
if cond then 1 else 2

# AST
{
  "tag": "If",
  "cond": { "tag": "Sym", "contents": "cond" },
  "thenExpr": { "tag": "Constant", "contents": { "tag": "Int", "contents": 1 } },
  "elseExpr": { "tag": "Constant", "contents": { "tag": "Int", "contents": 2 } }
}
```

## Nix Library Access

```nix
syntax.mkIf cond thenExpr elseExpr
```