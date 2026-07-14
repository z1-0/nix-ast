# Plain (Antiquoted)

Literal value in an `Antiquoted` node. Constructor of `Antiquoted`, polymorphic in the content type.

## Definition

```
Plain v
```

## Fields

| Field      | Type | Description                                                              |
| ---------- | ---- | ------------------------------------------------------------------------ |
| `contents` | `v`  | The literal value: `Text` in string parts, `String` node in `DynamicKey` |

## Description

`Plain` represents a literal value that is not an antiquotation. In a string like `"hello ${world}"`, the `"hello "` part is a `Plain` node with text content.

When used inside `DynamicKey` (as `Antiquoted String`), `Plain` wraps a `String` AST node (`DoubleQuoted` / `Indented`) instead of plain text. Use `mkPlain` for this case.

## Nix Source ↔ AST

### Antiquoted Text (string parts)

```nix
# Nix
"hello "

# AST (part of DoubleQuoted contents)
{ "tag": "Plain", "contents": "hello " }
```

### Antiquoted String (DynamicKey)

```nix
# Nix
{ "foo bar" = 1; }

# AST (part of DynamicKey contents)
{ "tag": "Plain", "contents": { "tag": "DoubleQuoted", "contents": [...] } }
```

## Related

- [Antiquoted](./antiquoted.md): embedded expression
- [EscapedNewline](./escaped-newline.md): escaped newline in indented strings
- [String](../string/README.md): `DoubleQuoted` / `Indented` containers

## Nix Library Access

```nix
syntax.mkPlain "hello "       # text content (string parts)
syntax.mkPlain (syntax.mkDoubleQuoted [...])  # String node content (DynamicKey)
```
