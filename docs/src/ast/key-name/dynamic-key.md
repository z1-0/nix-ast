# DynamicKey (Dynamic Attribute Key)

## Definition

```
DynamicKey (Antiquoted String)
```

## Fields

| Field      | Type                | Description                              |
| ---------- | ------------------- | ---------------------------------------- |
| `contents` | `Antiquoted String` | A string that may contain antiquotations |

## Description

`DynamicKey` is used for attribute keys that are not static identifiers — either quoted strings like `"foo bar"` or antiquoted expressions like `${name}`. In Nix, any key in quotes or with antiquotation is parsed as a `DynamicKey`.

The contents is an `Antiquoted String`, meaning it can be:

- Plain string parts
- Antiquoted expressions
- Escaped newlines (in indented strings)

## Nix Source ↔ AST

### Quoted String Key

```nix
# Nix
{ "foo bar" = 1; }

# AST (key part)
{
  "tag": "DynamicKey",
  "contents": {
    "tag": "Plain",
    "contents": {
      "tag": "DoubleQuoted",
      "contents": [
        { "tag": "Plain", "contents": "foo bar" }
      ]
    }
  }
}
```

### Antiquoted Key

```nix
# Nix
let name = "foo"; in { ${name} = 1; }

# AST (key part)
{
  "tag": "DynamicKey",
  "contents": {
    "tag": "Antiquoted",
    "contents": { "tag": "Sym", "contents": "name" }
  }
}
```

## Related

- [StaticKey](./static-key.md) — static identifier keys
- [String](../string/README.md) — `DoubleQuoted` / `Indented` string nodes
- [Antiquoted](../antiquoted/README.md) — string parts
- [NamedVar](./../binding/named-var.md) — uses `AttrPath` of `KeyName`

## Nix Library Access

```nix
syntax.mkDynamicKey (syntax.mkAntiquoted (syntax.mkSym "name"))
# Plain + String variant (rare): syntax.mkDynamicKey (syntax.mkPlain (syntax.mkDoubleQuoted [...]))
```
