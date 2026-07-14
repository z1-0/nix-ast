# SynHole (Syntax Hole)

## Definition

```
SynHole VarName
```

## Fields

| Field      | Type      | Description              |
| ---------- | --------- | ------------------------ |
| `contents` | `VarName` | The hole identifier/name |

## Description

`SynHole` represents a placeholder or "hole" in the AST that can be filled later during metaprogramming or code generation. This is useful for:

- Template generation
- Partial AST construction
- Code synthesis tools

The `VarName` identifies the hole for later substitution.

## Nix Source ↔ AST

There is no direct Nix syntax for `SynHole`: it is constructed programmatically.

```json
{
  "tag": "SynHole",
  "contents": "myHole"
}
```

## Nix Library Access

```nix
syntax.mkSynHole "myHole"
```
