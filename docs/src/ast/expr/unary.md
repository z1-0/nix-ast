# Unary (Unary Operation)

## Definition

```
Unary { op :: Text, arg :: Expr }
```

## Fields

| Field | Type | Description |
|-------|------|-------------|
| `op` | `Text` | Operator symbol (`-` or `!`) |
| `arg` | `Expr` | Operand expression |

## Supported Operators

See [Operators](../operators.md) for the full list of unary operators.

## Nix Source ↔ AST

```nix
# Nix
-x

# AST
{
  "tag": "Unary",
  "op": "-",
  "arg": { "tag": "Sym", "contents": "x" }
}
```

```nix
# Nix
!cond

# AST
{
  "tag": "Unary",
  "op": "!",
  "arg": { "tag": "Sym", "contents": "cond" }
}
```

## Nix Library Access

```nix
syntax.mkUnary "-" (syntax.mkSym "x")
syntax.mkUnary "!" (syntax.mkSym "cond")
```