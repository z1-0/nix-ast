# Params

## Constructors

| Constructor | Fields                                                              | Description                       |
| ----------- | ------------------------------------------------------------------- | --------------------------------- |
| `ParamSet`  | `paramSetName: Maybe VarName`, `variadic: Bool`, `params: ParamSet` | Parameter set `{ x, y ? 1, ... }` |
| `Param`     | `contents: VarName`                                                 | Single parameter `x: ...`         |

## Description

`Params` represents function parameters — either a single parameter (`x: body`) or a parameter set (`{ x, y ? 1 }: body`).

The `ParamSet` constructor contains an inner `ParamSet` type which is a map of parameter names to optional default expressions.

## Pages

- [ParamSet](./param-set.md)
- [Param](./param.md)

## Related

- [Abs](../expr/abs.md) — uses `Params`
- [VarName](../var-name.md)

## Nix Library Access

```nix
syntax.mkParam "x"
syntax.mkParamSet null false [["x" null] ["y" null]]
syntax.mkParamSet null false [["x" (syntax.mkInt 1)]]
syntax.mkParamSet null true [["x" null] ["y" null]]
```
