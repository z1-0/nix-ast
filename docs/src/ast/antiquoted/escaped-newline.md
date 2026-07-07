# EscapedNewline (Escaped Newline)

Escaped newline in indented strings. Constructor of `Antiquoted`.

## Definition

```
EscapedNewline
```

## Fields

None (nullary constructor).

## Description

`EscapedNewline` represents a backslash-newline sequence (`\` followed by newline) in an indented string (`''...''`). It allows splitting a long logical line across multiple physical lines without inserting a newline in the resulting string.

## Nix Source ↔ AST

```nix
# Nix
''
  this is a \
  continued line
''

# AST (part of Indented parts)
{
  "tag": "EscapedNewline"
}
```

The resulting string content is `"this is a continued line"` (no newline between "a" and "continued").

## Related

- [Plain](./plain.md) — literal text
- [Antiquoted](./antiquoted.md) — embedded expression
- [Indented](./../string/indented.md) — indented string container

## Nix Library Access

```nix
syntax.mkEscapedNewline
```