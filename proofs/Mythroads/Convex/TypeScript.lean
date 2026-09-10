namespace Mythroads.Convex.TypeScript

inductive TsType where
  | void
  | boolean
  | number
  | string
  | literalString (value : String)
  | named (name : String)
  | id (table : String)
  | object (fields : List (String × TsType))
  | array (inner : TsType)
  | union (members : List TsType)
  | promise (inner : TsType)
  deriving Repr

structure Parameter where
  name : String
  type : TsType
  deriving Repr

inductive Expr where
  | identifier (name : String)
  | boolean (value : Bool)
  | string (value : String)
  | number (value : Nat)
  | null
  | undefined
  | property (target : Expr) (name : String)
  | optionalProperty (target : Expr) (name : String)
  | index (target index : Expr)
  | call (callee : Expr) (arguments : List Expr)
  | new (constructor : String) (arguments : List Expr)
  | await (value : Expr)
  | prefix (operator : String) (value : Expr)
  | binary (left : Expr) (operator : String) (right : Expr)
  | conditional (condition whenTrue whenFalse : Expr)
  | arrow (parameters : List String) (body : Expr)
  | object (fields : List (String × Expr))
  | array (values : List Expr)
  | spread (value : Expr)
  | asConst (value : Expr)
  deriving Repr

inductive Statement where
  | constDecl (name : String) (value : Expr)
  | constDeclTyped (name : String) (type : TsType) (value : Expr)
  | letDecl (name : String) (value : Expr)
  | constObjectRest (omitted : List String) (rest : String) (source : Expr)
  | assign (target value : Expr)
  | expression (value : Expr)
  | voidValue (value : Expr)
  | ifThen (condition : Expr) (body : List Statement)
  | ifElse (condition : Expr) (whenTrue whenFalse : List Statement)
  | throw (error : Expr)
  | return (value : Expr)
  | returnVoid
  | break
  | switch (value : Expr) (cases : List (String × List Statement))
  | forOf (binding : String) (values : Expr) (body : List Statement)
  | whileDo (condition : Expr) (body : List Statement)
  deriving Repr

structure Function where
  isExported : Bool := true
  isAsync : Bool := true
  name : String
  parameters : List Parameter
  returns : TsType
  body : List Statement
  deriving Repr

def join (separator : String) : List String → String
  | [] => ""
  | [value] => value
  | value :: rest => value ++ separator ++ join separator rest

def quote (value : String) : String :=
  "'" ++ (value.replace "\\" "\\\\").replace "'" "\\'" ++ "'"

partial def emitType : TsType → String
  | .void => "void"
  | .boolean => "boolean"
  | .number => "number"
  | .string => "string"
  | .literalString value => quote value
  | .named name => name
  | .id table => s!"Id<{quote table}>"
  | .object fields =>
      "{ " ++ join "; " (fields.map fun (name, type) => s!"{name}: {emitType type}") ++ " }"
  | .array inner => s!"{emitType inner}[]"
  | .union members => join " | " (members.map emitType)
  | .promise inner => s!"Promise<{emitType inner}>"

partial def emitExpr : Expr → String
  | .identifier name => name
  | .boolean value => if value then "true" else "false"
  | .string value => quote value
  | .number value => toString value
  | .null => "null"
  | .undefined => "undefined"
  | .property target name => s!"{emitExpr target}.{name}"
  | .optionalProperty target name => s!"{emitExpr target}?.{name}"
  | .index target index => s!"{emitExpr target}[{emitExpr index}]"
  | .call callee arguments =>
      s!"{emitExpr callee}({join ", " (arguments.map emitExpr)})"
  | .new constructor arguments =>
      s!"new {constructor}({join ", " (arguments.map emitExpr)})"
  | .await value => s!"await {emitExpr value}"
  | .prefix operator value => s!"({operator}{emitExpr value})"
  | .binary left operator right => s!"({emitExpr left} {operator} {emitExpr right})"
  | .conditional condition whenTrue whenFalse =>
      s!"({emitExpr condition} ? {emitExpr whenTrue} : {emitExpr whenFalse})"
  | .arrow parameters body => s!"({join ", " parameters}) => {emitExpr body}"
  | .object fields =>
      "{ " ++ join ", " (fields.map fun (name, value) => s!"{name}: {emitExpr value}") ++ " }"
  | .array values => "[" ++ join ", " (values.map emitExpr) ++ "]"
  | .spread value => s!"...{emitExpr value}"
  | .asConst value => s!"{emitExpr value} as const"

