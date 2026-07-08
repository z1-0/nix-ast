# Int (Integer Atom)

## Definition

```
Int Integer
```

## Fields

| Field      | Type      | Description                                         |
| ---------- | --------- | --------------------------------------------------- |
| `contents` | `Integer` | Arbitrary-precision integer (Nix uses 64-bit range) |

## Nix Source ↔ AST

```nix
# Nix
42

# AST (wrapped in Constant)
{
  "tag": "Constant",
  "contents": { "tag": "Int", "contents": 42 }
}
```

```nix
# Nix
-123

# AST (wrapped in Constant)
{
  "tag": "Constant",
  "contents": { "tag": "Int", "contents": -123 }
}
```

## Note

Nix integers are 64-bit signed. The `Integer` type is arbitrary precision but values are constrained to Nix's 64-bit range at runtime.

## Related

- [Constant](./../expr/constant.md) — wrapper for atoms in expressions

## Nix Library Access

```nix
syntax.mkInt 42
syntax.mkConstant (syntax.mkInt 42)
```
