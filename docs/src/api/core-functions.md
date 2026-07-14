# Core Functions

The four main functions — `parse`, `render`, `eval`, `toAST`, `fromAST` — bridge between Nix source code, AST values, and evaluated Nix values.

All IFD-based functions (`parse`, `render`, `eval`) require a `pkgs` argument (a Nixpkgs instance). They work by serializing inputs to JSON, invoking the `nix-ast` CLI inside a derivation, and parsing the output back.

---

## `parse`

Read `.nix` files from disk and return their AST representations. Uses `nix-ast parse` under the hood.

```nix
parse :: pkgs -> [Path] -> [AST]
```

**How it works:** The function takes a list of file paths, serializes them to JSON, writes them to a temporary file, runs `nix-ast parse < paths.json` in a derivation, then parses the JSON output back into Nix values. The CLI performs concurrent file I/O (up to 50 parallel reads) for efficiency.

**Parameters:**

| Parameter | Type       | Description                             |
|-----------|------------|-----------------------------------------|
| `pkgs`    | `pkgs`     | Nixpkgs instance (provides `runCommand` and `stdenv` for IFD) |
| `paths`   | `[Path]`   | List of paths to `.nix` files to parse  |

**Returns:** `[AST]` — A list of AST nodes, one per input file, in the same order.

**Example:**

```nix
# Parse a single file
asts = lib.parse pkgs [./config.nix];

# Parse multiple files
asts = lib.parse pkgs [./config.nix ./default.nix ./modules/*.nix];

# Access the first AST
ast = builtins.head asts;
```

**Error behavior:** If a file doesn't exist or contains invalid Nix syntax, the derivation fails at build time with an error message indicating which file and the parser error.

---

## `render`

Convert AST values to `.nix` files on disk. The inverse of `parse`.

```nix
render :: pkgs -> [AST] -> [Path]
```

**How it works:** Serializes ASTs to JSON, pipes them through `nix-ast render --out-dir $out`, which writes each AST to a file named by its index (`0.nix`, `1.nix`, etc.) inside the derivation output directory. Returns the list of resulting store paths.

**Parameters:**

| Parameter | Type     | Description                                |
|-----------|----------|--------------------------------------------|
| `pkgs`    | `pkgs`   | Nixpkgs instance (for IFD)                 |
| `asts`    | `[AST]`  | List of AST nodes to render                |

**Returns:** `[Path]` — List of store paths to generated `.nix` files. The i-th path corresponds to the i-th input AST.

**Example:**

```nix
# Render a single AST to file
outPaths = lib.render pkgs [ast];
configFile = builtins.head outPaths;
config = import configFile;

# Render multiple ASTs
outPaths = lib.render pkgs [ast1, ast2, ast3];
imported = map import outPaths;
```

**Error behavior:** If an AST is structurally invalid (e.g., missing required fields), the conversion to internal representation fails with a descriptive error.

---

## `eval`

Evaluate AST values and return the results as JSON values.

```nix
eval :: pkgs -> [AST] -> [a]
```

**How it works:** Serializes ASTs to JSON, pipes them through `nix-ast eval` in a derivation. The CLI deserializes each AST, evaluates it, and outputs the results as JSON.

**Parameters:**

| Parameter | Type     | Description                                |
|-----------|----------|--------------------------------------------|
| `pkgs`    | `pkgs`   | Nixpkgs instance (for IFD)                 |
| `asts`    | `[AST]`  | List of AST nodes to evaluate              |

**Returns:** `[a]` — List of evaluated Nix values, serialized to JSON-compatible Nix values (atoms, lists, attrsets).

**Constraints:** Only JSON-serializable values are supported. Functions and derivations in the evaluation result cause errors.

**Example:**

```nix
# Evaluate a simple expression
asts = lib.parse pkgs [./expr.nix];
result = lib.eval pkgs asts;  # evaluated values

# Evaluate inline-generated AST
ast = lib.toAST { x = 1 + 2; };
result = lib.eval pkgs [ast];  # => [ { x = 3; } ]
```

---

## `toAST`

Convert any native Nix value to its AST representation. Pure function — no IFD required.

```nix
toAST :: a -> AST
```

