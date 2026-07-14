# Set (Attribute Set)

## Definition

```
Set { recursive :: Bool, bindings :: [Binding] }
```

## Fields

| Field       | Type        | Description                                     |
| ----------- | ----------- | ----------------------------------------------- |
| `recursive` | `Bool`      | `true` for `rec { ... }`, `false` for `{ ... }` |
| `bindings`  | `[Binding]` | List of bindings (`Inherit` or `NamedVar`)      |

## Nix Source ↔ AST

### Non-Recursive Set

```nix
# Nix
{ x = 1; y = 2; }

# AST
{
  "tag": "Set",
  "recursive": false,
  "bindings": [
    {
      "tag": "NamedVar",
      "attrPath": [{ "tag": "StaticKey", "contents": "x" }],
      "value": { "tag": "Constant", "contents": { "tag": "Int", "contents": 1 } }
    },
    {
      "tag": "NamedVar",
      "attrPath": [{ "tag": "StaticKey", "contents": "y" }],
      "value": { "tag": "Constant", "contents": { "tag": "Int", "contents": 2 } }
    }
  ]
}
```

### Recursive Set

```nix
# Nix
rec { x = 1; y = x + 1; }

# AST
{
  "tag": "Set",
  "recursive": true,
  "bindings": [
    {
      "tag": "NamedVar",
      "attrPath": [{ "tag": "StaticKey", "contents": "x" }],
      "value": { "tag": "Constant", "contents": { "tag": "Int", "contents": 1 } }
    },
    {
      "tag": "NamedVar",
      "attrPath": [{ "tag": "StaticKey", "contents": "y" }],
      "value": {
        "tag": "Binary",
        "op": "+",
        "left": { "tag": "Sym", "contents": "x" },
        "right": { "tag": "Constant", "contents": { "tag": "Int", "contents": 1 } }
      }
    }
  ]
}
```

### With Inherit

```nix
# Nix
{ inherit x y; z = 3; }

# AST
{
  "tag": "Set",
  "recursive": false,
  "bindings": [
    { "tag": "Inherit", "scope": null, "names": ["x", "y"] },
    {
      "tag": "NamedVar",
      "attrPath": [{ "tag": "StaticKey", "contents": "z" }],
      "value": { "tag": "Constant", "contents": { "tag": "Int", "contents": 3 } }
    }
  ]
}
```

## Related

- [Binding](../binding/README.md): `Inherit` and `NamedVar` constructors
- [KeyName](../key-name/README.md): `StaticKey` / `DynamicKey` for attribute paths

## Nix Library Access

```nix
syntax.mkSet false [syntax.mkNamedVar [syntax.mkStaticKey "x"] (syntax.mkInt 1)]
syntax.mkSet true [...]
```
