# Plain (Antiquoted Text)

Plain literal text part in a string. Constructor of `Antiquoted`.

## Definition

```
Plain Text
```

## Fields

| Field | Type | Description |
|-------|------|-------------|
| `contents` | `Text` | The literal text content |

## Description

`Plain` represents literal text in a string that is not an antiquotation. In a string like `"hello ${world}"`, the `"hello "` part is a `Plain` node.

## Nix Source ↔ AST

```nix
# Nix
"hello "

# AST (part of DoubleQuoted contents)
{ "tag": "Plain", "contents": "hello " }
```

## Related

- [Antiquoted](./antiquoted.md) — embedded expression
- [EscapedNewline](./escaped-newline.md) — escaped newline in indented strings
- [String](../string/README.md) — `DoubleQuoted` / `Indented` containers

## Nix Library Access

```nix
syntax.mkPlain "hello "
```