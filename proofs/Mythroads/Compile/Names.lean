import Lean

/-!
# TypeScript identifiers for Lean names

The compiled engine is read by people, so the names in it matter. A Lean declaration
such as `Mythroads.Engine.Lobby.join` becomes `Lobby_join`, not
`Mythroads_Engine_Lobby_join`: the emitted file *is* the engine namespace, so restating
it on every line is noise.

Three prefixes are stripped or shortened, in order:

| Lean prefix | TypeScript |
|---|---|
| `Mythroads.Engine.` | nothing (`step`, `State`, `Lobby_join`) |
| `Mythroads.Game.` | `Game_` (`Game_World_nodes`) |
| `Mythroads.` | nothing (`ItemId` and friends are abbreviations anyway) |
| anything else | fully mangled (`List_elem__redArg`) |

Shortening can in principle make two Lean names collide; `Mythroads.Compile.Driver`
checks for that and fails the build rather than emitting a file where one definition
silently shadows another.
-/

namespace Mythroads.Compile

open Lean

/-- The TypeScript spelling of one character of a Lean name. -/
def mangleChar (c : Char) : String :=
  if c.isAlphanum then c.toString
  else match c with
    | '?' => "_q"
    | '!' => "_x"
    | '\'' => "_p"
    | '@' => "_at"
    | _ => "_"

/-- Mangle a raw string into a legal TypeScript identifier. -/
def mangleString (s : String) : String :=
  let base := s.foldl (fun acc c => acc ++ mangleChar c) ""
  if base.isEmpty then "_" else if base.front.isDigit then "_" ++ base else base

/--
Reserved words that a Lean declaration could otherwise be emitted as. A Lean `def new`
would produce `function new(...)`, which does not parse; such names get a trailing `_`.
-/
def reservedWords : List String :=
  ["break", "case", "catch", "class", "const", "continue", "debugger", "default", "delete",
    "do", "else", "enum", "export", "extends", "false", "finally", "for", "function", "if",
    "import", "in", "instanceof", "new", "null", "return", "super", "switch", "this", "throw",
    "true", "try", "typeof", "var", "void", "while", "with", "let", "static", "yield", "await",
    "implements", "interface", "package", "private", "protected", "public", "undefined"]

/-- Append `_` to anything that would collide with a TypeScript keyword. -/
def avoidReserved (s : String) : String :=
  if reservedWords.contains s then s ++ "_" else s

/-- Drop `prefix` from `s` when it is there. -/
private def dropPrefix (s p : String) : Option String :=
  if s.startsWith p then some ((s.drop p.length).toString) else none

/--
The TypeScript identifier for a Lean declaration or inductive, with the engine's own
namespaces shortened as described in the module docstring.
-/
def tsIdent (n : Name) : String :=
  let s := n.toString
  let shortened :=
    match dropPrefix s "Mythroads.Engine." with
    | some rest => mangleString rest
    | none =>
      match dropPrefix s "Mythroads.Game." with
      | some rest => "Game_" ++ mangleString rest
      | none =>
        match dropPrefix s "Mythroads." with
        | some rest => mangleString rest
        | none => mangleString s
  avoidReserved shortened

/-- The discriminant string a constructor is tagged with: its last name component. -/
def ctorTag (ctorName : Name) : String := ctorName.getString!

/-- A TypeScript identifier for a Lean binder name, used for locals and parameters. -/
def localIdent (binder : Name) : String :=
  let raw := binder.eraseMacroScopes.toString
  let cleaned := raw.foldl (fun acc c =>
    if c.isAlphanum then acc ++ c.toString
    else if c == '.' || c == '_' then acc ++ "_"
    else acc) ""
  avoidReserved (if cleaned.isEmpty then "x" else
    if cleaned.front.isDigit then "_" ++ cleaned else cleaned)

/-- Does `id` occur in `body` as a whole identifier rather than inside a longer name? -/
def occursAsIdent (body id : String) : Bool := Id.run do
  let isIdentChar (c : Char) := c.isAlphanum || c == '_' || c == '$'
  let parts := (body.splitOn id).toArray
  if parts.size < 2 then return false
  for i in [0:parts.size - 1] do
    let before := parts[i]!
    let after := parts[i + 1]!
    let okBefore := before.isEmpty || !(isIdentChar before.back)
    let okAfter := after.isEmpty || !(isIdentChar after.front)
    if okBefore && okAfter then return true
  return false

end Mythroads.Compile
