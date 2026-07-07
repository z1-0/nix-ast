# Float (Floating-Point Atom)

## Definition

```
Float Float
```

## Fields

| Field | Type | Description |
|-------|------|-------------|
| `contents` | `Float` | Double-precision floating-point number |

## Note

Nix itself does not have native floating-point literals. The `Float` atom exists in the AST but is not directly exposed in Nix source syntax. Floating-point numbers in Nix are typically represented as strings or rationals.

In nix-ast JSON AST, `Float` atoms appear wrapped in `Constant`:

```json
{
  "tag": "Constant",
  "contents": { "tag": "Float", "contents": 3.14 }
}
```

## Related

- [Constant](./../expr/constant.md) — wrapper for atoms in expressions

## Nix Library Access

```nix
syntax.mkFloat 3.14
syntax.mkConstant (syntax.mkFloat 3.14)
```