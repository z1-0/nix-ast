# Antiquoted

## Constructors

| Constructor | Fields | Description |
|-------------|--------|-------------|
| `Plain` | `contents: v` | Literal value — `Text` in string parts, `String` in `DynamicKey` |
| `Antiquoted` | `contents: Expr` | Embedded expression `${...}` |
| `EscapedNewline` | (none) | Escaped newline `\` in indented strings |

## Description

`Antiquoted` is polymorphic in the `Plain` constructor. It is used at two type arguments:
- **`Antiquoted Text`** — in string parts (`DoubleQuoted` / `Indented`), `Plain` wraps literal text.
- **`Antiquoted String`** — in `DynamicKey`, `Plain` wraps a `String` AST node (`DoubleQuoted` / `Indented`).

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
syntax.mkPlain "hello"       # text content (string parts)
syntax.mkAntiquoted (syntax.mkSym "x")
syntax.mkEscapedNewline
```