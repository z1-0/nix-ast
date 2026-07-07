# VarName

Type alias for identifiers used throughout the AST.

```
type VarName = Text
```

## Description

`VarName` represents identifiers in Nix code — variable names, attribute names, parameter names, etc.

## Usage

- Used in `Sym` (variable references)
- Used in `Param` (function parameters)
- Used in `StaticKey` (static attribute keys)
- Used in `Inherit` binding names
- Used in `ParamSet` parameter names

## JSON Representation

In the JSON AST, `VarName` appears as a plain string:

```json
{ "tag": "Sym", "contents": "myVariable" }
```

## Nix Library Access

```nix
syntax.mkSym "myVariable"
```