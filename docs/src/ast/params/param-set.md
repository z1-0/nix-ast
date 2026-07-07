# ParamSet (Parameter Set)

Parameter set constructor for function parameters. Part of the `Params` type.

## Definition

```
ParamSet { paramSetName :: Maybe VarName, variadic :: Bool, params :: ParamSet }
```

## Fields

| Field | Type | Description |
|-------|------|-------------|
| `paramSetName` | `Maybe VarName` | Name for `@`-pattern (e.g., `args @ { x, y }`) |
| `variadic` | `Bool` | `true` if `...` is present (allows extra arguments) |
| `params` | `ParamSet` | The actual parameter set (map of name → optional default) |

## Description

`ParamSet` represents a function parameter set like `{ x, y ? 1, ... }`. It contains the parameter names, their optional default values, whether it's variadic, and an optional name for the whole set (for `@`-patterns).

The inner `ParamSet` field wraps a parameter set type that maps parameter names to optional default expressions.

## Nix Source ↔ AST

### Fixed Parameters
```nix
# Nix
{ x, y }: x + y

# AST
{
  "tag": "Abs",
  "params": {
    "tag": "ParamSet",
    "paramSetName": null,
    "variadic": false,
    "params": [
      ["x", null],
      ["y", null]
    ]
  },
  "body": { ... }
}
```

### With Defaults
```nix
# Nix
{ x ? 1, y ? "hello" }: x

# AST
{
  "tag": "ParamSet",
  "paramSetName": null,
  "variadic": false,
  "params": [
    ["x", { "tag": "Constant", "contents": { "tag": "Int", "contents": 1 } }],
    ["y", { "tag": "Str", "contents": { "tag": "DoubleQuoted", "contents": [{ "tag": "Plain", "contents": "hello" }] } }]
  ]
}
```

### Variadic (`...`)
```nix
# Nix
{ x, y, ... }: x + y

# AST
{
  "tag": "ParamSet",
  "paramSetName": null,
  "variadic": true,
  "params": [
    ["x", null],
    ["y", null]
  ]
}
```

### With `@`-Pattern
```nix
# Nix
args @ { x, y }: args.x + args.y

# AST
{
  "tag": "ParamSet",
  "paramSetName": "args",
  "variadic": false,
  "params": [
    ["x", null],
    ["y", null]
  ]
}
```

## Related

- [Param](./param.md) — single parameter constructor
- [Params](../params/README.md) — the parent sum type

## Nix Library Access

```nix
syntax.mkParamSet null [["x" null] ["y" null]] false
syntax.mkParamSet null [["x" (syntax.mkInt 1)]] false
syntax.mkParamSet null [["x" null] ["y" null]] true
syntax.mkParamSet "args" [["x" null] ["y" null]] false
```