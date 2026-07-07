# Indented (Multi-line String)

## Definition

```
Indented { indent :: Int, parts :: [Antiquoted Text] }
```

## Fields

| Field | Type | Description |
|-------|------|-------------|
| `indent` | `Int` | Indentation level (spaces stripped from each line) |
| `parts` | `[Antiquoted Text]` | List of string parts |

## Nix Source ↔ AST

### Simple Indented String
```nix
# Nix
''
  hello
  world
''

# String node
{
  "tag": "Indented",
  "indent": 2,
  "parts": [
    { "tag": "Plain", "contents": "hello\nworld" }
  ]
}
```

### With Antiquotation
```nix
# Nix
''
  hello
  ${name}
''

# String node
{
  "tag": "Indented",
  "indent": 2,
  "parts": [
    { "tag": "Plain", "contents": "hello\n" },
    { "tag": "Antiquoted", "contents": { "tag": "Sym", "contents": "name" } }
  ]
}
```

### Escaped Newline
```nix
# Nix
''
  first line \
  second line
''

# String node
{
  "tag": "Indented",
  "indent": 2,
  "parts": [
    { "tag": "Plain", "contents": "first line " },
    { "tag": "EscapedNewline" },
    { "tag": "Plain", "contents": "second line" }
  ]
}
```

## Expression Wrapper

```json
{
  "tag": "Str",
  "contents": { "tag": "Indented", "indent": 2, "parts": [...] }
}
```

## Related

- [DoubleQuoted](./double-quoted.md) — standard strings
- [Antiquoted](../antiquoted/README.md) — `Plain`, `Antiquoted`, `EscapedNewline` parts
- [Str](../expr/str.md) — expression wrapper

## Nix Library Access

```nix
syntax.mkIndented 2 [syntax.mkPlain "hello\nworld"]
```