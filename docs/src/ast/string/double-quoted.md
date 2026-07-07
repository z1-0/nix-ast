# DoubleQuoted (Standard String)

## Definition

```
DoubleQuoted [Antiquoted Text]
```

## Fields

| Field | Type | Description |
|-------|------|-------------|
| `contents` | `[Antiquoted Text]` | List of string parts |

## Nix Source ↔ AST

### Simple String
```nix
# Nix
"hello"

# String node
{
  "tag": "DoubleQuoted",
  "contents": [
    { "tag": "Plain", "contents": "hello" }
  ]
}
```

### With Antiquotation
```nix
# Nix
"hello ${name}"

# String node
{
  "tag": "DoubleQuoted",
  "contents": [
    { "tag": "Plain", "contents": "hello " },
    { "tag": "Antiquoted", "contents": { "tag": "Sym", "contents": "name" } }
  ]
}
```

## Expression Wrapper

The expression-level node is `Str` wrapping this:
```json
{
  "tag": "Str",
  "contents": { "tag": "DoubleQuoted", "contents": [...] }
}
```

## Related

- [Indented](./indented.md) — multi-line indented strings
- [Antiquoted](../antiquoted/README.md) — `Plain`, `Antiquoted`, `EscapedNewline` parts
- [Str](../expr/str.md) — expression wrapper

## Nix Library Access

```nix
syntax.mkDoubleQuoted [syntax.mkPlain "hello"]
syntax.mkDoubleQuoted [syntax.mkPlain "hello ", syntax.mkAntiquoted (syntax.mkSym "name")]
```