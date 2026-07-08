let
  isNodeOf = tags: node: builtins.isAttrs node && node ? tag && builtins.elem node.tag tags;

  Expr = {
    name = "Expr";
    check = isNodeOf [
      "Abs"
      "App"
      "Assert"
      "Binary"
      "Constant"
      "EnvPath"
      "HasAttr"
      "If"
      "Let"
      "List"
      "LiteralPath"
      "Select"
      "Set"
      "Str"
      "Sym"
      "SynHole"
      "Unary"
      "With"
    ];
  };

  Atom = {
    name = "Atom";
    check = isNodeOf [
      "Bool"
      "Float"
      "Int"
      "Null"
      "Uri"
    ];
  };

  Binding = {
    name = "Binding";
    check = isNodeOf [
      "Inherit"
      "NamedVar"
    ];
  };

  KeyName = {
    name = "KeyName";
    check = isNodeOf [
      "DynamicKey"
      "StaticKey"
    ];
  };

  Params = {
    name = "Params";
    check = isNodeOf [
      "Param"
      "ParamSet"
    ];
  };

  String = {
    name = "String";
    check = isNodeOf [
      "DoubleQuoted"
      "Indented"
    ];
  };

  AntiquotedText = {
    name = "Antiquoted Text";
    check = isNodeOf [
      "Plain"
      "Antiquoted"
      "EscapedNewline"
    ];
  };

  AntiquotedString = {
    name = "Antiquoted String";
    check = isNodeOf [
      "Plain"
      "Antiquoted"
      "EscapedNewline"
    ];
  };

  # Combinators
  listOf = type: {
    name = "listOf ${type.name}";
    check = v: builtins.isList v && builtins.all type.check v;
  };

  maybe = type: {
    name = "maybe ${type.name}";
    check = v: v == null || type.check v;
  };

  either = t1: t2: {
    name = "either ${t1.name} or ${t2.name}";
    check = v: t1.check v || t2.check v;
  };

  anyVal = {
    name = "any";
    check = _: true;
  };

  textVal = {
    name = "text";
    check = builtins.isString;
  };

  intVal = {
    name = "int";
    check = builtins.isInt;
  };

  floatVal = {
    name = "float";
    check = builtins.isFloat;
  };

  boolVal = {
    name = "bool";
    check = builtins.isBool;
  };
in
{
  inherit
    Expr
    Atom
    Binding
    KeyName
    Params
    String
    AntiquotedText
    AntiquotedString
    ;
  inherit
    listOf
    maybe
    either
    anyVal
    textVal
    intVal
    floatVal
    boolVal
    ;
}