def indentation (depth : Nat) : String := String.ofList (List.replicate (depth * 4) ' ')

mutual
  partial def emitStatement (depth : Nat) : Statement → String
    | .constDecl name value => s!"{indentation depth}const {name} = {emitExpr value}\n"
    | .constDeclTyped name type value =>
        s!"{indentation depth}const {name}: {emitType type} = {emitExpr value}\n"
    | .letDecl name value => s!"{indentation depth}let {name} = {emitExpr value}\n"
    | .constObjectRest omitted rest source =>
        s!"{indentation depth}const \u007b {join ", " omitted}, ...{rest} \u007d = {emitExpr source}\n"
    | .assign target value => s!"{indentation depth}{emitExpr target} = {emitExpr value}\n"
    | .expression value => s!"{indentation depth}{emitExpr value}\n"
    | .voidValue value => s!"{indentation depth}void {emitExpr value}\n"
    | .ifThen condition body =>
        s!"{indentation depth}if ({emitExpr condition}) \u007b\n" ++
        emitStatements (depth + 1) body ++ s!"{indentation depth}\u007d\n"
    | .ifElse condition whenTrue whenFalse =>
        s!"{indentation depth}if ({emitExpr condition}) \u007b\n" ++
        emitStatements (depth + 1) whenTrue ++ s!"{indentation depth}\u007d else \u007b\n" ++
        emitStatements (depth + 1) whenFalse ++ s!"{indentation depth}\u007d\n"
    | .throw error => s!"{indentation depth}throw {emitExpr error}\n"
    | .return value => s!"{indentation depth}return {emitExpr value}\n"
    | .returnVoid => s!"{indentation depth}return\n"
    | .break => s!"{indentation depth}break\n"
    | .switch value cases =>
        s!"{indentation depth}switch ({emitExpr value}) \u007b\n" ++
        join "" (cases.map fun (label, body) =>
          s!"{indentation (depth + 1)}case {quote label}: \u007b\n" ++
          emitStatements (depth + 2) body ++
          s!"{indentation (depth + 1)}\u007d\n") ++
        s!"{indentation depth}\u007d\n"
    | .forOf binding values body =>
        s!"{indentation depth}for (const {binding} of {emitExpr values}) \u007b\n" ++
        emitStatements (depth + 1) body ++ s!"{indentation depth}\u007d\n"
    | .whileDo condition body =>
        s!"{indentation depth}while ({emitExpr condition}) \u007b\n" ++
        emitStatements (depth + 1) body ++ s!"{indentation depth}\u007d\n"

  partial def emitStatements (depth : Nat) (statements : List Statement) : String :=
    join "" (statements.map (emitStatement depth))
end

def emitParameter (parameter : Parameter) : String :=
  s!"{parameter.name}: {emitType parameter.type}"

def emitFunction (function : Function) : String :=
  let exportPrefix := if function.isExported then "export " else ""
  let asyncPrefix := if function.isAsync then "async " else ""
  exportPrefix ++ asyncPrefix ++ "function " ++ function.name ++ "(" ++
  join ", " (function.parameters.map emitParameter) ++ s!"): {emitType function.returns} \u007b\n" ++
  emitStatements 1 function.body ++ "}\n"

def emitTypeAlias (name : String) (type : TsType) : String :=
  s!"export type {name} = {emitType type}\n"

structure AsyncHandler where
  parameters : List Parameter
  body : List Statement

def emitAsyncHandler (handler : AsyncHandler) : String :=
  "async (" ++ join ", " (handler.parameters.map emitParameter) ++ ") => \u007b\n" ++
  emitStatements 2 handler.body ++ "    \u007d"

structure EndpointDefinition where
  name : String
  arguments : List (String × Expr)
  returns : Expr
  handler : AsyncHandler

def emitEndpointDefinition (endpoint : EndpointDefinition) : String :=
  s!"export const {endpoint.name} = \u007b\n" ++
  "    args: " ++ emitExpr (.object endpoint.arguments) ++ ",\n" ++
  "    returns: " ++ emitExpr endpoint.returns ++ ",\n" ++
  "    handler: " ++ emitAsyncHandler endpoint.handler ++ ",\n" ++
  "\u007d\n"

end Mythroads.Convex.TypeScript
