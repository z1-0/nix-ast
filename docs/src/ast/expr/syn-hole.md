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

`SynHole` is a placeholder in the AST that metaprogramming or code generation fills in later. Typical uses: template generation, building partial ASTs, and code synthesis.

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
