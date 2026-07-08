# AST Reference

Complete reference for every node type in the Nix AST, organized by type hierarchy (as defined in `Types.hs`).

## Node Types

| Type                                 | Description                                              |
| ------------------------------------ | -------------------------------------------------------- |
| [Expr](./expr/README.md)             | The main expression tree (Abs, App, Binary, ...)         |
| [Atom](./atom/README.md)             | Primitive constant values (Bool, Float, Int, Null, Uri)  |
| [VarName](./var-name.md)             | Identifier name                                          |
| [AttrPath](./attr-path.md)           | Non-empty list of `KeyName` for attribute paths          |
| [Binding](./binding/README.md)       | Left-hand side of attribute bindings (Inherit, NamedVar) |
| [KeyName](./key-name/README.md)      | Attribute path components (StaticKey, DynamicKey)        |
| [Operators](./operators.md)          | Binary and unary operators                               |
| [Params](./params/README.md)         | Function parameter definitions (Param, ParamSet)         |
| [String](./string/README.md)         | String literal contents (DoubleQuoted, Indented)         |
| [Antiquoted](./antiquoted/README.md) | String parts with interpolation                          |

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
