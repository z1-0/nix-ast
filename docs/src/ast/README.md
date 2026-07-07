# AST Reference

Complete reference for every node type in the Nix AST, organized by type hierarchy (as defined in `Types.hs`).

## Type Aliases

| Type | Description |
|------|-------------|
| [VarName](./var-name.md) | Identifier name (`Text`) |
| [AttrPath](./attr-path.md) | Non-empty list of `KeyName` |
| [ParamSet](./param-set.md) | Map of parameter names to optional defaults |
| [Operators](./operators.md) | Binary (`==`, `+`, `//`, ...) and unary (`-`, `!`) operators |

## Algebraic Types

| Type | Constructors | Role |
|------|-------------|------|
| [Expr](./expr/README.md) | 18 constructors (Abs, App, Binary, ...) | The main expression tree |
| [Atom](./atom/README.md) | Bool, Float, Int, Null, Uri | Primitive constant values |
| [Binding](./binding/README.md) | Inherit, NamedVar | Left-hand side of attribute bindings |
| [KeyName](./key-name/README.md) | StaticKey, DynamicKey | Attribute path components |
| [Params](./params/README.md) | Param, ParamSet | Function parameter definitions |
| [String](./string/README.md) | DoubleQuoted, Indented | String literal contents |
| [Antiquoted](./antiquoted/README.md) | Plain, Antiquoted, EscapedNewline | String parts with interpolation |

## Quick Start

```nix
# Parse Nix code into AST
ast = lib.parse pkgs ./example.nix;

# Inspect the expression type
lib.match ast {
  Set = { recursive, bindings }: "attribute set";
  List = { contents }: "list of ${toString (builtins.length contents)} items";
  _ = _: "other expression";
};

# Transform all integer constants
transformed = lib.traversal.transform (node:
  if node.tag == "Constant" && node.contents.tag == "Int"
  then lib.syntax.mkConstant (lib.syntax.mkInt (node.contents.contents * 2))
  else node
) ast;

# Render back to Nix code
lib.render pkgs transformed
```
