# NamedVar (Named Variable Binding)

## Definition

```
NamedVar { attrPath :: AttrPath, value :: Expr }
```

## Fields

| Field | Type | Description |
|-------|------|-------------|
| `attrPath` | `AttrPath` | Attribute path (non-empty list of `KeyName`) |
| `value` | `Expr` | The bound expression |

## Nix Source ↔ AST

### Simple Binding
```nix
# Nix
x = 1;

# AST
{
  "tag": "NamedVar",
  "attrPath": [{ "tag": "StaticKey", "contents": "x" }],
  "value": { "tag": "Constant", "contents": { "tag": "Int", "contents": 1 } }
}
```

### Nested Path Binding
```nix
# Nix
a.b.c = 1;

# AST
{
  "tag": "NamedVar",
  "attrPath": [
    { "tag": "StaticKey", "contents": "a" },
    { "tag": "StaticKey", "contents": "b" },
    { "tag": "StaticKey", "contents": "c" }
  ],
  "value": { "tag": "Constant", "contents": { "tag": "Int", "contents": 1 } }
}
```

### Dynamic Key Binding
```nix
# Nix
let name = "foo"; in { ${name} = 1; }

# AST
{
  "tag": "NamedVar",
  "attrPath": [
    { "tag": "DynamicKey", "contents": {
        "tag": "Antiquoted",
        "contents": { "tag": "Sym", "contents": "name" }
      }
    }
  ],
  "value": { "tag": "Constant", "contents": { "tag": "Int", "contents": 1 } }
}
```

## Related

- [Inherit](./inherit.md) — inherit binding
- [AttrPath](./../attr-path.md) — attribute path structure
- [KeyName](../key-name/README.md) — `StaticKey` / `DynamicKey`
- [Let](./../expr/let.md) — let expressions
- [Set](./../expr/set.md) — attribute sets

## Nix Library Access

```nix
syntax.mkNamedVar [syntax.mkStaticKey "x"] (syntax.mkInt 1)
syntax.mkNamedVar [syntax.mkStaticKey "a", syntax.mkStaticKey "b"] (syntax.mkInt 1)
```