# EnvPath (Search Path)

## Definition

```
EnvPath FilePath
```

## Fields

| Field      | Type       | Description                       |
| ---------- | ---------- | --------------------------------- |
| `contents` | `FilePath` | The path string (e.g., `nixpkgs`) |

## Description

`EnvPath` represents paths written in angle brackets like `<nixpkgs>` or `<nixos>`. These are looked up in the Nix search path (`NIX_PATH` environment variable) and are distinct from literal file paths.

## Nix Source ↔ AST

```nix
# Nix
<nixpkgs>

# AST
{
  "tag": "EnvPath",
  "contents": "nixpkgs"
}
```

```nix
# Nix
<nixos>

# AST
{
  "tag": "EnvPath",
  "contents": "nixos"
}
```

## Related

- [LiteralPath](./literal-path.md) — relative/absolute paths like `./foo.nix`

## Nix Library Access

```nix
syntax.mkEnvPath "nixpkgs"
syntax.mkEnvPath "nixos"
```
