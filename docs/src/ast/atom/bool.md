# Bool (Boolean Atom)

## Definition

```
Bool Bool
```

## Fields

| Field      | Type   | Description       |
| ---------- | ------ | ----------------- |
| `contents` | `Bool` | `True` or `False` |

## Nix Source ↔ AST

```nix
# Nix
true

# AST (wrapped in Constant)
{
  "tag": "Constant",
  "contents": { "tag": "Bool", "contents": true }
}
```

```nix
# Nix
false

# AST (wrapped in Constant)
{
  "tag": "Constant",
  "contents": { "tag": "Bool", "contents": false }
}
```

## Related

- [Constant](./../expr/constant.md): wrapper for atoms in expressions

## Nix Library Access

```nix
syntax.mkBool true
syntax.mkBool false
syntax.mkConstant (syntax.mkBool true)
```
