# AST Reference

Complete reference for every node type in the Nix AST, organized by type hierarchy as defined in [Types.hs](https://github.com/z1-0/nix-ast/blob/main/src/NixAST/Types.hs).

## Quick Overview

The AST is a sum type with 19 expression constructors and supporting types for atoms, bindings, keys, parameters, strings, and antiquoted parts. Every node has a `tag` field (a string identifying the constructor) plus constructor-specific fields.

## Node Types

| Type                                               | Description                                              |
| -------------------------------------------------- | -------------------------------------------------------- |
| [Expr](./expr/README.md)                           | The main expression tree — 19 constructors                |
| [Atom](./atom/README.md)                           | Primitive constant values (Bool, Float, Int, Null, Uri)   |
| [VarName](./var-name.md)                           | Identifier name (simple string)                            |
| [AttrPath](./attr-path.md)                         | Non-empty list of `KeyName` for attribute paths           |
| [Binding](./binding/README.md)                     | Left-hand side of attribute bindings (Inherit, NamedVar)  |
| [KeyName](./key-name/README.md)                    | Attribute path components (StaticKey, DynamicKey)         |
| [Operators](./operators.md)                        | Binary and unary operators                                |
| [Params](./params/README.md)                       | Function parameter definitions (Param, ParamSet)          |
| [String](./string/README.md)                       | String literal contents (DoubleQuoted, Indented)          |
| [Antiquoted](./antiquoted/README.md)               | String parts with interpolation                           |

## JSON Representation

Every node is serializable to/from JSON. The `tag` field identifies the constructor:

```json
{ "tag": "Constant", "contents": { "tag": "Int", "contents": 42 } }
```

This is the format used by the CLI for `nix-ast parse` output and `nix-ast render` input.

## Quick Start

```nix
# Parse Nix code into AST
asts = lib.parse pkgs [./example.nix];
ast = builtins.head asts;

# Inspect the expression type using match
lib.match ast {
  Set = { recursive, bindings }: "attribute set";
  List = { contents }: "list of ${toString (builtins.length contents)} items";
  _ = _: "other expression";
};

# Transform all integer constants: double their value
transformed = lib.traversal.transform (node:
  if node.tag == "Constant" && node.contents.tag == "Int"
  then lib.syntax.mkConstant (lib.syntax.mkInt (node.contents.contents * 2))
  else node
) ast;

# Render back to Nix code
outPaths = lib.render pkgs [transformed];
builtins.head outPaths
```
