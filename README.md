# nix-ast

> A Nix library that parses, inspects, transforms, and evaluates Nix Abstract Syntax Trees (AST) using Haskell's [hnix](https://github.com/haskell-nix/hnix) parser.

`nix-ast` provides the full Nix AST API in Nix itself (via IFD, Import From Derivation) and uses hnix's Haskell parser and evaluator internally. Parse any Nix expression into a structured AST, traverse and transform it with pure Nix functions, render it back to source code, or evaluate it, all from within your Nix expressions.

---

## Features

| Feature                       | Description                                                                            |
| ----------------------------- | -------------------------------------------------------------------------------------- |
| **Parse**                     | Parse any Nix expression (file, string, or stdin) into a structured, typed AST         |
| **Render**                    | Convert an AST back to formatted, importable Nix code                                  |
| **Eval**                      | Evaluate ASTs using hnix's evaluator and get the results as JSON values                |
| **toAST**                     | Convert native Nix values (ints, strings, lists, attrsets) to AST nodes (pure, no IFD) |
| **fromAST**                   | Convert an AST back to a native Nix value, the inverse of `toAST` (pure, no IFD)       |
| **Pattern Matching**          | Type-safe tag-based dispatch with `match ast { Tag = handler; _ = fallback; }`         |
| **Traversal**                 | Recursive `transform`, `rewrite`, `universe`, `children`/`rebuild`, and `contexts`     |
| **Type-checked Constructors** | All `mk*` builders validate argument types at runtime with descriptive error messages  |
| **CLI Tool**                  | `nix-ast eval` / `nix-ast parse` / `nix-ast render` for shell/pipe workflows           |

---

## Quick Start

### Using the Nix Library (Flake)

Add `nix-ast` to your flake inputs:

```nix
inputs.nix-ast.url = "github:z1-0/nix-ast";
```

The library provides three main API groups via `inputs.nix-ast.lib`:

| API                                      | Description                                   |
| ---------------------------------------- | --------------------------------------------- |
| `lib.parse` `lib.render` `lib.eval`      | IFD-based: bridge to hnix's parser/evaluator  |
| `lib.toAST` `lib.fromAST`                | Pure Nix: convert between Nix values and ASTs |
| `lib.match` `lib.syntax` `lib.traversal` | Work with AST nodes after construction        |

```nix
# Parse -> Transform -> Render
asts = lib.parse pkgs [./config.nix];
transformed = lib.traversal.transform (node: ...) (builtins.head asts);
outPaths = lib.render pkgs [transformed];
config = import (builtins.head outPaths);

# Parse -> Evaluate (skip rendering)
result = lib.eval pkgs asts;
```

### CLI

```bash
# Parse from expression string
nix-ast parse --expr '{ x = 1; }' > ast.json

# Parse files from stdin (one path per line)
echo ./config.nix | nix-ast parse > ast.json

# Render AST back to Nix
nix-ast render --json '{"tag":"Set","recursive":false,"bindings":[...]}'

# Render batch to output directory
nix-ast render < asts.json --out-dir ./out

# Evaluate AST using hnix
nix-ast eval --json '{"tag":"Constant","contents":{"tag":"Int","contents":42}}'

# Pipe workflow: parse -> eval
nix-ast parse --expr '{ x = 1 + 2; }' | nix-ast eval
```

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                nix-ast                                  │
│                                                         │
│  lib.parse   lib.render   lib.eval                      │
│       │           │           │                         │
│       ▼           ▼           ▼                         │
│  ┌──────────────────────────────┐                       │
│  │  IFD: nix-ast CLI (Haskell)  │  <- hnix parser/eval  │
│  └──────────────────────────────┘                       │
│                                                         │
│  lib.toAST  lib.fromAST  (pure Nix, no IFD)             │
│  lib.match  lib.syntax  lib.traversal                   │
└─────────────────────────────────────────────────────────┘
```

`parse`/`render`/`eval` go through Haskell via IFD. `toAST`/`fromAST`/`match`/`syntax`/`traversal` run in pure Nix on the AST values.

## Installation

Use `nix-ast` as a CLI tool or as a Nix library.

### CLI (run directly, no installation)

```bash
# Run directly without installing
nix run github:z1-0/nix-ast -- parse --expr '{ x = 1; }'
```

### Nix library (via flake inputs)

```nix
# Add to your flake inputs
inputs.nix-ast.url = "github:z1-0/nix-ast";
```

See [Quick Start](#quick-start) for the library API (`lib.parse`, `lib.render`, ...).

### Binary Cache

Use the [Cachix](https://z1-0.cachix.org) cache to skip building from source: the binary is built against a **patched hnix 0.17**, so its derivation doesn't match nixpkgs' `hnix`, and nixpkgs' cache can't substitute it.

Quickest way to enable it:

```bash
cachix use z1-0
```

Or add it to your NixOS/home-manager config:

```nix
nix.settings = {
  substituters = [ "https://z1-0.cachix.org" ];
  trusted-public-keys = [ "z1-0.cachix.org-1:FS7lPgL0StRBOPrlu0RgdCL7LafUI23+U6Iivdw5QK8=" ];
};
```

## Learn more

- **[API Reference](https://z1-0.github.io/nix-ast/api/)**: parse, render, eval, construct, match, and traverse AST nodes
  - [Core Functions](https://z1-0.github.io/nix-ast/api/core-functions.html): `parse`, `render`, `eval`, `toAST`, `fromAST`
  - [Pattern Matching](https://z1-0.github.io/nix-ast/api/match.html): tag-based dispatch on node types
  - [Syntax](https://z1-0.github.io/nix-ast/api/syntax.html): runtime-validated constructors and predicates
  - [Traversal](https://z1-0.github.io/nix-ast/api/traversal.html): children, rebuild, transform, universe
- **[AST Reference](https://z1-0.github.io/nix-ast/ast/)**: every node type with fields, JSON representation, and examples
  - [Expr](https://z1-0.github.io/nix-ast/ast/expr/): 19 expression constructors
  - [Atom](https://z1-0.github.io/nix-ast/ast/atom/): primitive constants (Bool, Int, Float, Null, Uri)
  - [Binding](https://z1-0.github.io/nix-ast/ast/binding/): Inherit, NamedVar
  - [KeyName](https://z1-0.github.io/nix-ast/ast/key-name/): StaticKey, DynamicKey
  - [Params](https://z1-0.github.io/nix-ast/ast/params/): Param, ParamSet
  - [String](https://z1-0.github.io/nix-ast/ast/string/): DoubleQuoted, Indented
  - [Antiquoted](https://z1-0.github.io/nix-ast/ast/antiquoted/): Plain, Antiquoted, EscapedNewline
- **[CLI Reference](https://z1-0.github.io/nix-ast/cli.html)**: `nix-ast eval` / `nix-ast parse` / `nix-ast render`

## License

BSD-3-Clause: see [LICENSE](./LICENSE) for details.
