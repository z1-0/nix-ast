# Antiquoted

## Constructors

| Constructor | Fields | Description |
|-------------|--------|-------------|
| `Plain` | `contents: Text` | Literal text |
| `Antiquoted` | `contents: Expr` | Embedded expression `${...}` |
| `EscapedNewline` | (none) | Escaped newline `\` in indented strings |

## Description

`Antiquoted` represents string parts: literal text or interpolated expressions.

A string like `"hello ${x} world"` becomes a list:
`[Plain "hello ", Antiquoted (Sym "x"), Plain " world"]`

## Pages

- [Plain](./plain.md)
- [Antiquoted](./antiquoted.md)
- [EscapedNewline](./escaped-newline.md)

## Related

- [String](../string/README.md) — `DoubleQuoted` / `Indented` containers
- [Str](../expr/str.md) — expression wrapper

## Nix Library Access

```nix
syntax.mkPlain "hello"
syntax.mkAntiquoted (syntax.mkSym "x")
syntax.mkEscapedNewline
```