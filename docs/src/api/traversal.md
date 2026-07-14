# traversal: Tree Operations

All operations respect the **children/rebuild contract**: `rebuild node (children node) == node`.

## Core Operations

### `children`

Get immediate child nodes in deterministic order.

```nix
traversal.children :: Expr -> [Expr]
```

**Example:**

```nix
# For: { tag = "App"; func = f; arg = x; }
traversal.children node  # => [f, x]
```

### `rebuild`

Reconstruct node from new children (inverse of `children`).

```nix
traversal.rebuild :: Expr -> [Expr] -> Expr
```

**Example:**

```nix
newNode = traversal.rebuild node [newFunc newArg]
```

### `descend`

Apply function to all immediate children, then rebuild.

```nix
traversal.descend :: (Expr -> Expr) -> Expr -> Expr
```

**Example:**

```nix
# Transform all direct children
traversal.descend (n: n + 1) node
```

## Transformations

### `transform`

Bottom-up transformation: `f (descend (transform f) node)`.

```nix
traversal.transform :: (Expr -> Expr) -> Expr -> Expr
```

**Example:**

```nix
# Replace all integers with their double
doubleInts = traversal.transform (node:
  if syntax.isConstant node && syntax.isInt node.contents then
    syntax.mkConstant (syntax.mkInt (node.contents.contents * 2))
  else
    node
);
```

### `rewrite`

Apply rule bottom-up; `null` means no change.

```nix
traversal.rewrite :: (Expr -> Expr | null) -> Expr -> Expr
```

**Example:**

```nix
# Simplify constant folding
simplify = traversal.rewrite (node:
  if isBinaryAdd node && bothConstants node then
    syntax.mkInt (evalNode node)
  else
    null  # no change
);
```

### `para`

Paramorphism: access node and recursive results from children.

```nix
traversal.para :: (Expr -> [a] -> a) -> Expr -> a
```

**Example:**

```nix
# Count all nodes
countNodes = traversal.para (node: childCounts:
  1 + builtins.foldl' (a: b: a + b) 0 childCounts
);
```

## Exploration

### `universe`

All descendant nodes including self.

```nix
traversal.universe :: Expr -> [Expr]
```

**Example:**

```nix
allSymbols = builtins.filter syntax.isSym (traversal.universe ast);
```

### `holes`

Each child paired with a replacement function.

```nix
traversal.holes :: Expr -> [(Expr, Expr -> Expr)]
```

**Example:**

```nix
# Get all positions where a child can be replaced
holes = traversal.holes ast;
# => [(child1, \replacement -> rebuild node [replacement ...]),
#     (child2, \replacement -> rebuild node [... replacement ...])]
```

### `contexts`

Every subnode paired with a function to replace it in context.

```nix
traversal.contexts :: Expr -> [(Expr, Expr -> Expr)]
```

**Example:**

```nix
# Get all subexpressions with their context
contexts = traversal.contexts ast;
```

## Children/Rebuild Contract

All traversal operations maintain this invariant:

```nix
traversal.rebuild node (traversal.children node) == node
```

This ensures that operations can freely decompose and reconstruct nodes without losing information.

## Use Cases

### Deep Transformation

```nix
# Replace all variable references
replaceVars = traversal.transform (node:
  if syntax.isSym node then
    syntax.mkSym (replaceName node.contents)
  else
    node
);
```

### Collection

```nix
# Collect all function applications
collectApps = traversal.universe >> builtins.filter syntax.isApp;
```

### Analysis

```nix
# Check if expression contains a specific pattern
containsAssert = node:
  builtins.any syntax.isAssert (traversal.universe node);
```
