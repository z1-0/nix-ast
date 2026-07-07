# String

## Constructors

| Constructor | Fields | Description |
|-------------|--------|-------------|
| `DoubleQuoted` | `contents: [Antiquoted Text]` | Standard string `"..."` |
| `Indented` | `indent: Int`, `parts: [Antiquoted Text]` | Multi-line indented string `''...''` |

## Description

`String` represents the contents of a string literal (not the expression wrapper). The expression-level node is `Str` which wraps a `String`.

String parts are `Antiquoted Text` — either `Plain` text, `Antiquoted` expressions, or `EscapedNewline` (indented strings only).

## Pages

- [DoubleQuoted](./double-quoted.md)
- [Indented](./indented.md)

## String Parts (Antiquoted)

See [Antiquoted](../antiquoted/README.md) for:
- `Plain` — literal text
- `Antiquoted` — embedded expression `${...}`
- `EscapedNewline` — `\` newline in indented strings

## Related

- [Str](../expr/str.md) — expression wrapper
- [Antiquoted](../antiquoted/README.md) — string parts

## Nix Library Access

```nix
syntax.mkDoubleQuoted [syntax.mkPlain "hello"]
syntax.mkIndented 2 [syntax.mkPlain "hello\nworld"]
```