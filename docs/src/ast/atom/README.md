# Atom

## Constructors

| Constructor | Field      | Type      | Description                                |
| ----------- | ---------- | --------- | ------------------------------------------ |
| `Bool`      | `contents` | `Bool`    | Boolean value (`true`/`false`)             |
| `Float`     | `contents` | `Float`   | Floating-point (not in Nix surface syntax) |
| `Int`       | `contents` | `Integer` | 64-bit integer                             |
| `Null`      | (none)     | —         | Null value                                 |
| `Uri`       | `contents` | `Text`    | URI literal                                |

## Description

Atoms are the primitive constant values in Nix. They are always wrapped in a `Constant` expression node when used as expressions.

```json
{
  "tag": "Constant",
  "contents": { "tag": "Int", "contents": 42 }
}
```

## Pages

- [Bool](./bool.md)
- [Float](./float.md)
- [Int](./int.md)
- [Null](./null.md)
- [Uri](./uri.md)

## Related

- [Constant](../expr/constant.md) — expression wrapper for atoms

## Nix Library Access

```nix
syntax.mkInt 42
syntax.mkBool true
syntax.mkNull
syntax.mkUri "https://example.com"
syntax.mkFloat 3.14

# Wrapped in Constant
syntax.mkConstant (syntax.mkInt 42)
```
