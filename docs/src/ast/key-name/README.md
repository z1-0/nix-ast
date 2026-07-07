# KeyName

## Constructors

| Constructor | Fields | Description |
|-------------|--------|-------------|
| `DynamicKey` | `contents: Antiquoted String` | Dynamic/computed key |
| `StaticKey` | `contents: VarName` | Static identifier key |

## Description

`KeyName` represents attribute keys in bindings and attribute paths. A bare identifier like `foo` is a `StaticKey`; a quoted string like `"foo bar"` or antiquoted `${name}` is a `DynamicKey`.

## Pages

- [DynamicKey](./dynamic-key.md)
- [StaticKey](./static-key.md)

## Related

- [AttrPath](../attr-path.md) — non-empty list of `KeyName`
- [NamedVar](../binding/named-var.md) — uses `AttrPath`
- [VarName](../var-name.md)

## Nix Library Access

```nix
syntax.mkStaticKey "foo"
syntax.mkDynamicKey (syntax.mkDoubleQuoted [syntax.mkPlain "foo bar"])
syntax.mkDynamicKey (syntax.mkDoubleQuoted [syntax.mkAntiquoted (syntax.mkSym "name")])
```