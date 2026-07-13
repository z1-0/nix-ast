let
  isNodeOf = tags: node: builtins.isAttrs node && node ? tag && builtins.elem node.tag tags;
  mkType = name: tags: { inherit name; check = isNodeOf tags; };
in {
  Expr = mkType "Expr" [ "Abs" "App" "Assert" "Binary" "Constant" "EnvPath" "HasAttr" "If" "Let" "List" "LiteralPath" "Select" "Set" "Str" "Sym" "SynHole" "Unary" "With" ];
  Atom = mkType "Atom" [ "Bool" "Float" "Int" "Null" "Uri" ];
  Binding = mkType "Binding" [ "Inherit" "NamedVar" ];
  KeyName = mkType "KeyName" [ "DynamicKey" "StaticKey" ];
  Params = mkType "Params" [ "Param" "ParamSet" ];
  String = mkType "String" [ "DoubleQuoted" "Indented" ];
  Antiquoted = mkType "Antiquoted" [ "Plain" "Antiquoted" "EscapedNewline" ];
  listOf = type: { name = "listOf ${type.name}"; check = v: builtins.isList v && builtins.all type.check v; };
  maybe = type: { name = "maybe ${type.name}"; check = v: v == null || type.check v; };
  either = t1: t2: { name = "either ${t1.name} or ${t2.name}"; check = v: t1.check v || t2.check v; };
  anyVal = { name = "any"; check = _: true; };
  textVal = { name = "text"; check = builtins.isString; };
  intVal = { name = "int"; check = builtins.isInt; };
  floatVal = { name = "float"; check = builtins.isFloat; };
  boolVal = { name = "bool"; check = builtins.isBool; };
}
