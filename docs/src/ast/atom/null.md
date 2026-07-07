# Null (Null Atom)

## Definition

```
Null
```

## Fields

None (nullary constructor).

## Nix Source ↔ AST

```nix
# Nix
null

# AST (wrapped in Constant)
{
  "tag": "Constant",
  "contents": { "tag": "Null" }
}
```

## Related

- [Constant](./../expr/constant.md) — wrapper for atoms in expressions

## Nix Library Access

```nix
syntax.mkNull
syntax.mkConstant syntax.mkNull
```