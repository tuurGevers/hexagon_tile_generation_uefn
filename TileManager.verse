using { /Fortnite.com/Devices }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { /Fortnite.com/Devices/CreativeAnimation }
using {mapProps}

Tiles := class(creative_device):
    @editable InActiveTile: creative_prop_asset = DefaultCreativePropAsset
    @editable ActiveTile: creative_prop_asset = DefaultCreativePropAsset
    @editable DebugCube:creative_prop = creative_prop{}
    @editable DebugCubeAsset:creative_prop_asset = DefaultCreativePropAsset
    @editable TransitionAnim: cinematic_sequence_device = cinematic_sequence_device{}
    @editable TestInActive: creative_prop_asset = DefaultCreativePropAsset
    @editable TestActive: creative_prop_asset = DefaultCreativePropAsset

    @editable InteractInput: input_trigger_device = input_trigger_device{}
    @editable RecordPlayerAsset: creative_prop_asset = DefaultCreativePropAsset

    @editable AudioPlayers: []audio_player_device = array{}
    
    basePosition:vector3= vector3{X:=0.0, Y:=0.0, Z:=0.0}
    var PremadeTiles:[]tuple(int,int,string, creative_prop_asset) = array{}
    Zones:[]tuple(tuple(int, int), tuple(int,int), string) = {
        ((-20, -10), (-11, 10), "Desert"),
        ((-10,-10), (10, 10), "Forest")
    }

    var TileArr: []Tile = array{}
    var CurrentTile: ?Tile = false


   
    OnBegin<override>() <suspends>: void =
        InteractInput.PressedEvent.Subscribe(ExecuteSpecialTileFunction)
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
        set CurrentTile = option{newTile}
        
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
        
        if (Player := GetPlayspace().GetPlayers()[0]):
            spawn. DelayedActivate()
            loop:
                if (ACurrentTile := CurrentTile?):
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

             
            set CurrentTile = option{closestTile}
        return closestTile

    DelayedActivate()<suspends> : void=
        loop:
            if(tile:=CurrentTile?):
                if(tile.isActive= false):
                    tile.Activate()
                
            Sleep(0.4)

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
                    Print("Zone Found: {zone(2)} at {gridPosition(0)}, {gridPosition(1)}")
                    return zone(2)
        return "Default"


    ExecuteSpecialTileFunction(Player:agent):void=
        if(ACurrentTile:=CurrentTile?):
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
        Print("todo")


    

    
            
        