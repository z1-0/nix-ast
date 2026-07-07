# Select (Attribute Selection)

## Definition

```
Select { defaultValue :: Maybe Expr, expr :: Expr, selectPath :: AttrPath }
```

## Fields

| Field | Type | Description |
|-------|------|-------------|
| `defaultValue` | `Maybe Expr` | Default value if attribute not found (`Nothing` = no default, throws error) |
| `expr` | `Expr` | The set expression to select from |
| `selectPath` | `AttrPath` | The attribute path to select |

## Nix Source ↔ AST

### Without Default (throws if missing)
```nix
# Nix
set.attr

# AST
{
  "tag": "Select",
  "defaultValue": null,
  "expr": { "tag": "Sym", "contents": "set" },
  "selectPath": [{ "tag": "StaticKey", "contents": "attr" }]
}
```

### With Default (`or`)
```nix
# Nix
set.attr or "default"

# AST
{
  "tag": "Select",
  "defaultValue": { "tag": "Str", "contents": { "tag": "DoubleQuoted", "contents": [{ "tag": "Plain", "contents": "default" }] } },
  "expr": { "tag": "Sym", "contents": "set" },
  "selectPath": [{ "tag": "StaticKey", "contents": "attr" }]
}
```

### Nested Path
```nix
# Nix
set.a.b.c or 0

# AST
{
  "tag": "Select",
  "defaultValue": { "tag": "Constant", "contents": { "tag": "Int", "contents": 0 } },
  "expr": { "tag": "Sym", "contents": "set" },
  "selectPath": [
    { "tag": "StaticKey", "contents": "a" },
    { "tag": "StaticKey", "contents": "b" },
    { "tag": "StaticKey", "contents": "c" }
  ]
}
```

## Related

- [AttrPath](./../attr-path.md) — attribute path structure
- [HasAttr](./has-attr.md) — check if attribute exists

## Nix Library Access

```nix
syntax.mkSelect (syntax.mkSym "set") [syntax.mkStaticKey "attr"] null
syntax.mkSelect (syntax.mkSym "set") [syntax.mkStaticKey "attr"] (syntax.mkStr (syntax.mkDoubleQuoted [syntax.mkPlain "default"]))
```