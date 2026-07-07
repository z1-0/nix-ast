# API Reference

Functions for parsing, constructing, matching, and transforming Nix AST nodes.

## Overview

| Function area | Description |
|---------------|-------------|
| **Parse / Render** | Convert between Nix source code and structured AST |
| **Constructors** | Build AST nodes with runtime type validation |
| **Pattern Matching** | Tag-based dispatch on node types |
| **Traversal** | Walk, transform, and collect nodes in the tree |

## Pages

| Page | Description |
|------|-------------|
| [Core Functions](./core-functions.md) | `parse`, `render`, `toAST` — convert Nix ↔ AST |
| [syntax — Constructors & Predicates](./syntax.md) | `mk*` builders and `is*` tag checks for all node types |
| [match — Pattern Matching](./match.md) | Type-safe tag dispatch with `match ast { ... }` |
| [traversal — Tree Operations](./traversal.md) | `children`, `rebuild`, `transform`, `universe`, `contexts` |

## Quick Example

```nix
# Parse, transform, and render
ast = lib.parse pkgs ./file.nix;
transformed = lib.traversal.transform (node:
  if lib.syntax.isConstant node && lib.syntax.isInt node.contents then
    lib.syntax.mkConstant (lib.syntax.mkInt (node.contents.contents * 2))
  else node
) ast;
lib.render pkgs transformed
```

See also [CLI Reference](../cli.md) for the `nix-ast parse` / `nix-ast render` command-line tool.
