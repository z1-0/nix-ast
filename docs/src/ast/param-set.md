# ParamSet

Type alias for parameter sets, mapping parameter names to optional default expressions.

```
type ParamSet = [(Text, Maybe Expr)]
```

## Description

`ParamSet` represents the parameter set structure in function definitions — the `{ x, y ? 1, ... }` part. It maps parameter names to their optional default values. The `variadic` field on `ParamSet` distinguishes fixed (`false`) from variadic / ellipsis (`true`) parameter sets.

> **Invariant**: duplicate parameter names are semantically invalid in Nix. Each parameter name must be unique.

## Used In

- `Params.ParamSet.params` — the parameter set inside a `ParamSet` constructor

## JSON Representation

```json
{
  "tag": "ParamSet",
  "paramSetName": null,
  "variadic": false,
  "params": [
    ["x", null],
    ["y", { "tag": "Constant", "contents": { "tag": "Int", "contents": 1 } }]
  ]
}
```

## Nix Library Access

```nix
syntax.mkParamSet null false [["x" null] ["y" (syntax.mkInt 1)]]
```