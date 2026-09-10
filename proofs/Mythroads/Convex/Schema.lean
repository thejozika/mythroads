namespace Mythroads.Convex.Schema

inductive Validator where
  | any
  | null
  | boolean
  | number
  | int64
  | string
  | id (table : String)
  | literalString (value : String)
  | literalNumber (value : Int)
  | optional (inner : Validator)
  | array (inner : Validator)
  | object (fields : List (String × Validator))
  | union (members : List Validator)
  | external (name : String)
  deriving Repr

structure Index where
  name : String
  fields : List String
  deriving Repr, DecidableEq

structure Table where
  name : String
  document : Validator
  indexes : List Index := []
  deriving Repr

structure AppSchema where
  targetConvexVersion : String
  tables : List Table
  deriving Repr

def object (fields : List (String × Validator)) : Validator := .object fields
def optional (inner : Validator) : Validator := .optional inner
def literals (values : List String) : Validator := .union (values.map .literalString)
def index (name : String) (fields : List String) : Index := { name, fields }

end Mythroads.Convex.Schema
