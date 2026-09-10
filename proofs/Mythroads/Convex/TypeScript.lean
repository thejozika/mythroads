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
  | union (members : List TsType)
  | promise (inner : TsType)
  deriving Repr

structure Parameter where
  name : String
  type : TsType
  deriving Repr

inductive Expr where
  | identifier (name : String)
  | string (value : String)
  | number (value : Nat)
  | null
  | undefined
  | property (target : Expr) (name : String)
  | call (callee : Expr) (arguments : List Expr)
  | new (constructor : String) (arguments : List Expr)
  | await (value : Expr)
  | prefix (operator : String) (value : Expr)
  | binary (left : Expr) (operator : String) (right : Expr)
  | conditional (condition whenTrue whenFalse : Expr)
  | arrow (parameters : List String) (body : Expr)
  | object (fields : List (String × Expr))
  deriving Repr

inductive Statement where
  | constDecl (name : String) (value : Expr)
  | expression (value : Expr)
  | ifThen (condition : Expr) (body : List Statement)
  | throw (error : Expr)
  | return (value : Expr)
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
  | .union members => join " | " (members.map emitType)
  | .promise inner => s!"Promise<{emitType inner}>"

partial def emitExpr : Expr → String
  | .identifier name => name
  | .string value => quote value
  | .number value => toString value
  | .null => "null"
  | .undefined => "undefined"
  | .property target name => s!"{emitExpr target}.{name}"
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

def indentation (depth : Nat) : String := String.ofList (List.replicate (depth * 4) ' ')

mutual
  partial def emitStatement (depth : Nat) : Statement → String
    | .constDecl name value => s!"{indentation depth}const {name} = {emitExpr value}\n"
    | .expression value => s!"{indentation depth}{emitExpr value}\n"
    | .ifThen condition body =>
        s!"{indentation depth}if ({emitExpr condition}) \u007b\n" ++
        emitStatements (depth + 1) body ++ s!"{indentation depth}\u007d\n"
    | .throw error => s!"{indentation depth}throw {emitExpr error}\n"
    | .return value => s!"{indentation depth}return {emitExpr value}\n"

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

end Mythroads.Convex.TypeScript
