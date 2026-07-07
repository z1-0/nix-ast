# Uri (URI Atom)

## Definition

```
Uri Text
```

## Fields

| Field | Type | Description |
|-------|------|-------------|
| `contents` | `Text` | The URI string |

## Nix Source ↔ AST

```nix
# Nix
https://example.com

# AST (wrapped in Constant)
{
  "tag": "Constant",
  "contents": { "tag": "Uri", "contents": "https://example.com" }
}
```

## Note

In Nix, URIs are a distinct literal type (not strings). They are written without quotes and must be valid URIs.

## Related

- [Constant](./../expr/constant.md) — wrapper for atoms in expressions

## Nix Library Access

```nix
syntax.mkUri "https://example.com"
syntax.mkConstant (syntax.mkUri "https://example.com")
```