# StaticKey (Static Attribute Key)

## Definition

```
StaticKey VarName
```

## Fields

| Field      | Type      | Description         |
| ---------- | --------- | ------------------- |
| `contents` | `VarName` | The identifier name |

## Description

`StaticKey` is used for bare identifier keys in attribute sets: keys that are valid Nix identifiers (alphanumeric + underscore, not starting with a digit). These are written without quotes.

```nix
{ foo = 1; bar = 2; }  -- both are StaticKey
```

## Nix Source ↔ AST

```nix
# Nix
{ foo = 1; }

# AST (key part)
{ "tag": "StaticKey", "contents": "foo" }
```

## Rules

- Must be a valid Nix identifier: `[a-zA-Z_][a-zA-Z0-9_]*`
- Cannot start with a digit
- Cannot contain spaces or special characters (those require `DynamicKey`)

## Related

- [DynamicKey](./dynamic-key.md): dynamic/computed keys
- [VarName](./../var-name.md): underlying type
- [NamedVar](./../binding/named-var.md): uses `AttrPath` of `KeyName`

## Nix Library Access

```nix
syntax.mkStaticKey "foo"
syntax.mkStaticKey "my_var_123"
```
