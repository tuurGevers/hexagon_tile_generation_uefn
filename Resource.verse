using { /Fortnite.com/Devices }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { /Fortnite.com/Devices/CreativeAnimation }

Resource := class:
    tile: Tile
    Asset: creative_prop_asset
    HitPlayer: audio_player_device
    BreakPlayer: audio_player_device
    BreakNS: creative_prop_asset
    var Prop: creative_prop = creative_prop{}
    var FullHP: float = 120.0
    var HP: float = 100.0
    var HasScaled: logic = false
    var RespawnTime: float = 10.0
    Main: Tiles

    # Method to spawn the resource
    Spawn(): void =
        set Main.AliveProps += 1
        set Prop = SpawnTarget(vector3{X := tile.Position.X, Y := tile.Position.Y, Z := tile.Position.Z + 500.0}, Asset)
        set HP = FullHP
        set HasScaled = false

    # Method to handle taking damage
    TakeDamage(Damage: float, Player: agent) <suspends>: void =
        if (FC := Player.GetFortCharacter[]):
            if (HP <= 0.0):
                return
            set HP = HP - Damage
            HPPercentage := HP / FullHP
            HitPlayer.Play()
            spawn. ShakeTreeAnim()
            if (HPPercentage < 0.5 and HasScaled = false):
                set HasScaled = true
                Prop.MoveTo(transform{
                    Translation := Prop.GetTransform().Translation,
                    Rotation := Prop.GetTransform().Rotation,
                    Scale := vector3{X := 0.5, Y := 0.5, Z := 0.5}
                }, 0.5)
            if (HP <= 0.0):
                BreakPlayer.Play()
                Prop.Dispose()
                set Main.AliveProps -= 1
                TempProp := SpawnTarget(vector3{X := tile.Position.X, Y := tile.Position.Y, Z := tile.Position.Z + 500.0}, BreakNS, ?Rotation := FC.GetTransform().Rotation)
                Sleep(2.0)
                TempProp.Dispose()

    # Coroutine for shaking animation
    Shake(rotationAngle: float, duration: float) <suspends>: void =
        if (Prop.IsValid[]):
            originalTransform := Prop.GetTransform()
            spawn. Prop.MoveTo(
                transform{
                    Translation := originalTransform.Translation,
                    Rotation := originalTransform.Rotation.ApplyRoll(DegreesToRadians(rotationAngle)),
                    Scale := originalTransform.Scale
                },
                duration
            )
            Sleep(duration-0.01)

    ShakeTreeAnim() <suspends>: void =
        # Perform the shaking animation
        Shake(10.0, 0.11)
        Shake(-10.0, 0.11)
        Shake(10.0, 0.11)
        Shake(-10.0, 0.11)

    # Method to handle respawn (optional addition)
    Respawn() <suspends>: void =
        Sleep(RespawnTime)
        Spawn()
