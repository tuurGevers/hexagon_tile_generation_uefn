using { /Fortnite.com/Devices }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { /Fortnite.com/Devices/CreativeAnimation }

ResourceType := struct:
    Asset: creative_prop_asset
    FullHP: float
    Weight: int
    BreakNS: creative_prop_asset
    HitPlayers: []audio_player_device
    BreakPlayer: audio_player_device
    ItemDrop:string
    TotalDropAmount:int

Resource := class:
    tile: Tile
    var Prop: creative_prop = creative_prop{}
    var HP: float = 100.0
    var HasScaled: logic = false
    var RespawnTime: float = 10.0
    var isSpawning: logic = false
    resourceType: ResourceType
    Main: Tiles
    var UUID: string = ""
    var HitIndex: int = 0

    # Method to spawn the resource
    Spawn() <suspends>: void =
        set UUID = GenerateUUID()
        set Main.AliveProps += 1
        set isSpawning = true
        set Prop = SpawnTarget(vector3{X := tile.Position.X, Y := tile.Position.Y, Z := tile.Position.Z}, resourceType.Asset)
        Prop.MoveTo(vector3{X := tile.Position.X, Y := tile.Position.Y, Z := tile.Position.Z + 500.0}, IdentityRotation(), 0.5)
        set HP = resourceType.FullHP
        set HasScaled = false
        Sleep(0.5)
        set isSpawning = false

    # Method to handle taking damage
    TakeDamage(Player: agent, Damage: float ) <suspends>: void =
        if (FC := Player.GetFortCharacter[]):
            if (HP <= 0.0 or isSpawning = true):
                return
            set HP = HP - Damage
            HPPercentage := HP / resourceType.FullHP
            PlayAudio(Player)
            spawn. ShakeTreeAnim()
            DropItem(Player, Damage)
            if(CurrentUI:=Main.PlayerHealthUI[Player]):
                Print("Updating UI")
                spawn. CurrentUI.UpdateUI(Player, Self)

            if (HPPercentage < 0.5 and HasScaled = false):
                set HasScaled = true
                Prop.MoveTo(transform{
                    Translation := Prop.GetTransform().Translation,
                    Rotation := Prop.GetTransform().Rotation,
                    Scale := vector3{X := 0.5, Y := 0.5, Z := 0.5}
                }, 0.5)
            if (HP <= 0.0):
                DropExtraItems(Player)
                resourceType.BreakPlayer.Play()
                Prop.Dispose()
                set Main.AliveProps -= 1
                TempProp := SpawnTarget(vector3{X := tile.Position.X, Y := tile.Position.Y, Z := tile.Position.Z + 500.0}, resourceType.BreakNS, ?Rotation := FC.GetTransform().Rotation)
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
            Sleep(duration - 0.01)

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

    PlayAudio(Player:agent):void=
        if(HitIndex >= resourceType.HitPlayers.Length):
            set HitIndex = 0
        if(AudioPlayer:= resourceType.HitPlayers[HitIndex]):
            AudioPlayer.Play(Player)
        set HitIndex += 1

    DropItem(Player:agent, Damage:float):void=
        if(DropAmount:= Ceil[resourceType.TotalDropAmount*(Damage/resourceType.FullHP)]):
            case (resourceType.ItemDrop):
                "Wood" =>
                    if(PersistanceLayer:=Main.PlayerPersistanceLayer[Player]):
                        Wood:= PersistanceLayer.Wood.IncreaseValue(DropAmount)
                        ShowDropUI(Player, DropAmount, "Wood")
                "Stone" =>
                    if(PersistanceLayer:=Main.PlayerPersistanceLayer[Player]):
                        Stone:= PersistanceLayer.Stone.IncreaseValue(DropAmount)
                        ShowDropUI(Player, DropAmount, "Stone")
                _=>
                
    # Method to drop extra items when resource "dies"
    DropExtraItems(Player: agent): void =
        if(ExtraDropAmount :int= Ceil[resourceType.TotalDropAmount * 0.2]):
            case (resourceType.ItemDrop):
                "Wood" =>
                    if(PersistanceLayer:=Main.PlayerPersistanceLayer[Player]):
                        Wood := PersistanceLayer.Wood.IncreaseValue(ExtraDropAmount)
                        ShowDropUI(Player, ExtraDropAmount, "Wood")
                "Stone" =>
                    if(PersistanceLayer:=Main.PlayerPersistanceLayer[Player]):
                        Stone := PersistanceLayer.Stone.IncreaseValue(ExtraDropAmount)
                        ShowDropUI(Player, ExtraDropAmount, "Stone")
                _ =>

    ShowDropUI(Player:agent, Amount:int,Type:string ):void=
        if(UI:=Main.PlayerDropUI[Player]):
            spawn. UI.AddElement(Player, Amount, Type)
