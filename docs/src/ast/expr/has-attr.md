# HasAttr (Has Attribute)

## Definition

```
HasAttr { expr :: Expr, attrPath :: AttrPath }
```

## Fields

| Field | Type | Description |
|-------|------|-------------|
| `expr` | `Expr` | The expression to check (typically a set) |
| `attrPath` | `AttrPath` | The attribute path to check for |

## Description

`HasAttr` represents the `?` operator in Nix, which checks whether an attribute exists in a set. Returns a boolean.

## Nix Source ↔ AST

```nix
# Nix
set ? attr

# AST
{
  "tag": "HasAttr",
  "expr": { "tag": "Sym", "contents": "set" },
  "attrPath": [
    { "tag": "StaticKey", "contents": "attr" }
  ]
}
```

```nix
# Nix
set ? a.b.c

# AST
{
  "tag": "HasAttr",
  "expr": { "tag": "Sym", "contents": "set" },
  "attrPath": [
    { "tag": "StaticKey", "contents": "a" },
    { "tag": "StaticKey", "contents": "b" },
    { "tag": "StaticKey", "contents": "c" }
  ]
}
```

## Related

- [AttrPath](./../attr-path.md) — attribute path structure
- [Select](./select.md) — attribute selection (with default)

## Nix Library Access

```nix
syntax.mkHasAttr (syntax.mkSym "set") [syntax.mkStaticKey "attr"]
```