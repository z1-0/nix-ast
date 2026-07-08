# Str (String Expression)

## Definition

```
Str String
```

## Fields

| Field      | Type     | Description                                        |
| ---------- | -------- | -------------------------------------------------- |
| `contents` | `String` | The string contents (`DoubleQuoted` or `Indented`) |

## Description

`Str` is the expression-level node for strings. It wraps a `String` node which contains the actual string parts (plain text, antiquotations, escaped newlines).

## Nix Source ↔ AST

### Double-Quoted String

```nix
# Nix
"hello ${world}"

# AST
{
  "tag": "Str",
  "contents": {
    "tag": "DoubleQuoted",
    "contents": [
      { "tag": "Plain", "contents": "hello " },
      { "tag": "Antiquoted", "contents": { "tag": "Sym", "contents": "world" } }
    ]
  }
}
```

### Indented String

```nix
# Nix
''
  hello
  world
''

# AST
{
  "tag": "Str",
  "contents": {
    "tag": "Indented",
    "indent": 2,
    "parts": [
      { "tag": "Plain", "contents": "hello\nworld" }
    ]
  }
}
```

## Related

- [String](../string/README.md) — `DoubleQuoted` and `Indented` constructors
- [Antiquoted](../antiquoted/README.md) — `Plain`, `Antiquoted`, `EscapedNewline` parts

## Nix Library Access

```nix
syntax.mkStr (syntax.mkDoubleQuoted [syntax.mkPlain "hello"])
syntax.mkStr (syntax.mkIndented 2 [syntax.mkPlain "hello\nworld"])
```
