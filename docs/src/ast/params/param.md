# Param (Single Parameter)

Single parameter constructor for function parameters. Part of the `Params` type.

## Definition

```
Param VarName
```

## Fields

| Field      | Type      | Description        |
| ---------- | --------- | ------------------ |
| `contents` | `VarName` | The parameter name |

## Description

`Param` represents a single-argument function parameter like `x: x + 1`. This is distinct from `ParamSet` which represents `{ x, y }: ...`.

## Nix Source ↔ AST

```nix
# Nix
x: x + 1

# AST
{
  "tag": "Abs",
  "params": { "tag": "Param", "contents": "x" },
  "body": {
    "tag": "Binary",
    "op": "+",
    "left": { "tag": "Sym", "contents": "x" },
    "right": { "tag": "Constant", "contents": { "tag": "Int", "contents": 1 } }
  }
}
```

## Related

- [ParamSet](./param-set.md) — parameter set constructor
- [Params](../params/README.md) — the parent sum type
- [VarName](./../var-name.md) — the parameter name type

## Nix Library Access

```nix
syntax.mkParam "x"
```
