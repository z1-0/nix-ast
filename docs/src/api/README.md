# API Reference

Functions for parsing, constructing, matching, and transforming Nix AST nodes.

## Overview

The API is organized into three conceptual layers:

| Layer                | Functions                      | Description                                                       |
| -------------------- | ------------------------------ | ----------------------------------------------------------------- |
| **IFD bridge**       | `parse`, `render`, `eval`      | Bridge to the Haskell parser/evaluator via Import From Derivation |
| **Value conversion** | `toAST`, `fromAST`             | Pure Nix conversion between Nix values and AST nodes              |
| **AST tools**        | `match`, `syntax`, `traversal` | Pattern matching, constructors, and tree operations               |

## Pages

| Page                                             | Description                                                |
| ------------------------------------------------ | ---------------------------------------------------------- |
| [Core Functions](./core-functions.md)            | `parse`, `render`, `eval`, `toAST`, `fromAST`              |
| [syntax: Constructors & Predicates](./syntax.md) | `mk*` builders and `is*` tag checks for all node types     |
| [match: Pattern Matching](./match.md)            | Type-safe tag dispatch with `match ast { ... }`            |
| [traversal: Tree Operations](./traversal.md)     | `children`, `rebuild`, `transform`, `universe`, `contexts` |

## How IFD Works

`parse`, `render`, and `eval` use `pkgs.runCommand` to create a derivation that:

1. Serializes the input (paths, ASTs) to a JSON file via `pkgs.writeText`
2. Runs the `nix-ast` CLI binary inside the derivation, piping the JSON file to stdin
3. Captures stdout as the derivation output
4. Reads back the output with `builtins.readFile` + `builtins.fromJSON`

This means these functions have IFD (Import From Derivation) semantics: they work in `nix build` and `nix eval` but are unavailable in restricted evaluation modes like `nix-instantiate --eval`.

## Quick Example

```nix
# Parse, transform, and render
asts = lib.parse pkgs [./file.nix];
transformed = lib.traversal.transform (node:
  if lib.syntax.isConstant node && lib.syntax.isInt node.contents then
    lib.syntax.mkConstant (lib.syntax.mkInt (node.contents.contents * 2))
  else node
) (builtins.head asts);
outPaths = lib.render pkgs [transformed];
builtins.head outPaths
```

See also [CLI Reference](../cli.md) for the `nix-ast eval` / `nix-ast parse` / `nix-ast render` command-line tool.
