# Operators

## Binary Operators

| Operator | Description               | Example    |
| -------- | ------------------------- | ---------- |
| `==`     | Equality                  | `x == y`   |
| `!=`     | Inequality                | `x != y`   |
| `<`      | Less than                 | `x < y`    |
| `<=`     | Less than or equal        | `x <= y`   |
| `>`      | Greater than              | `x > y`    |
| `>=`     | Greater than or equal     | `x >= y`   |
| `&&`     | Logical AND               | `x && y`   |
| `\|\|`   | Logical OR                | `x \|\| y` |
| `->`     | Implication               | `x -> y`   |
| `//`     | Set update/merge          | `x // y`   |
| `+`      | Addition                  | `x + y`    |
| `-`      | Subtraction               | `x - y`    |
| `*`      | Multiplication            | `x * y`    |
| `/`      | Division                  | `x / y`    |
| `++`     | List/string concatenation | `x ++ y`   |

### Example

```nix
# Nix source
x + y

# AST
{
  "tag": "Binary",
  "op": "+",
  "left": { "tag": "Sym", "contents": "x" },
  "right": { "tag": "Sym", "contents": "y" }
}
```

## Unary Operators

| Operator | Description      | Example |
| -------- | ---------------- | ------- |
| `-`      | Numeric negation | `-x`    |
| `!`      | Logical NOT      | `!x`    |

### Example

```nix
# Nix source
!x

# AST
{
  "tag": "Unary",
  "op": "!",
  "arg": { "tag": "Sym", "contents": "x" }
}
```

## Special Operators

| Operation            | nix-ast node |
| -------------------- | ------------ |
| Function application | `App`        |
| Attribute selection  | `Select`     |
| Has attribute        | `HasAttr`    |

## Nix Library Access

```nix
syntax.mkBinary "+" (syntax.mkSym "x") (syntax.mkSym "y")
syntax.mkUnary "!" (syntax.mkSym "x")
syntax.mkBinary "==" (syntax.mkInt 1) (syntax.mkInt 1)
syntax.mkBinary "//" (syntax.mkSym "a") (syntax.mkSym "b")
syntax.mkBinary "++" (syntax.mkSym "xs") (syntax.mkSym "ys")
```
