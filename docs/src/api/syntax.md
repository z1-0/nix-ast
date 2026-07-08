# syntax — Constructors & Predicates

Type-checked node builders and tag predicates. All constructors validate their arguments at runtime.

## Constructors

### Atoms

```nix
syntax.mkInt 42
syntax.mkFloat 3.14
syntax.mkBool true
syntax.mkNull
syntax.mkUri "https://example.com"
```

### Strings

```nix
syntax.mkStrDoubleQuoted [ syntax.mkPlain "hello" ]
syntax.mkStrIndented 2 [ syntax.mkPlain "world" ]
```

### Expressions

```nix
syntax.mkSym "x"
syntax.mkApp (syntax.mkSym "f") (syntax.mkInt 1)
syntax.mkAbs (syntax.mkParam "x") (syntax.mkSym "x")
syntax.mkIf (syntax.mkBool true) (syntax.mkInt 1) (syntax.mkInt 2)
syntax.mkLet [ syntax.mkNamedVar [ syntax.mkStaticKey "x" ] (syntax.mkInt 1) ] (syntax.mkSym "x")
syntax.mkSet false [ syntax.mkNamedVar [ syntax.mkStaticKey "x" ] (syntax.mkInt 1) ]
syntax.mkList [ syntax.mkInt 1 syntax.mkInt 2 syntax.mkInt 3 ]
syntax.mkBinary "+" (syntax.mkSym "x") (syntax.mkSym "y")
syntax.mkUnary "!" (syntax.mkSym "x")
syntax.mkWith (syntax.mkSym "pkgs") (syntax.mkSym "x")
syntax.mkAssert (syntax.mkBool true) (syntax.mkSym "x")
syntax.mkSelect (syntax.mkSym "default") (syntax.mkSym "set") [ syntax.mkStaticKey "attr" ]
syntax.mkHasAttr (syntax.mkSym "set") [ syntax.mkStaticKey "attr" ]
syntax.mkLiteralPath "./foo.nix"
syntax.mkEnvPath "<nixpkgs>"
```

### Bindings

```nix
syntax.mkInherit null [ "x" "y" ]
syntax.mkInherit (syntax.mkSym "pkgs") [ "vim" "git" ]
syntax.mkNamedVar [ syntax.mkStaticKey "x" ] (syntax.mkInt 1)
```

### Keys

```nix
syntax.mkStaticKey "foo"
syntax.mkDynamicKey (syntax.mkAntiquoted (syntax.mkSym "name"))
```

### Parameters

```nix
syntax.mkParam "x"
syntax.mkParamSet null false [ [ "x" null ] [ "y" (syntax.mkInt 1) ] ]
```

### Antiquoted Text

```nix
syntax.mkPlain "hello"
syntax.mkAntiquoted (syntax.mkSym "x")
syntax.mkEscapedNewline
```

## Predicates

One predicate per node type:

```nix
# Expression predicates
syntax.isAbs node
syntax.isApp node
syntax.isAssert node
syntax.isBinary node
syntax.isConstant node
syntax.isEnvPath node
syntax.isHasAttr node
syntax.isIf node
syntax.isLet node
syntax.isList node
syntax.isLiteralPath node
syntax.isSelect node
syntax.isSet node
syntax.isStr node
syntax.isSym node
syntax.isSynHole node
syntax.isUnary node
syntax.isWith node

# Atom predicates
syntax.isInt node
syntax.isFloat node
syntax.isBool node
syntax.isNull node
syntax.isUri node

# Binding predicates
syntax.isInherit node
syntax.isNamedVar node

# Key predicates
syntax.isDynamicKey node
syntax.isStaticKey node

# String predicates
syntax.isDoubleQuoted node
syntax.isIndented node

# Antiquoted text predicates
syntax.isPlain node
syntax.isAntiquoted node
syntax.isEscapedNewline node
```

## Helpers

```nix
# Get node tag
syntax.getExprKind node  # => "Sym", "App", etc.

# Check tag
syntax.hasTag "Sym" node  # => true/false
```
