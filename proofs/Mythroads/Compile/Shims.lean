import Mythroads.Compile.Names

/-!
# Primitive shims

The compiler stops at Lean's primitives. Everything above them is compiled from LCNF;
everything at or below them is replaced by a TypeScript template from the table here,
and anything that is *neither* — an `@[extern]` declaration with no shim — is a hard
build failure rather than a call to a function that was never emitted.

## Numbers

`Nat` and `Int` are both emitted as `number`. Every quantity the engine stores is a
board index, a hit point, a gold piece, a basis point or a Park–Miller state below
2^31, so the exact-integer range of a double (2^53) is never approached. This is a
*representation choice, not a proof*: nothing in Lean currently forbids a future rule
from computing a larger `Nat`, and if one ever does, the parity oracle in
`tests/engine/` is what will catch it. The alternative, `bigint`, serialises poorly
into Convex documents and reads badly in game code, so it is not used.

Subtraction, division and modulus are truncated `Nat` operations, so they need the
`natSub` / `natDiv` / `natMod` helpers rather than the JavaScript operators.

## Strings

A Lean `String` is a JavaScript string, and `String.length` and `String.toList` count
Unicode code points exactly as Lean does.

Lean indexes into a string by UTF-8 byte offset. The compiled engine indexes by UTF-16
code unit instead, which is what JavaScript can do natively, and the whole family of
position operations is shimmed *together* so that the two never mix: `utf8ByteSize`,
`extract`, `Slice.mk`, `decodeChar`, `Pos.set` and `Char.utf8Size` all speak UTF-16
offsets. Nothing in the engine inspects an individual byte, so the choice of unit is
invisible above these shims; a slice is simply the substring it denotes.
-/

namespace Mythroads.Compile

open Lean

/-- One primitive: how many computationally relevant arguments it takes, and its template. -/
structure Shim where
  /-- Number of arguments the template consumes; call sites are eta-expanded to match. -/
  arity : Nat
  /-- TypeScript with `$0`, `$1`, … standing for the arguments. -/
  tmpl : String
  deriving Inhabited

/-- Arithmetic and comparison on `Nat`, which is a `number`. -/
def natShims : List (Name × Shim) :=
  [ (``Nat.add, ⟨2, "($0 + $1)"⟩),
    (``Nat.sub, ⟨2, "natSub($0, $1)"⟩),
    (``Nat.mul, ⟨2, "($0 * $1)"⟩),
    (``Nat.div, ⟨2, "natDiv($0, $1)"⟩),
    (``Nat.mod, ⟨2, "natMod($0, $1)"⟩),
    (``Nat.pow, ⟨2, "$0 ** $1"⟩),
    (``Nat.decEq, ⟨2, "($0 === $1)"⟩),
    (``Nat.decLt, ⟨2, "($0 < $1)"⟩),
    (``Nat.decLe, ⟨2, "($0 <= $1)"⟩),
    (``Nat.beq, ⟨2, "($0 === $1)"⟩),
    (``Nat.ble, ⟨2, "($0 <= $1)"⟩),
    (``Nat.blt, ⟨2, "($0 < $1)"⟩),
    (``Nat.min, ⟨2, "Math.min($0, $1)"⟩),
    (``Nat.max, ⟨2, "Math.max($0, $1)"⟩),
    (``Nat.shiftRight, ⟨2, "Math.floor($0 / 2 ** $1)"⟩),
    (``Nat.shiftLeft, ⟨2, "($0 * 2 ** $1)"⟩),
    (``Nat.repr, ⟨1, "String($0)"⟩),
    (``Nat.reprFast, ⟨1, "String($0)"⟩) ]

/--
`Int` as a `number`. `Int.ofNat` and `Int.negSucc` are the two constructors, so they
are shimmed rather than emitted as tagged objects; `Int.tdiv` and `Int.tmod` truncate
toward zero, `Int.ediv` and `Int.emod` are the Euclidean pair, and `Int.fdiv` and
`Int.fmod` round toward negative infinity, exactly as in `Init.Data.Int`.
-/
def intShims : List (Name × Shim) :=
  [ (``Int.ofNat, ⟨1, "$0"⟩),
    (``Int.negSucc, ⟨1, "(-1 - $0)"⟩),
    (``Int.neg, ⟨1, "(-$0)"⟩),
    (``Int.add, ⟨2, "($0 + $1)"⟩),
    (``Int.sub, ⟨2, "($0 - $1)"⟩),
    (``Int.mul, ⟨2, "($0 * $1)"⟩),
    (``Int.tdiv, ⟨2, "intTruncDiv($0, $1)"⟩),
    (``Int.tmod, ⟨2, "intTruncMod($0, $1)"⟩),
    (``Int.ediv, ⟨2, "intEuclidDiv($0, $1)"⟩),
    (``Int.emod, ⟨2, "intEuclidMod($0, $1)"⟩),
    (``Int.fdiv, ⟨2, "intFloorDiv($0, $1)"⟩),
    (``Int.fmod, ⟨2, "intFloorMod($0, $1)"⟩),
    (``Int.decEq, ⟨2, "($0 === $1)"⟩),
    (``Int.decLt, ⟨2, "($0 < $1)"⟩),
    (``Int.decLe, ⟨2, "($0 <= $1)"⟩),
    (``Int.natAbs, ⟨1, "Math.abs($0)"⟩),
    (``Int.toNat, ⟨1, "Math.max(0, $0)"⟩),
    (``Int.repr, ⟨1, "String($0)"⟩) ]

