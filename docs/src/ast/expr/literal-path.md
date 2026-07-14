# LiteralPath (Relative/Absolute Path)

## Definition

```
LiteralPath FilePath
```

## Fields

| Field      | Type       | Description                                        |
| ---------- | ---------- | -------------------------------------------------- |
| `contents` | `FilePath` | The path string (e.g., `./foo.nix`, `/etc/config`) |

## Description

`LiteralPath` represents paths written without angle brackets: relative paths like `./foo.nix`, `../bar.nix`, or absolute paths like `/etc/nixos/configuration.nix`. These are resolved relative to the current file or as absolute paths, distinct from search-path paths.

## Nix Source ↔ AST

```nix
# Nix
./foo.nix

# AST
{
  "tag": "LiteralPath",
  "contents": "./foo.nix"
}
```

```nix
# Nix
../config.nix

# AST
{
  "tag": "LiteralPath",
  "contents": "../config.nix"
}
```

```nix
# Nix
/etc/nixos/configuration.nix

# AST
{
  "tag": "LiteralPath",
  "contents": "/etc/nixos/configuration.nix"
}
```

## Related

- [EnvPath](./env-path.md): search paths like `<nixpkgs>`

## Nix Library Access

```nix
syntax.mkLiteralPath "./foo.nix"
syntax.mkLiteralPath "/etc/nixos/configuration.nix"
```
