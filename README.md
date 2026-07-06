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
# Import the library
lib = inputs.nix-ast.lib;

# Example workflow: parse → transform → render
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

### Nix (Flake)

```bash
# Run directly without installing
nix run github:z1-0/nix-ast -- parse -f ./file.nix

# Or add to your flake inputs
inputs.nix-ast.url = "github:z1-0/nix-ast";
```

---

## Nix Library API

The library is exposed via `lib` in the flake output. All functions are IFD-based (Import From Derivation) because they invoke the Haskell CLI.

### Core Functions

| Function | Type                  | Description                         |
| -------- | --------------------- | ----------------------------------- |
| `parse`  | `pkgs -> Path -> AST` | Parse a `.nix` file into an AST     |
| `render` | `pkgs -> AST -> Path` | Render an AST to a `.nix` file      |
| `toAST`  | `a -> AST`            | Convert a Nix value to AST (no IFD) |

### `lib.syntax` — Constructors & Predicates

Type-checked node builders and tag predicates. All constructors validate their arguments at runtime.

```nix
# Builders
syntax.mkInt 42
syntax.mkFloat 3.14
syntax.mkBool true
syntax.mkNull
syntax.mkDoubleQuoted [ syntax.mkPlain "hello" ]
syntax.mkIndented 2 [ syntax.mkPlain "world" ]
syntax.mkSym "x"
syntax.mkApp (syntax.mkSym "f") (syntax.mkInt 1)
syntax.mkAbs (syntax.mkParam "x") (syntax.mkSym "x")
syntax.mkLet [ syntax.mkNamedVar [ syntax.mkStaticKey "x" ] (syntax.mkInt 1) ] (syntax.mkSym "x")
syntax.mkSet false [ syntax.mkNamedVar [ syntax.mkStaticKey "x" ] (syntax.mkInt 1) ]
syntax.mkIf (syntax.mkBool true) (syntax.mkInt 1) (syntax.mkInt 2)
# ... and more

# Predicates
syntax.isInt node
syntax.isSym node
syntax.isApp node
# ... one per node type
```

### `lib.match` — Pattern Matching

```nix
match ast {
  Sym = n: n.contents;           # exact tag match
  App = { func, arg }: ...;      # destructure
  _ = n: n.tag;                  # wildcard fallback
}
```

### `lib.traversal` — Tree Operations

All operations respect the **children/rebuild contract**: `rebuild node (children node) == node`.

| Function    | Description                                                   |
| ----------- | ------------------------------------------------------------- |
| `children`  | Get immediate child nodes in deterministic order              |
| `rebuild`   | Reconstruct node from new children (inverse of `children`)    |
| `descend`   | Apply function to all immediate children, then rebuild        |
| `transform` | Bottom-up transformation: `f (descend (transform f) node)`    |
| `rewrite`   | Apply rule bottom-up; `null` means no change                  |
| `para`      | Paramorphism: access node and recursive results from children |
| `universe`  | All descendant nodes including self                           |
| `holes`     | Each child paired with a replacement function                 |
| `contexts`  | Every subnode paired with a function to replace it in context |

```nix
# Example: replace all integers with their double
doubleInts = traversal.transform (node:
  if syntax.isConstant node && syntax.isInt node.contents then
    syntax.mkInt (node.contents * 2)
  else
    node
);
```

---

## AST Data Format

The AST is a **tagged union** — Nix attribute sets with a `tag` field identifying the node type.

### Expression Nodes

```nix
{ tag = "Abs"; params = <Params>; body = <Expr>; }
{ tag = "App"; func = <Expr>; arg = <Expr>; }
{ tag = "Assert"; cond = <Expr>; body = <Expr>; }
{ tag = "Binary"; op = "&&"; left = <Expr>; right = <Expr>; }
{ tag = "Constant"; contents = <Atom>; }
{ tag = "EnvPath"; contents = "<nixpkgs>"; }
{ tag = "HasAttr"; expr = <Expr>; attrPath = [<KeyName>]; }
{ tag = "If"; cond = <Expr>; thenExpr = <Expr>; elseExpr = <Expr>; }
{ tag = "Let"; bindings = [<Binding>]; body = <Expr>; }
{ tag = "List"; contents = [<Expr>]; }
{ tag = "LiteralPath"; contents = "./foo.nix"; }
{ tag = "Select"; defaultValue = <Expr|null>; expr = <Expr>; selectPath = [<KeyName>]; }
{ tag = "Set"; recursive = false; bindings = [<Binding>]; }
{ tag = "Str"; contents = <String>; }
{ tag = "Sym"; contents = "x"; }
{ tag = "SynHole"; contents = "hole"; }
{ tag = "Unary"; op = "!"; arg = <Expr>; }
{ tag = "With"; namespace = <Expr>; body = <Expr>; }
```

### Atoms

