# Binary (Binary Operation)

## Definition

```
Binary { op :: Text, left :: Expr, right :: Expr }
```

## Fields

| Field | Type | Description |
|-------|------|-------------|
| `op` | `Text` | Operator symbol (e.g., `+`, `==`, `&&`) |
| `left` | `Expr` | Left operand |
| `right` | `Expr` | Right operand |

## Supported Operators

See [Operators](../operators.md) for the full list of binary operators.

## Nix Source ↔ AST

```nix
# Nix
x + y

# AST
{
  "tag": "Binary",
  "op": "+",
  "left": { "tag": "Sym", "contents": "x" },
  "right": { "tag": "Sym", "contents": "y" }
}
```

```nix
# Nix
{ a = 1; } // { b = 2; }

# AST
{
  "tag": "Binary",
  "op": "//",
  "left": { "tag": "Set", "recursive": false, "bindings": [...] },
  "right": { "tag": "Set", "recursive": false, "bindings": [...] }
}
```

## Nix Library Access

```nix
syntax.mkBinary "+" (syntax.mkSym "x") (syntax.mkSym "y")
syntax.mkBinary "//" set1 set2
```