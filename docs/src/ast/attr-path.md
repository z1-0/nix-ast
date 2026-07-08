# AttrPath

## Definition

```
NonEmpty KeyName
```

## Description

`AttrPath` represents a path to an attribute in an attribute set, like `foo.bar.baz`. An attribute path must be **non-empty**: it always contains at least one key.

## Nix Source ↔ AST

```json
{
  "tag": "NamedVar",
  "attrPath": [
    { "tag": "StaticKey", "contents": "foo" },
    { "tag": "StaticKey", "contents": "bar" }
  ],
  "value": { ... }
}
```

### Examples

```
foo.bar.baz
  → [ StaticKey "foo", StaticKey "bar", StaticKey "baz" ]

"${name}.static"
  → [ DynamicKey (Antiquoted (Sym "name")), StaticKey "static" ]
```

Used as the `attrPath` field of:

- `NamedVar` — binding left-hand side
- `Select` — attribute selection
- `HasAttr` — attribute existence check

## Related

- [KeyName](../key-name/README.md)
- [Binding](../binding/README.md)

## Nix Library Access

```nix
syntax.mkStaticKey "foo"
syntax.mkDynamicKey (syntax.mkAntiquoted (syntax.mkSym "name"))
```