```nix
{ tag = "Int"; contents = 42; }
{ tag = "Float"; contents = 3.14; }
{ tag = "Bool"; contents = true; }
{ tag = "Null"; }
{ tag = "Uri"; contents = "https://example.com"; }
```

### Bindings

```nix
{ tag = "Inherit"; scope = <Expr|null>; names = [ "x" "y" ]; }
{ tag = "NamedVar"; attrPath = [<KeyName>]; value = <Expr>; }
```

### Keys

```nix
{ tag = "DynamicKey"; contents = <String>; }
{ tag = "StaticKey"; contents = "keyName"; }
```

### Strings

```nix
{ tag = "DoubleQuoted"; contents = [<AntiquotedText>]; }
{ tag = "Indented"; indent = 2; contents = [<AntiquotedText>]; }
```

### Antiquoted Text

```nix
{ tag = "Plain"; contents = "literal text"; }
{ tag = "Antiquoted"; contents = <Expr>; }
{ tag = "EscapedNewline"; }
```

### Parameters

```nix
{ tag = "Param"; contents = "x"; }
{ tag = "ParamSet"; paramSetName = "args"; variadic = false; params = [ [ "x" null ] [ "y" <Expr> ] ]; }
```

---

## CLI Reference

```
nix-ast - Nix AST tool

Usage: nix-ast COMMAND
  Parse and generate Nix expressions via hnix

Available commands:
  parse    Parse a Nix expression to AST
  render   Generate Nix expression from AST

Options:
  -h, --help     Show this help text
  -v, --version  Show version

nix-ast parse - Parse a Nix expression to AST

Usage: nix-ast parse [--expr EXPR] [--file FILE]
  -e, --expr EXPR       Nix expression string
  -f, --file FILE       Input file (default: stdin)

nix-ast render - Generate Nix expression from AST

Usage: nix-ast render [--json JSON] [--file FILE]
  -j, --json JSON       AST in JSON format
  -f, --file FILE       Input file (default: stdin)
```

---

## Architecture

```
┌────────────────────────────────────────────────────────────┐
│                        Nix Layer                           │
│  ┌─────────┐  ┌──────────┐  ┌───────────┐  ┌───────────┐   │
│  │  match  │  │  syntax  │  │ traversal │  │   toAST   │   │
│  └─────────┘  └──────────┘  └───────────┘  └───────────┘   │
│        │           │              │            │           │
│        └───────────┴──────────────┴────────────┘           │
│                           │                                │
│                    ┌──────▼───────┐                        │
│                    │ parse/render │  (IFD → Haskell CLI)   │
│                    └──────┬───────┘                        │
└───────────────────────────┼────────────────────────────────┘
                            │
                    ┌───────▼───────┐
                    │ Haskell Layer │
                    │  ┌────────┐   │
                    │  │  hnix  │   │
                    │  └────────┘   │
                    │  ┌────────┐   │
                    │  │ nix-ast│   │
                    │  └────────┘   │
                    └───────────────┘
```

- **Nix layer**: Pure Nix functions for AST manipulation, type-checked builders, pattern matching, and traversal combinators
- **Haskell layer**: Uses `hnix` for parsing/pretty-printing; provides CLI for JSON ↔ AST conversion
- **IFD bridge**: `parse` and `render` invoke the CLI via `runCommand` (Import From Derivation)

---

## Development

### Prerequisites

- Nix with flakes enabled
- GHC 9.10+ (provided by devShell)

### Commands

```bash
# Enter development shell
nix develop

# Build Haskell package
cabal build

# Run tests
cabal test

# Format Haskell code
fourmolu -i src app test

# Run CLI locally
cabal run nix-ast -- parse --expr '{ x = 1; }'

# Run Nix tests
nix flake check
```

### Project Structure

```
nix-ast/
├── app/                    # Haskell CLI entry point
│   ├── Main.hs
│   └── NixAST/CLI.hs
├── src/                    # Haskell library
│   ├── NixAST.hs           # Main exports
│   ├── NixAST/Types.hs     # JSON AST types (Haskell)
│   ├── NixAST/Convert.hs   # hnix AST ↔ JSON AST conversion
│   └── NixAST/Input.hs     # Input handling (stdin, file, string)
├── nix/
│   └── lib/                # Pure Nix library
│       ├── default.nix     # Main export (match, syntax, traversal, toAST, parse, render)
│       ├── types.nix       # Type predicates and combinators
│       ├── syntax.nix      # Constructors and predicates
│       ├── match.nix       # Pattern matching
│       └── traversal.nix   # Tree traversal & transformation
├── test/                   # Haskell tests
├── flake.nix               # Flake definition
├── nix-ast.cabal           # Cabal package
└── CHANGELOG.md
```

---

## License

BSD-3-Clause — see [LICENSE](LICENSE) for details.