**How it works:** Recursively inspects the Nix value's type using `builtins.isBool`, `builtins.isInt`, etc., and constructs the corresponding AST nodes using syntax constructors (`mkInt`, `mkSet`, `mkStr`, etc.). Attrsets are converted to `Set` nodes with `NamedVar` bindings. Strings become `Str` → `DoubleQuoted` → `Plain`.

**Supported types:**

| Nix type     | AST representation                   |
|-------------|--------------------------------------|
| `Bool`      | `Constant (Bool b)`                  |
| `Int`       | `Constant (Int i)`                   |
| `Float`     | `Constant (Float f)`                 |
| `null`      | `Constant Null`                      |
| `String`    | `Str (DoubleQuoted [Plain s])`       |
| `Path`      | `LiteralPath`                        |
| `List`      | `List [items...]`                    |
| `AttrSet`   | `Set { recursive = false, bindings = [...] }` |

**Unsupported types:** Functions and derivations raise an error.

**Example:**

```nix
lib.toAST 42;
# => { tag = "Constant"; contents = { tag = "Int"; contents = 42; }; }

lib.toAST { x = 1; y = [1 2 3]; };
# => { tag = "Set"; recursive = false;
#      bindings = [
#        { tag = "NamedVar"; attrPath = [{tag="StaticKey"; contents="x"}];
#          value = { tag = "Constant"; contents = { tag = "Int"; contents = 1; }; }; }
#        ...
#      ]; }
```

**Error behavior:**

- `toAST` on a function: `"toAST: cannot convert function to AST"`
- `toAST` on a derivation: `"toAST: cannot convert derivation to AST"`
- Unrecognized type: `"toAST: unsupported Nix type"`

---

## `fromAST`

Convert an AST back to a native Nix value. Pure function — runs entirely in Nix, no IFD.

```nix
fromAST :: AST -> a
```

**How it works:** Uses `match` to dispatch on the AST node tag and recursively converts nodes to native Nix values. Atoms become their Nix equivalents, strings are concatenated from their parts (with interpolation support for `Str` nodes and plain text), lists are mapped element-wise, and non-recursive attrsets are reconstructed from bindings.

**Supported node conversions:**

| AST node       | Nix type     | Notes                              |
|----------------|--------------|------------------------------------|
| `Constant`     | atom value   | Int, Float, Bool, Null, Uri        |
| `Str`          | `String`     | Concatenates parts; only `Str` and text in interpolation |
| `EnvPath`      | `String`     | Returns the path string directly   |
| `LiteralPath`  | `String`     | Returns the path string directly   |
| `List`         | `List`       | Recursively converts elements      |
| `Set`          | `AttrSet`    | Only non-recursive sets            |

**Limitations:**

- Recursive sets (`rec { ... }`) throw: `"fromAST: cannot convert recursive set to Nix value"`
- Plain `inherit` (without a scope) throws: `"fromAST: plain inherit (without scope) is not supported"`
- String interpolation only supports `Str` nodes or plain text inside `Antiquoted` parts
- Paths are returned as strings, not actual Nix paths

**Example:**

```nix
ast = lib.toAST { greeting = "hello"; count = 42; };
lib.fromAST ast;
# => { greeting = "hello"; count = 42; }

# Round-trip: toAST → fromAST preserves the value
assert lib.fromAST (lib.toAST [1 2 3]) == [1 2 3];
```

---

## Workflow Example

Putting it all together: parse a Nix file, transform it, render the result, and verify via eval.

```nix
let
  inherit (lib) parse render eval traversal syntax toAST fromAST;

  # Step 1: Parse source files into ASTs
  asts = parse pkgs [./config.nix];
  original = builtins.head asts;

  # Step 2: Transform the AST (double all integer constants)
  transformed = traversal.transform (node:
    if syntax.isConstant node && syntax.isInt node.contents then
      syntax.mkConstant (syntax.mkInt (node.contents.contents * 2))
    else
      node
  ) original;

  # Step 3: Render back to .nix file
  outPaths = render pkgs [transformed];
  configFile = builtins.head outPaths;

  # Step 4: Import the result
  config = import configFile;

  # Step 5: Or evaluate the transformed AST directly
  evaluated = eval pkgs [transformed];

in { inherit config configFile evaluated; }
```
