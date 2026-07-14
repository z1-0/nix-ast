# Sym (Variable Reference)

## Definition

```
Sym VarName
```

## Fields

| Field      | Type      | Description       |
| ---------- | --------- | ----------------- |
| `contents` | `VarName` | The variable name |

## Description

`Sym` represents a reference to a variable in scope. It is used for:

- Function parameters
- Let-bound variables
- Inherited variables
- Built-in identifiers (e.g., `builtins`, `pkgs`)

## Nix Source ↔ AST

```nix
# Nix
x

# AST
{
  "tag": "Sym",
  "contents": "x"
}
```

```nix
# Nix
builtins.map

# AST
{
  "tag": "Sym",
  "contents": "builtins.map"
}
```

## Related

- [VarName](./../var-name.md): the underlying type

## Nix Library Access

```nix
syntax.mkSym "x"
syntax.mkSym "builtins.map"
```
