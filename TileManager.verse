using { /Fortnite.com/Devices }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { /Fortnite.com/Devices/CreativeAnimation }
using { /Verse.org/Random }
using {mapProps}

Tiles := class(creative_device):
    @editable InActiveTile: creative_prop_asset = DefaultCreativePropAsset
    @editable ActiveTile: creative_prop_asset = DefaultCreativePropAsset
    @editable DebugCube:creative_prop = creative_prop{}
    @editable DebugCubeAsset:creative_prop_asset = DefaultCreativePropAsset
    @editable TestInActive: creative_prop_asset = DefaultCreativePropAsset
    @editable TestActive: creative_prop_asset = DefaultCreativePropAsset

    @editable InteractInput: input_trigger_device = input_trigger_device{}
    @editable LeftClickInput: input_trigger_device = input_trigger_device{}
    @editable RecordPlayerAsset: creative_prop_asset = DefaultCreativePropAsset

    @editable TreePropAsset: creative_prop_asset = DefaultCreativePropAsset
    @editable AudioPlayers: []audio_player_device = array{}

    @editable AudioPlayerTreeHit: audio_player_device = audio_player_device{}
    @editable AudioPlayerTreeBreak: audio_player_device = audio_player_device{}
    @editable TreeBreakNs: creative_prop_asset = DefaultCreativePropAsset
    
    basePosition:vector3= vector3{X:=0.0, Y:=0.0, Z:=0.0}

    var PremadeTiles:[]tuple(int,int,string, creative_prop_asset) = array{}
    Zones:[]tuple(tuple(int, int), tuple(int,int), string) = {
        ((-20, -10), (-11, 10), "Desert"),
        ((-10,-10), (10, 10), "Forest")
    }

    var TileArr: []Tile = array{}
    # var CurrentTile: ?Tile = false
    var CurrentPlayerTile: [agent]Tile = map{}
    var PlayerPressingLeft: [agent]logic = map{}
    var AliveProps:int = 0
    var MaxProps:int = 10            
        
    OnBegin<override>() <suspends>: void =
        InteractInput.PressedEvent.Subscribe(ExecuteSpecialTileFunction)
        LeftClickInput.PressedEvent.Subscribe(PressLeftInit)
        LeftClickInput.ReleasedEvent.Subscribe(ReleaseLeft)
        set PremadeTiles = array{
            (4,4,"Test",RecordPlayerAsset)
        }
        var newTile: Tile = Tile{
            InactiveTileAsset := InActiveTile,
            TilePropAsset := ActiveTile,
            Position := vector3{X := 0.0, Y := 0.0, Z := 0.0},
            Parent := Self
        }
        newTile.Init(TileArr, ?isActiveState := true)  # Initialize as active
        set TileArr += array{newTile}
        for(Player:GetPlayspace().GetPlayers()):
            if(set CurrentPlayerTile[Player] = newTile){}
        
        for (neighborPos : newTile.neighborPositions):
            var neighborTile: Tile = newTile.FindExistingOrInitialize(neighborPos)(0)
            if (neighborTile.isActive = false):
                neighborTile.Activate()

        for (move : PremadeTiles):
            Props := GetPropsByType(move(2))
            PremadeTile := Tile{
                InactiveTileAsset := Props(1),
                TilePropAsset := Props(0),
                Position := vector3{X := 0.0, Y := 0.0, Z := 0.0},
                Parent := Self
            }
            PremadeTile.InitSpecial(vector3{X := 0.0, Y := 0.0, Z := 0.0}, move)
            set TileArr += array{PremadeTile}
        
        spawn. ResourceSpawnLoop()
        for (Player : GetPlayspace().GetPlayers()):
            spawn. DelayedActivate(Player)
            loop:
                if (ACurrentTile := CurrentPlayerTile[Player]):
                    Sleep(0.2)
                    LocalTile := GetCurrentTile(Player, ACurrentTile)


    GetPropsByType(Type:string)<transacts>: tuple(creative_prop_asset,creative_prop_asset)=
        case(Type):
            "Desert" =>return (TestActive, TestInActive)
            "Test" =>return (TestActive, TestInActive)
            "Forest" => return (ActiveTile, InActiveTile)
            _=>return (ActiveTile, InActiveTile)
    
    GetCurrentTile(Player:agent, ACurrentTile:Tile)<transacts> : Tile=
        var closestTile: Tile = ACurrentTile
        if(FC:= Player.GetFortCharacter[]):
            currentPosition:= FC.GetTransform().Translation
            var closestDistance: float = ManhattenDistance(closestTile.Position, currentPosition)
            # Check all neighbors to see if any are closer
            for (neighbor : ACurrentTile.Neighbors):
                var neighborDistance: float = ManhattenDistance(neighbor.Position, currentPosition)
                if (neighborDistance < closestDistance):
                    set closestDistance = neighborDistance
                    set closestTile = neighbor  # Recursively find the closest tile

             
            if(set CurrentPlayerTile[Player] = closestTile){}
        return closestTile

    DelayedActivate(Player:agent)<suspends> : void=
        loop:
            if(tile:=CurrentPlayerTile[Player]):
                if(tile.isActive= false):
                    tile.Activate()
                
            Sleep(0.740)

    CalculateGridFromPosition(currentPosition: vector3): tuple(int, int) =
        xDiff := currentPosition.X - basePosition.X
        yDiff := currentPosition.Y - basePosition.Y

        var XMove:int = -1
        var YMove:int = -1

        if(set XMove = Round[xDiff / 1000.0],
        set YMove = Round[yDiff / 850.0]){}

        return (XMove, YMove)

    DetermineZoneType(position: vector3): string =
        gridPosition := CalculateGridFromPosition(position)
        for (zone : Zones):
            if (gridPosition(0) >= zone(0)(0) and gridPosition(0) <= zone(1)(0) and
                gridPosition(1) >= zone(0)(1) and gridPosition(1) <= zone(1)(1)):
                    return zone(2)
        return "Default"


    ExecuteSpecialTileFunction(Player:agent):void=
        if(ACurrentTile:=CurrentPlayerTile[Player]):
            if(ACurrentTile.isActive = false):
                return
            case(ACurrentTile.Type):
                "Test" => spawn. TestFunction(Player, ACurrentTile)
                _=>{}

    var AudioIndex:int = -1
    TestFunction(Player:agent, tile:Tile)<suspends>:void=
        if(AudioIndex>=0, AudioPlayer:=AudioPlayers[AudioIndex]):
            AudioPlayer.Stop()
        set AudioIndex += 1
        if(AudioPlayer:=AudioPlayers[AudioIndex]):
            AudioPlayer.Play()
        else:
            set AudioIndex = -1

    PressLeftInit(Player:agent):void=
        spawn. PressLeft(Player)

    PressLeft(Player:agent)<suspends>:void=
        if(set PlayerPressingLeft[Player] = true){}
        Sleep(0.2)
        loop:
            if(PlayerPressingLeft[Player] = false):
                break
            DamageClosestNeighbourProp(Player)
            Sleep(0.4)

    ReleaseLeft(Player:agent, Time:float):void=
        if(set PlayerPressingLeft[Player] = false){}

    DamageClosestNeighbourProp(Player:agent):void=
        if(ACurrentTile:=CurrentPlayerTile[Player]):
            Print("looking for damage")
            LookingPoint := CalculatePoint(Player, 100.0, "Forward")
            LookingPoint2 := CalculatePoint(Player, 500.0, "Forward")
            var ClosestResource: ?Resource = ACurrentTile.pResource
            var ClosestDistance: float = 100000.0
            for (neighbor : ACurrentTile.Neighbors+array{ACurrentTile}):
                if(resource:= neighbor.pResource?):
                    if(resource.Prop.IsValid[]):
                        MDistance:=ManhattenDistance(resource.Prop.GetTransform().Translation, LookingPoint)
                        MDistance2 := ManhattenDistance(resource.Prop.GetTransform().Translation, LookingPoint2)
                        if(MDistance<MDistance2):
                            if(MDistance<ClosestDistance):
                                set ClosestDistance = MDistance
                                set ClosestResource = option{resource}
                        else:
                            if(MDistance2<ClosestDistance):
                                set ClosestDistance = MDistance2
                                set ClosestResource = option{resource}

            Print("Closest Distance: {ClosestDistance}")
            if(ClosestDistance<300.0, AClosestResource:= ClosestResource?):
                Print("damaging")
                spawn. AClosestResource.TakeDamage(20.0,Player)

    GetActiveTileCount()<transacts>:int=
        var count:int = 0
        for (tile : TileArr):
            if(tile.isActive = true):
                set count += 1
        return count

    ResourceSpawnLoop()<suspends>:void=
        loop:
            Sleep(2.0)
            var Tries:int = 0
            loop:
                Sleep(0.1)
                if(AliveProps>=MaxProps or AliveProps>=GetActiveTileCount() or Tries>=10):
                    break
                if(RandomTile:= TileArr[GetRandomInt(0, TileArr.Length-1)]):
                    if(RandomTile.isActive = true):
                        Print("active tile")
                        if((not RandomTile.pResource?) or  RandomTile.pResource?.HP < 0.0 ):
                            RandomTile.CreateOrRespawnResource()
                set Tries+=1
                            
                        
                

                
            
            


    

    
            
        