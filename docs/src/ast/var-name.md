# VarName

## Description

`VarName` represents identifiers in Nix code: variable names, attribute names, parameter names, etc.

## Nix Source ↔ AST

```nix
# Nix
myVariable

# AST (inside Sym)
{ "tag": "Sym", "contents": "myVariable" }
```

Used as the `contents` field of:

- `Sym`: variable references
- `Param`: function parameters
- `StaticKey`: static attribute keys
- `Inherit`: inherited names
- `ParamSet`: parameter set parameter names

## Related

- [Expr](../expr/README.md)
- [KeyName](../key-name/README.md)
- [Binding](../binding/README.md)

## Nix Library Access

```nix
syntax.mkSym "myVariable"
```
