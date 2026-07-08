# Binding

## Constructors

| Constructor | Fields                                  | Description                  |
| ----------- | --------------------------------------- | ---------------------------- |
| `Inherit`   | `scope: Maybe Expr`, `names: [VarName]` | Inherit variables from scope |
| `NamedVar`  | `attrPath: AttrPath`, `value: Expr`     | Named variable binding       |

## Description

Bindings are used in `Let` expressions and `Set` (attribute set) expressions. They associate names with values.

## Pages

- [Inherit](./inherit.md)
- [NamedVar](./named-var.md)

## Related

- [Let](../expr/let.md)
- [Set](../expr/set.md)
- [AttrPath](../attr-path.md)
- [VarName](../var-name.md)

## Nix Library Access

```nix
syntax.mkInherit null ["x" "y"]
syntax.mkInherit (syntax.mkSym "pkgs") ["vim" "git"]
syntax.mkNamedVar [syntax.mkStaticKey "x"] (syntax.mkInt 1)
```
