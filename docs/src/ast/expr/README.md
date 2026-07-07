# Expression Nodes

## All 18 Constructors

| nix-ast tag | Fields | Description |
|-------------|--------|-------------|
| `Abs` | `params: Params`, `body: Expr` | Function abstraction (lambda) |
| `App` | `func: Expr`, `arg: Expr` | Function application |
| `Assert` | `cond: Expr`, `body: Expr` | Assertion `assert cond; body` |
| `Binary` | `op: Text`, `left: Expr`, `right: Expr` | Binary operator |
| `Constant` | `contents: Atom` | Atomic constant wrapper |
| `EnvPath` | `contents: FilePath` | Search-path `<nixpkgs>` |
| `HasAttr` | `expr: Expr`, `attrPath: AttrPath` | Has-attribute check `set ? attr` |
| `If` | `cond: Expr`, `thenExpr: Expr`, `elseExpr: Expr` | Conditional |
| `Let` | `bindings: [Binding]`, `body: Expr` | Let bindings |
| `List` | `contents: [Expr]` | List `[ ... ]` |
| `LiteralPath` | `contents: FilePath` | Relative/absolute path `./foo.nix` |
| `Select` | `defaultValue: Maybe Expr`, `expr: Expr`, `selectPath: AttrPath` | Attribute selection `set.attr or default` |
| `Set` | `recursive: Bool`, `bindings: [Binding]` | Attribute set `{ ... }` |
| `Str` | `contents: String` | String expression (wraps `String`) |
| `Sym` | `contents: VarName` | Variable reference |
| `SynHole` | `contents: VarName` | Syntax hole/placeholder |
| `Unary` | `op: Text`, `arg: Expr` | Unary operator |
| `With` | `namespace: Expr`, `body: Expr` | With expression `with pkgs; ...` |

## Node Hierarchy

```
Expr
├── Abs
├── App
├── Assert
├── Binary
├── Constant    → wraps Atom (Int, Float, Bool, Null, Uri)
├── EnvPath
├── HasAttr
├── If
├── Let
├── List
├── LiteralPath
├── Select
├── Set
├── Str         → wraps String (DoubleQuoted / Indented)
├── Sym
├── SynHole
├── Unary
└── With
```

## Pages

### Primitive Expressions
- [SynHole](./syn-hole.md) — syntax hole (nix-ast specific)
- [EnvPath](./env-path.md) — `<nixpkgs>` search path
- [LiteralPath](./literal-path.md) — `./foo.nix` path
- [HasAttr](./has-attr.md) — `set ? attr` check

### Function & Application
- [Abs](./abs.md) — lambda abstraction
- [App](./app.md) — function application

### Control Flow
- [Assert](./assert.md) — assertion
- [If](./if.md) — conditional

### Data Structures
- [List](./list.md) — list literal
- [Set](./set.md) — attribute set
- [Select](./select.md) — attribute selection

### Bindings & Scope
- [Let](./let.md) — local bindings
- [With](./with.md) — bring set into scope

### Operations
- [Binary](./binary.md) — binary operators
- [Unary](./unary.md) — unary operators

### References & Constants
- [Sym](./sym.md) — variable reference
- [Constant](./constant.md) — atom wrapper
- [Str](./str.md) — string expression

## See Also

- [Operators](../operators.md) — Binary and unary operator reference
- [Atom](../atom/README.md) — constant values
- [Binding](../binding/README.md) — let/set bindings
- [Params](../params/README.md) — function parameters