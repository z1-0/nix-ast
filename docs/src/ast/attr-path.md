# AttrPath

Type alias for attribute paths. A non-empty list of `KeyName`.

```
type AttrPath = NonEmpty KeyName
```

## Description

`AttrPath` represents a path to an attribute in an attribute set, like `foo.bar.baz`. An attribute path must be **non-empty**: it always contains at least one key.

## Structure

```
-- Example: foo.bar.baz
AttrPath [ StaticKey "foo", StaticKey "bar", StaticKey "baz" ]

-- Example: "${dynamicKey}.static"
AttrPath [ DynamicKey (Antiquoted (Sym "dynamicKey")), StaticKey "static" ]
```

## Used In

- `NamedVar.attrPath` — the left-hand side of a binding
- `Select.selectPath` — the attribute path being selected
- `HasAttr.attrPath` — the attribute path being checked

## JSON Representation

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

## Nix Library Access

```nix
syntax.mkStaticKey "foo"
syntax.mkDynamicKey (syntax.mkAntiquoted (syntax.mkSym "name"))
-- Build AttrPath as a list of KeyName
```