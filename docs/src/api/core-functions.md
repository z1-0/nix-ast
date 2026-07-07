# Core Functions

## `parse`

Parse a `.nix` file into an AST.

```nix
parse :: pkgs -> Path -> AST
```

**Parameters:**
- `pkgs` — Nixpkgs instance (used for IFD)
- `path` — Path to a `.nix` file

**Returns:** AST (JSON attribute set)

**Example:**
```nix
ast = lib.parse pkgs ./config.nix;
```

## `render`

Render an AST to a `.nix` file.

```nix
render :: pkgs -> AST -> Path
```

**Parameters:**
- `pkgs` — Nixpkgs instance (used for IFD)
- `ast` — AST to render

**Returns:** Path to generated `.nix` file

**Example:**
```nix
configFile = lib.render pkgs ast;
config = import configFile;
```

## `toAST`

Convert a Nix value to AST (no IFD).

```nix
toAST :: a -> AST
```

**Parameters:**
- `value` — Nix value (int, string, list, attrset)

**Returns:** AST node

**Example:**
```nix
ast = lib.toAST { x = 1; y = [1 2 3]; }
# { tag = "Set"; recursive = false; bindings = [...]; }
```

## Workflow Example

```nix
configFile = let
  # Parse source file
  ast = lib.parse pkgs ./config.nix;

  # Transform the AST
  transformed = lib.traversal.transform (node:
    if lib.syntax.isConstant node && lib.syntax.isInt node.contents then
      lib.syntax.mkConstant (lib.syntax.mkInt (node.contents.contents * 2))
    else
      node
  ) ast;

  # Render back to Nix
in lib.render pkgs transformed;
```
