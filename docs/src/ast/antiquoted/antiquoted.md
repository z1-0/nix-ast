# Antiquoted (Embedded Expression)

Embedded expression inside a string. Constructor of `Antiquoted`.

## Definition

```
Antiquoted Expr
```

## Fields

| Field      | Type   | Description                                         |
| ---------- | ------ | --------------------------------------------------- |
| `contents` | `Expr` | The embedded expression to evaluate and interpolate |

## Description

`Antiquoted` represents an `${...}` expression inside a string. The contained `Expr` is evaluated and its result is converted to a string for interpolation.

## Nix Source ↔ AST

```nix
# Nix
"hello ${name}"

# AST (part of DoubleQuoted contents)
{
  "tag": "Antiquoted",
  "contents": { "tag": "Sym", "contents": "name" }
}
```

### Complex Antiquotation

```nix
# Nix
"${if cond then "yes" else "no"}"

# AST
{
  "tag": "Antiquoted",
  "contents": {
    "tag": "If",
    "cond": { "tag": "Sym", "contents": "cond" },
    "thenExpr": { "tag": "Str", ... },
    "elseExpr": { "tag": "Str", ... }
  }
}
```

## Related

- [Plain](./plain.md): literal text
- [EscapedNewline](./escaped-newline.md): escaped newline
- [String](../string/README.md): containers

## Nix Library Access

```nix
syntax.mkAntiquoted (syntax.mkSym "name")
syntax.mkAntiquoted (syntax.mkIf cond thenExpr elseExpr)
```
