import Mythroads.Convex.Ast

namespace Mythroads.Convex.TypeScript

/-! # Printing the TypeScript syntax tree

The printer is expressed entirely in terms of `Mythroads.Convex.Doc`: each `…Doc` function returns
a layout document that knows *where* it breaks but not *how far* it is indented, and `Doc.indent`
supplies the depth. That replaces the earlier design in which every printer took a `depth : Nat`
and pasted `indentation depth` in front of each line — a scheme under which `emitAsyncHandler` was
hard-wired to render correctly only at one nesting level. The rendered bytes did not change when
this layer was introduced: `npm run proofs:check` is the proof.

Final style (line width, trailing commas, method-chain breaking, import order) is Biome's job, not
this module's. The printer only has to emit valid TypeScript with the structural breaks Biome
preserves.
-/

/-- Builds an object type whose every field is required. Most emitters want this; only a validator
translation that knows a field is `v.optional(...)` needs the three-component form directly. -/
def TsType.obj (fields : List (String × TsType)) : TsType :=
  .object (fields.map fun (name, type) => (name, type, false))

/-- Joins strings with a separator. Kept for emitters that assemble plain text. -/
def join (separator : String) : List String → String
  | [] => ""
  | [value] => value
  | value :: rest => value ++ separator ++ join separator rest

/-- Renders a string as a single-quoted TypeScript literal, escaping backslashes and quotes. -/
def quote (value : String) : String :=
  "'" ++ (value.replace "\\" "\\\\").replace "'" "\\'" ++ "'"

/-- Lays out a TypeScript type. Types never break, so this is a `Doc.text` of one line. -/
partial def typeDoc : TsType → Doc
  | .void => .text "void"
  | .boolean => .text "boolean"
  | .number => .text "number"
  | .string => .text "string"
  | .literalString value => .text (quote value)
  | .named name => .text name
  | .id table => .text s!"Id<{quote table.name}>"
  | .doc table => .text s!"Doc<{quote table.name}>"
  | .omit inner fields =>
      .concat [.text "Omit<", typeDoc inner, .text ", ",
        Doc.joinWith " | " (fields.map fun field => .text (quote field)), .text ">"]
  | .object fields =>
      .concat [.text "{ ",
        Doc.joinWith "; " (fields.map fun (name, type, isOptional) =>
          .concat [.text (if isOptional then name ++ "?: " else name ++ ": "), typeDoc type]),
        .text " }"]
  | .array inner => .concat [typeDoc inner, .text "[]"]
  | .union members => Doc.joinWith " | " (members.map typeDoc)
  | .promise inner => .concat [.text "Promise<", typeDoc inner, .text ">"]

/-- Renders a TypeScript type as source text. -/
def emitType (type : TsType) : String := Doc.render (typeDoc type)

/-- Lays out a TypeScript expression. Expressions are emitted on one line; Biome decides where a
long call chain or object literal actually wraps. -/
partial def exprDoc : Expr → Doc
  | .identifier name => .text name
  | .boolean value => .text (if value then "true" else "false")
  | .string value => .text (quote value)
  | .number value => .text (toString value)
  | .null => .text "null"
  | .undefined => .text "undefined"
  | .property target name => .concat [exprDoc target, .text ("." ++ name)]
  | .optionalProperty target name => .concat [exprDoc target, .text ("?." ++ name)]
  | .index target index => .concat [exprDoc target, .text "[", exprDoc index, .text "]"]
  | .call callee arguments =>
      .concat [exprDoc callee, .text "(", Doc.joinWith ", " (arguments.map exprDoc), .text ")"]
  | .new constructor arguments =>
      .concat [.text ("new " ++ constructor ++ "("),
        Doc.joinWith ", " (arguments.map exprDoc), .text ")"]
  | .await value => .concat [.text "await ", exprDoc value]
  | .prefix operator value => .concat [.text ("(" ++ operator), exprDoc value, .text ")"]
  | .binary left operator right =>
      .concat [.text "(", exprDoc left, .text (" " ++ operator ++ " "), exprDoc right, .text ")"]
  | .conditional condition whenTrue whenFalse =>
      .concat [.text "(", exprDoc condition, .text " ? ", exprDoc whenTrue, .text " : ",
        exprDoc whenFalse, .text ")"]
  | .arrow parameters body =>
      .concat [.text ("(" ++ join ", " parameters ++ ") => "), exprDoc body]
  | .object fields =>
      .concat [.text "{ ",
        Doc.joinWith ", " (fields.map fun (name, value) =>
          .concat [.text (name ++ ": "), exprDoc value]),
        .text " }"]
  | .shorthand names => .text ("{ " ++ join ", " names ++ " }")
  | .array values => .concat [.text "[", Doc.joinWith ", " (values.map exprDoc), .text "]"]
  | .spread value => .concat [.text "...", exprDoc value]
  | .asConst value => .concat [exprDoc value, .text " as const"]

/-- Renders a TypeScript expression as source text. -/
def emitExpr (value : Expr) : String := Doc.render (exprDoc value)

