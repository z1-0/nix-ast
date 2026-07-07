# nix-ast

> A Nix library for parsing, inspecting, and transforming Nix Abstract Syntax Tree (AST), powered by Haskell's [hnix](https://github.com/haskell-nix/hnix) parser.

`nix-ast` provides a pure-Nix interface (via IFD) to parse Nix code into a typed AST, traverse and transform it, and render it back to Nix code. It also includes a CLI tool for parsing and rendering Nix expressions.

---

## Features

| Feature                       | Description                                                                                 |
| ----------------------------- | ------------------------------------------------------------------------------------------- |
| **Parse**                     | Parse any Nix expression (file, string, or stdin) into a structured AST                     |
| **Render**                    | Convert an AST back to formatted Nix code                                                   |
| **toAST**                     | Convert native Nix values (ints, strings, lists, attrsets) to AST nodes                     |
| **Pattern Matching**          | Type-safe pseudo pattern matching on AST node tags                                          |
| **Traversal**                 | Recursive traversal, transformation, and universe operations with children/rebuild contract |
| **Type-checked Constructors** | Build AST nodes with runtime type validation                                                |
| **CLI Tool**                  | `nix-ast parse` / `nix-ast render` for shell/pipe workflows                                 |

---

## Quick Start

### Using the Nix Library (Flake)

```nix
lib = inputs.nix-ast.lib;

# Parse → Transform → Render
configFile = let
  ast = lib.parse pkgs ./config.nix;
  transformed = lib.traversal.transform (node: ...) ast;
in lib.render pkgs transformed;

# Import the generated file
config = import configFile;
```

### Using the CLI

```bash
# Parse a Nix file to AST
nix-ast parse -f ./config.nix > ast.json

# Parse from stdin
echo '{ x = 1; }' | nix-ast parse > ast.json

# Parse from expression string
nix-ast parse --expr '{ x = 1; }'

# Render AST back to Nix
nix-ast render -f ast.json

# Render from AST string
nix-ast render --json '{"tag":"Set","recursive":false,"bindings":[...]}'
```

---

## Installation

```bash
# Run directly without installing
nix run github:z1-0/nix-ast -- parse -f ./file.nix

# Or add to your flake inputs
inputs.nix-ast.url = "github:z1-0/nix-ast";
```

## Learn more

- **[API Reference](https://z1-0.github.io/nix-ast/api/)** — parse, render, construct, match, and traverse AST nodes
  - [Core Functions](https://z1-0.github.io/nix-ast/api/core-functions.html) — `parse`, `render`, `toAST`
  - [Pattern Matching](https://z1-0.github.io/nix-ast/api/match.html) — tag-based dispatch on node types
  - [Syntax](https://z1-0.github.io/nix-ast/api/syntax.html) — runtime-validated constructors and predicates
  - [Traversal](https://z1-0.github.io/nix-ast/api/traversal.html) — children, rebuild, transform, universe
- **[AST Reference](https://z1-0.github.io/nix-ast/ast/)** — every node type with fields, JSON representation, and examples
  - [Expr](https://z1-0.github.io/nix-ast/ast/expr/) — 19 expression constructors
  - [Atom](https://z1-0.github.io/nix-ast/ast/atom/) — primitive constants (Bool, Int, Float, Null, Uri)
  - [Binding](https://z1-0.github.io/nix-ast/ast/binding/) — Inherit, NamedVar
  - [KeyName](https://z1-0.github.io/nix-ast/ast/key-name/) — StaticKey, DynamicKey
  - [Params](https://z1-0.github.io/nix-ast/ast/params/) — Param, ParamSet
  - [String](https://z1-0.github.io/nix-ast/ast/string/) — DoubleQuoted, Indented
  - [Antiquoted](https://z1-0.github.io/nix-ast/ast/antiquoted/) — Plain, Antiquoted, EscapedNewline
- **[CLI Reference](https://z1-0.github.io/nix-ast/cli.html)** — `nix-ast parse` / `nix-ast render`

## License

BSD-3-Clause — see [LICENSE](./LICENSE) for details.
