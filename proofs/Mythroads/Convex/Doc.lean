namespace Mythroads.Convex

/-! # Explicit-layout documents

`Doc` is the layout layer that sits between the TypeScript syntax tree and the emitted string.
Before it existed, every printer in `Convex/TypeScript.lean` threaded a `depth : Nat` by hand and
pasted `indentation depth` in front of each line, so a nested construct only rendered correctly at
the exact depth its author happened to test. `Doc` makes indentation a property of the *tree*:
`Doc.indent` opens a nesting level and `Doc.line` emits a newline followed by however much
indentation is currently open.

Every break in a `Doc` is authored explicitly. This is deliberately *not* `Std.Format`, whose
`group`/`fill` combinators pick breaks from a target column width: generated files are checked into
the repository and byte-compared, so the renderer must not depend on a width parameter or on how
deeply a subtree happens to nest. Biome remains the arbiter of final style — the emitter only has
to produce valid TypeScript with the right breaks — so a minimal four-constructor document is
enough.
-/

/-- A layout-explicit document. Rendering is a pure function of the tree: no column width, no
reflow, no locale. -/
inductive Doc where
  /-- Literal text, emitted verbatim. Must not contain a newline; use `Doc.line` for that. -/
  | text (value : String)
  /-- Sequential composition; the empty list is the identity. -/
  | concat (parts : List Doc)
  /-- A newline followed by the indentation of the enclosing `Doc.indent` levels. -/
  | line
  /-- Renders `body` one nesting level deeper. -/
  | indent (body : Doc)
  deriving Inhabited

namespace Doc

/-- Concatenation, so emitters can write `a ++ b` for two document fragments. -/
instance : Append Doc := ⟨fun a b => .concat [a, b]⟩

/-- Lets a string literal stand for `Doc.text` in emitter code. -/
instance : Coe String Doc := ⟨Doc.text⟩

/-- The empty document. -/
def empty : Doc := .concat []

/-- Interleaves `separator` between the parts. -/
def sep (separator : Doc) : List Doc → Doc
  | [] => empty
  | [only] => only
  | head :: tail => .concat [head, separator, sep separator tail]

/-- Joins parts with a literal separator that introduces no line break. -/
def joinWith (separator : String) (parts : List Doc) : Doc := sep (.text separator) parts

/-- Places each part on its own line at the current indentation. -/
def lines (parts : List Doc) : Doc := sep .line parts

/-- The indentation string for `depth` open nesting levels. Generated TypeScript uses four
spaces, matching `biome.json`'s `indentWidth`. -/
private def pad (depth : Nat) : String := String.ofList (List.replicate (depth * 4) ' ')

/-- Tail-recursive renderer accumulating into `out` at the given nesting `depth`. -/
private def render' (depth : Nat) (out : String) : Doc → String
  | .text value => out ++ value
  | .line => out ++ "\n" ++ pad depth
  | .indent body => render' (depth + 1) out body
  | .concat parts => parts.foldl (fun acc part => render' depth acc part) out

/-- Renders a document to TypeScript source starting at the outermost nesting level. -/
def render (doc : Doc) : String := render' 0 "" doc

/-- A brace-delimited block whose `body` sits one level deeper, with the closing brace back at the
opening level. An empty body still breaks, which is what the pre-`Doc` printers emitted. -/
def block (body : Doc) : Doc :=
  .concat [.text "{", .indent (.concat [.line, body]), .line, .text "}"]

/-- A brace-delimited block for a possibly empty list of lines. Keeps the historical rendering of
an empty body (`{` and `}` on consecutive lines) rather than emitting a padded blank line. -/
def blockLines : List Doc → Doc
  | [] => .concat [.text "{", .line, .text "}"]
  | parts => block (lines parts)

end Doc
end Mythroads.Convex