mutual
  -- A doc comment may not precede `mutual`, so the explanation lives here: `statementDoc` lays out
  -- one statement with no leading indentation, and `statementsDoc` puts one statement per line.
  -- All nesting comes from `Doc.blockLines`, so a statement renders correctly at any depth.
  partial def statementDoc : Statement → Doc
    | .constDecl name value => .concat [.text ("const " ++ name ++ " = "), exprDoc value]
    | .constDeclTyped name type value =>
        .concat [.text ("const " ++ name ++ ": "), typeDoc type, .text " = ", exprDoc value]
    | .letDecl name value => .concat [.text ("let " ++ name ++ " = "), exprDoc value]
    | .constObjectRest omitted rest source =>
        .concat [.text ("const { " ++ join ", " omitted ++ ", ..." ++ rest ++ " } = "),
          exprDoc source]
    | .assign target value => .concat [exprDoc target, .text " = ", exprDoc value]
    | .expression value => exprDoc value
    | .voidValue value => .concat [.text "void ", exprDoc value]
    | .ifThen condition body =>
        .concat [.text "if (", exprDoc condition, .text ") ", statementsBlock body]
    | .ifElse condition whenTrue whenFalse =>
        .concat [.text "if (", exprDoc condition, .text ") ", statementsBlock whenTrue,
          .text " else ", statementsBlock whenFalse]
    | .throw error => .concat [.text "throw ", exprDoc error]
    | .return value => .concat [.text "return ", exprDoc value]
    | .returnVoid => .text "return"
    | .break => .text "break"
    | .switch value cases =>
        .concat [.text "switch (", exprDoc value, .text ") ",
          Doc.blockLines (cases.map fun (label, body) =>
            .concat [.text ("case " ++ quote label ++ ": "), statementsBlock body])]
    | .forOf binding values body =>
        .concat [.text ("for (const " ++ binding ++ " of "), exprDoc values, .text ") ",
          statementsBlock body]
    | .whileDo condition body =>
        .concat [.text "while (", exprDoc condition, .text ") ", statementsBlock body]

  partial def statementsDoc (statements : List Statement) : Doc :=
    Doc.lines (statements.map statementDoc)

  partial def statementsBlock (statements : List Statement) : Doc :=
    Doc.blockLines (statements.map statementDoc)
end

/-- Lays out one declared parameter, `name: T`. -/
def parameterDoc (parameter : Parameter) : Doc :=
  .concat [.text (parameter.name ++ ": "), typeDoc parameter.type]

/-- Lays out a Lean-authored `Function` as a TypeScript function declaration, newline-terminated. -/
def functionDoc (function : Function) : Doc :=
  .concat [
    .text ((if function.isExported then "export " else "") ++
      (if function.isAsync then "async " else "") ++ "function " ++ function.name ++ "("),
    Doc.joinWith ", " (function.parameters.map parameterDoc),
    .text "): ", typeDoc function.returns, .text " ", statementsBlock function.body, .text "\n"]

/-- Renders a Lean-authored `Function` syntax tree as executable TypeScript source. -/
def emitFunction (function : Function) : String := Doc.render (functionDoc function)

/-- Lays out an exported type alias, newline-terminated. -/
def typeAliasDoc (name : String) (type : TsType) : Doc :=
  .concat [.text ("export type " ++ name ++ " = "), typeDoc type, .text "\n"]

/-- Renders an exported type alias. -/
def emitTypeAlias (name : String) (type : TsType) : String := Doc.render (typeAliasDoc name type)

/-- The `handler` of a Convex endpoint definition: an async arrow over `(ctx, args)`. -/
structure AsyncHandler where
  /-- The handler parameters, conventionally the context and a destructured argument object. -/
  parameters : List Parameter
  /-- An explicit result annotation. Convex needs one on any handler whose return type would
  otherwise be inferred through a cycle; `none` lets the `returns` validator do the checking. -/
  returns : Option TsType := none
  /-- The statements of the handler body. -/
  body : List Statement

/-- Lays out an async arrow function. Unlike the pre-`Doc` printer this carries no baked-in
nesting level, so a handler renders correctly wherever it is placed. -/
def asyncHandlerDoc (handler : AsyncHandler) : Doc :=
  .concat [.text "async (", Doc.joinWith ", " (handler.parameters.map parameterDoc), .text ")",
    match handler.returns with
    | none => Doc.empty
    | some type => .concat [.text ": ", typeDoc type],
    .text " => ", statementsBlock handler.body]

/-- A Convex `{ args, returns, handler }` record exported for a registrar to wrap. -/
structure EndpointDefinition where
  /-- The exported binding name. -/
  name : String
  /-- The argument validators, keyed by argument name. -/
  arguments : List (String × Expr)
  /-- The return validator. -/
  returns : Expr
  /-- The handler implementation. -/
  handler : AsyncHandler

/-- Lays out an endpoint definition as an exported object literal, newline-terminated. -/
def endpointDefinitionDoc (endpoint : EndpointDefinition) : Doc :=
  .concat [
    .text ("export const " ++ endpoint.name ++ " = "),
    Doc.blockLines [
      .concat [.text "args: ", exprDoc (.object endpoint.arguments), .text ","],
      .concat [.text "returns: ", exprDoc endpoint.returns, .text ","],
      .concat [.text "handler: ", asyncHandlerDoc endpoint.handler, .text ","]],
    .text "\n"]

/-- Renders an endpoint definition as exported TypeScript source. -/
def emitEndpointDefinition (endpoint : EndpointDefinition) : String :=
  Doc.render (endpointDefinitionDoc endpoint)

end Mythroads.Convex.TypeScript
