# Constant (Atom Wrapper)

## Definition

```
Constant Atom
```

## Fields

| Field      | Type   | Description                                    |
| ---------- | ------ | ---------------------------------------------- |
| `contents` | `Atom` | The atomic value (Int, Float, Bool, Null, Uri) |

## Description

`Constant` wraps an `Atom` to make it a valid expression node. All literal values in Nix (integers, booleans, null, URIs) are represented as `Constant` containing an `Atom`.

## Nix Source ↔ AST

```nix
# Nix
42

# AST
{
  "tag": "Constant",
  "contents": { "tag": "Int", "contents": 42 }
}
```

```nix
# Nix
true

# AST
{
  "tag": "Constant",
  "contents": { "tag": "Bool", "contents": true }
}
```

```nix
# Nix
null

# AST
{
  "tag": "Constant",
  "contents": { "tag": "Null" }
}
```

## Related

- [Atom](../atom/README.md) — the wrapped atomic types (Int, Float, Bool, Null, Uri)
- See [Atoms](../atom/README.md) for atom constructors

## Nix Library Access

```nix
syntax.mkConstant (syntax.mkInt 42)
syntax.mkConstant (syntax.mkBool true)
syntax.mkConstant syntax.mkNull
```