/-- Strings, including the byte-indexed slice trio that the compiler treats as one unit. -/
def stringShims : List (Name × Shim) :=
  [ (``String.decEq, ⟨2, "($0 === $1)"⟩),
    (``String.append, ⟨2, "($0 + $1)"⟩),
    (``String.length, ⟨1, "leanChars($0).length"⟩),
    (``String.toList, ⟨1, "leanChars($0)"⟩),
    (``String.ofList, ⟨1, "leanString($0)"⟩),
    (``String.utf8ByteSize, ⟨1, "$0.length"⟩),
    (``String.extract, ⟨3, "$0.slice($1, $2)"⟩),
    (``String.Slice.mk, ⟨4, "$0.slice($1, $2)"⟩),
    (``String.Slice.toString, ⟨1, "$0"⟩),
    (``String.Internal.toArray, ⟨1, "leanChars($0)"⟩),
    (``String.Slice.trimAscii, ⟨1, "leanTrimAscii($0)"⟩),
    (``String.Slice.trimAsciiStart, ⟨1, "$0.replace(/^[\\t\\n\\r ]+/, \"\")"⟩),
    (``String.Slice.trimAsciiEnd, ⟨1, "$0.replace(/[\\t\\n\\r ]+$/, \"\")"⟩),
    (``String.decidableLT, ⟨2, "($0 < $1)"⟩),
    (``String.decodeChar, ⟨2, "leanCharAt($0, $1)"⟩),
    (``String.Pos.set, ⟨3, "leanCharSet($0, $1, $2)"⟩),
    (``Char.utf8Size, ⟨1, "leanCharWidth($0)"⟩) ]

/--
Booleans, machine words (a `Char` is a `UInt32` after monomorphisation), and the two
sequence types. A Lean `Array` is a structure wrapping a `List`, and a `List` is already
a JavaScript array, so `Array.mk` and `Array.toList` are both the identity and the two
types share one representation.
-/
def structuralShims : List (Name × Shim) :=
  [ (``Bool.not, ⟨1, "(!$0)"⟩),
    (``Bool.and, ⟨2, "($0 && $1)"⟩),
    (``Bool.or, ⟨2, "($0 || $1)"⟩),
    (``UInt32.decEq, ⟨2, "($0 === $1)"⟩),
    (``UInt32.decLt, ⟨2, "($0 < $1)"⟩),
    (``UInt32.decLe, ⟨2, "($0 <= $1)"⟩),
    (``UInt32.add, ⟨2, "(($0 + $1) % 4294967296)"⟩),
    (``UInt32.toNat, ⟨1, "$0"⟩),
    (``UInt32.ofNatLT, ⟨1, "$0"⟩),
    (``Char.ofNatAux, ⟨2, "$0"⟩),
    (``Char.toNat, ⟨1, "$0"⟩),
    (``Array.mk, ⟨1, "$0"⟩),
    (``Array.mkEmpty, ⟨1, "[]"⟩),
    (``Array.emptyWithCapacity, ⟨1, "[]"⟩),
    (``Array.push, ⟨2, "[...$0, $1]"⟩),
    (``Array.pop, ⟨1, "$0.slice(0, -1)"⟩),
    (``Array.size, ⟨1, "$0.length"⟩),
    (``Array.toList, ⟨1, "$0"⟩),
    (``List.toArray, ⟨1, "$0"⟩),
    (``List.length, ⟨1, "$0.length"⟩),
    (``List.lengthTR, ⟨1, "$0.length"⟩),
    (``List.append, ⟨2, "[...$0, ...$1]"⟩),
    (``List.reverse, ⟨1, "[...$0].reverse()"⟩),
    (`List.length._redArg, ⟨1, "$0.length"⟩),
    (`List.lengthTR._redArg, ⟨1, "$0.length"⟩),
    (`List.reverse._redArg, ⟨1, "[...$0].reverse()"⟩),
    (`List.append._redArg, ⟨2, "[...$0, ...$1]"⟩),
    (``panic, ⟨1, "leanPanic($0)"⟩),
    (``panicCore, ⟨1, "leanPanic($0)"⟩) ]

