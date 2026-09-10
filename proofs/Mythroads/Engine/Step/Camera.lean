import Mythroads.Engine.Event

/-!
# The shared camera

Camera commands are the one part of the alphabet that is *not* game history. They
travel through the same gateway and the same three gates, but `Event.durable` is
`false` for all three, so nothing is appended to the log and a replay of the log
reproduces a room whose camera is simply absent. That is the whole content of
`camera_is_ephemeral` in `Mythroads.Engine.Theorems`.

They are still turn-gated, because the generated `requireCameraControl` demands the
active player: the shared screen follows whoever is playing, and a phone that is not
on turn cannot drag the view out from under the table.

Coordinates are held in hundredths of a world unit, exactly as `Game.World.Point` is,
so the pan step of `0.9` and the bounds of `±7` by `±5.5` are integers here.
-/

namespace Mythroads.Engine.CameraStep

open Mythroads.Game

/-- One pan step, in hundredths of a world unit. -/
def panStep : Int := 90

/-- Clamp a value into an inclusive range. -/
def clamp (low high value : Int) : Int := max low (min high value)

/-- `camera.toggle`: swap follow and free mode, re-centring on the active hero's node. -/
def toggle (s : State) (p : PlayerState) : Outcome :=
  let landmark := node p.position
  let next : Camera :=
    match s.camera with
    | none => { free := true, targetX := landmark.point.x, targetZ := landmark.point.z,
                distance := 8 }
    | some camera =>
        { camera with
            free := not camera.free, targetX := landmark.point.x, targetZ := landmark.point.z }
  .ok ({ s with camera := some next }, [.persistCamera, .notify "camera.toggle"])

/-- `camera.move`: pan the free camera, clamped to the table the board sits on. -/
def move (s : State) (direction : Direction) : Outcome :=
  match s.camera with
  | some camera =>
      if !camera.free then .error .cameraNotFree
      else
        let dx : Int := match direction with
          | .left => -panStep | .right => panStep | _ => 0
        let dz : Int := match direction with
          | .up => -panStep | .down => panStep | _ => 0
        .ok ({ s with camera := some { camera with
                 targetX := clamp (-700) 700 (camera.targetX + dx),
                 targetZ := clamp (-550) 550 (camera.targetZ + dz) } },
             [.persistCamera, .notify "camera.move"])
  | none => .error .cameraNotFree

/-- `camera.zoom`: one notch in or out, held between five and fifteen units. -/
def zoom (s : State) (delta : Zoom) : Outcome :=
  match s.camera with
  | some camera =>
      if !camera.free then .error .cameraNotFree
      else
        .ok ({ s with camera := some { camera with
                 distance := (clamp 5 15 ((camera.distance : Int) + delta.delta)).toNat } },
             [.persistCamera, .notify "camera.zoom"])
  | none => .error .cameraNotFree

end Mythroads.Engine.CameraStep
