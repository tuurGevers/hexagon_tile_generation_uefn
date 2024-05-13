using { /Fortnite.com/Devices }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { /Fortnite.com/Devices/CreativeAnimation }

Resource :=class:
    tile:Tile
    Asset: creative_prop_asset
    HitPlayer: audio_player_device
    BreakPlayer: audio_player_device
    BreakNS: creative_prop_asset
    var Prop: creative_prop = creative_prop{}
    var FullHP: float = 120.0
    var HP: float = 100.0
    var HasScaled:logic = false
    var RespawnTime: float = 10.0
    Main:Tiles

    Spawn():void=
        set Main.AliveProps+=1
        set Prop = SpawnTarget(vector3{X:=tile.Position.X,Y:=tile.Position.Y,Z:=tile.Position.Z+500.0}, Asset)
        set HP = FullHP
        set HasScaled = false

    TakeDamage(Damage:float, Player:agent)<suspends>:void=
        if(FC:=Player.GetFortCharacter[]):
            if(HP<=0.0):
                return
            set HP = HP - Damage
            HPPercentage := HP / FullHP
            HitPlayer.Play()
            spawn. ShakeTreeAnim()
            if(HPPercentage < 0.5 and HasScaled = false):
                set HasScaled = true
                Prop.MoveTo(transform{
                    Translation:= Prop.GetTransform().Translation,
                    Rotation:= Prop.GetTransform().Rotation,
                    Scale:= vector3{X:=0.5,Y:=0.5,Z:=0.5}
                },0.5)
            if (HP <= 0.0):
                BreakPlayer.Play()
                Prop.Dispose()
                set Main.AliveProps-=1
                TempProp := SpawnTarget(vector3{X:=tile.Position.X,Y:=tile.Position.Y,Z:=tile.Position.Z+500.0},BreakNS,?Rotation:=FC.GetTransform().Rotation )
                Sleep(2.0)
                TempProp.Dispose()
            

    ShakeTreeAnim()<suspends>: void =
        # Store original transform for reference
        originalTransform := Prop.GetTransform()

        # First movement: tilt the tree to one side
        if(Prop.IsValid[]):
            spawn. Prop.MoveTo(
                transform{
                    Translation := originalTransform.Translation,
                    Rotation := originalTransform.Rotation.ApplyRoll(DegreesToRadians(15.0)),  # Roll the tree by 15 degrees
                    Scale := originalTransform.Scale  # No scale change needed here
                },
                0.11  # Duration of the move
            )
            Sleep(0.10)  # Wait for the first move to complete

        # Second movement: tilt the tree to the opposite side
        if(Prop.IsValid[]):
            spawn. Prop.MoveTo(
                transform{
                    Translation := originalTransform.Translation,
                    Rotation := originalTransform.Rotation.ApplyRoll(DegreesToRadians(-15.0)),  # Roll to the opposite side
                    Scale := originalTransform.Scale
                },
                0.11  # Duration of the move
            )
            Sleep(0.10)  # Wait for the second move to complete

        # Third movement: return to original position
        if(Prop.IsValid[]):
            spawn. Prop.MoveTo(
                transform{
                    Translation := originalTransform.Translation,
                    Rotation := originalTransform.Rotation,  # Return to original rotation
                    Scale := originalTransform.Scale  # Return to original scale
                },
                0.11  # Duration of the move
            )
    
    
       