/-- Every primitive the compiler knows, keyed by declaration name. -/
def shimTable : Std.HashMap Name Shim :=
  Std.HashMap.ofList (natShims ++ intShims ++ stringShims ++ structuralShims)

/--
The hand-written runtime the emitted code calls into, one helper per entry. Only the
helpers a given compilation actually reaches are written out, so the generated file
never carries a definition nobody calls.
-/
def runtimeHelpers : List (String × String) :=
  [
    ("natSub",
      "/** Truncating `Nat` subtraction: Lean's `a - b` is `0` when `b` exceeds `a`. */\nconst natSub = (a: number, b: number): number => (a > b ? a - b : 0)"),
    ("natDiv",
      "/** Lean's `Nat` division, which is `0` rather than an error when dividing by zero. */\nconst natDiv = (a: number, b: number): number => (b === 0 ? 0 : Math.floor(a / b))"),
    ("natMod",
      "/** Lean's `Nat` modulus, which is the dividend itself when the divisor is zero. */\nconst natMod = (a: number, b: number): number => (b === 0 ? a : a % b)"),
    ("intTruncDiv",
      "/** Lean's `Int.tdiv`: rounding toward zero, `0` on a zero divisor. */\nconst intTruncDiv = (a: number, b: number): number => (b === 0 ? 0 : Math.trunc(a / b))"),
    ("intTruncMod",
      "/** Lean's `Int.tmod`: the remainder of `intTruncDiv`. */\nconst intTruncMod = (a: number, b: number): number => (b === 0 ? a : a % b)"),
    ("intEuclidDiv",
      "/** Lean's `Int.ediv`: the Euclidean quotient, whose remainder is never negative. */\nconst intEuclidDiv = (a: number, b: number): number =>\n    b === 0 ? 0 : b > 0 ? Math.floor(a / b) : -Math.floor(a / -b)"),
    ("intEuclidMod",
      "/** Lean's `Int.emod`: the Euclidean remainder, always in `[0, |b|)`. */\nconst intEuclidMod = (a: number, b: number): number =>\n    b === 0 ? a : ((a % b) + Math.abs(b)) % Math.abs(b)"),
    ("intFloorDiv",
      "/** Lean's `Int.fdiv`: rounding toward negative infinity. */\nconst intFloorDiv = (a: number, b: number): number => (b === 0 ? 0 : Math.floor(a / b))"),
    ("intFloorMod",
      "/** Lean's `Int.fmod`: the remainder of `intFloorDiv`. */\nconst intFloorMod = (a: number, b: number): number => (b === 0 ? a : a - b * Math.floor(a / b))"),
    ("leanChars",
      "/** `String.toList`: the Unicode code points of a string, which is what a Lean `Char` is. */\nconst leanChars = (s: string): number[] => Array.from(s, (c) => c.codePointAt(0) ?? 0)"),
    ("leanString",
      "/** `String.ofList`: the inverse of `leanChars`. */\nconst leanString = (cs: number[]): string => cs.map((c) => String.fromCodePoint(c)).join('')"),
    ("leanTrimAscii",
      "/** `String.Slice.trimAscii`: Lean trims exactly space, tab, carriage return and newline. */\nconst leanTrimAscii = (s: string): string => s.replace(/^[\\t\\n\\r ]+/, '').replace(/[\\t\\n\\r ]+$/, '')"),
    ("leanCharAt",
      "/** The Unicode code point at a UTF-16 offset, which is what Lean's `decodeChar` returns. */\nconst leanCharAt = (s: string, index: number): number => s.codePointAt(index) ?? 0"),
    ("leanCharWidth",
      "/** How many UTF-16 code units a code point occupies, the unit this engine indexes in. */\nconst leanCharWidth = (c: number): number => (c > 0xffff ? 2 : 1)"),
    ("leanCharSet",
      "/** `String.Pos.set`: replace the character at a UTF-16 offset. */\nconst leanCharSet = (s: string, index: number, c: number): string =>\n    s.slice(0, index) +\n    String.fromCodePoint(c) +\n    s.slice(index + leanCharWidth(leanCharAt(s, index)))"),
    ("leanPanic",
      "/** Lean's `panic!`, which the engine reaches only if a proved-total lookup were to fail. */\nconst leanPanic = (message: string): never => {\n    throw new Error(`Mythroads engine panic: ${message}`)\n}")
  ]

/-- The helpers `body` uses, in declaration order, closed under their own uses. -/
def runtimeFor (body : String) : String := Id.run do
  let mut needed := body
  let mut chosen := #[]
  for _ in [0:3] do
    chosen := #[]
    let mut text := ""
    for (name, source) in runtimeHelpers do
      if occursAsIdent needed name then
        chosen := chosen.push source
        text := text ++ source
    needed := body ++ text
  return String.intercalate "\n\n" chosen.toList

end Mythroads.Compile
