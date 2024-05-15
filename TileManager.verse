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
    @editable TreeBigPropAsset: creative_prop_asset = DefaultCreativePropAsset
    @editable StonePropAsset: creative_prop_asset = DefaultCreativePropAsset

    @editable AudioPlayers: []audio_player_device = array{}

    @editable AudioPlayersTreeHit: []audio_player_device = array{}
    @editable AudioPlayerTreeBreak: audio_player_device = audio_player_device{}

    @editable TreeBreakNs: creative_prop_asset = DefaultCreativePropAsset
    @editable BigTreeBreakNs: creative_prop_asset = DefaultCreativePropAsset
    @editable StoneBreakNs: creative_prop_asset = DefaultCreativePropAsset
    
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
    var PlayerStillInGame: [agent]logic = map{}
    var PlayerHealthUI: [agent]Health_UI = map{}
    var PlayerPersistanceLayer:[agent]PlayerClass = map{}
    var PlayerDropUI: [agent]Drop_UI = map{}

    var AliveProps:int = 0
    var MaxProps:int = 10            
        
    var ForestResources: []ResourceType = array{}
    var firstTile:?Tile =false
    InitZoneResources():void=
        set ForestResources =array{
            ResourceType{Asset := TreePropAsset, FullHP := 100.0, Weight := 50, BreakNS := TreeBreakNs, HitPlayers:=AudioPlayersTreeHit, BreakPlayer:=AudioPlayerTreeBreak, ItemDrop:="Wood", TotalDropAmount:=20},
            ResourceType{Asset := TreeBigPropAsset, FullHP := 200.0, Weight := 30, BreakNS := BigTreeBreakNs, HitPlayers:=AudioPlayersTreeHit, BreakPlayer:=AudioPlayerTreeBreak,ItemDrop:="Wood", TotalDropAmount:=40},  # Example of another prop with more HP
            ResourceType{Asset := StonePropAsset, FullHP := 150.0, Weight := 20, BreakNS := StoneBreakNs, HitPlayers:=AudioPlayersTreeHit, BreakPlayer:=AudioPlayerTreeBreak, ItemDrop:="Stone", TotalDropAmount:=10}  # Example of a stone prop
            }

    ChooseWeightedResource(Type:string): ResourceType =
        var resources: []ResourceType = array{}
        case(Type):
            "Forest" => set resources = ForestResources
            _=> set resources = ForestResources

        var totalWeight: int = 0
        Print("resources: {resources.Length}")
        for (resource : resources):
            set totalWeight += resource.Weight

        var randomWeight: int = GetRandomInt(0, totalWeight - 1)
        for (I->resource : resources):
            set randomWeight -= resource.Weight
            if (randomWeight < 0):
                Print("returning resource {I}")
                return resource

        return ResourceType{Asset := TreePropAsset, FullHP := 100.0, Weight := 50, BreakNS := BigTreeBreakNs, HitPlayers:=AudioPlayersTreeHit, BreakPlayer:=AudioPlayerTreeBreak, ItemDrop:="Wood", TotalDropAmount:=20}

    OnBegin<override>() <suspends>: void =
        InitZoneResources()
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
        set firstTile = option{newTile}
        
        
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
           spawn. PlayerLoop(Player)

        Sleep(1.0)
        GetPlayspace().PlayerAddedEvent().Subscribe(PlayerJoin)
        

    PlayerLoop(Player:player)<suspends>:void=
        if(set PlayerStillInGame[Player] = true){}
        if(set CurrentPlayerTile[Player] = TileArr[0]){}
        NewClass:=PlayerClass{Player:=Player}
        NewClass.Init()
        if(set PlayerPersistanceLayer[Player]=NewClass){}
        NewUI:=Health_UI{Main:=Self}
        if(set PlayerHealthUI[Player]= NewUI){}
        DropUI:=Drop_UI{}
        DropUI.ShowUIToPlayer(Player)
        if(set PlayerDropUI[Player]=DropUI){}
        spawn. DelayedActivate(Player)
        loop:
            if( PlayerStillInGame[Player] = false):
                break
            if (ACurrentTile := CurrentPlayerTile[Player]):
                Sleep(0.2)
                LocalTile := GetCurrentTile(Player, ACurrentTile)
                PResource:= FindClosestResource(Player)
                
                if(not PResource(1)? or PResource(0) > 500.0):
                    if(CurretnPLayerHealthUI:= PlayerHealthUI[Player]):
                        if(CurretnPLayerHealthUI.IsActive = true):
                            CurretnPLayerHealthUI.RemoveUIFromPlayer(Player)
                


    PlayerLeave(Player:agent):void=
        if(set PlayerStillInGame[Player] = false){}
        set CurrentPlayerTile = CurrentPlayerTile.Remove(Player)
        set PlayerPressingLeft = PlayerPressingLeft.Remove(Player)

    PlayerJoin(Player:player):void=
        spawn. DelayedActivate(Player)
        spawn. PlayerLoop(Player)

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
            if( PlayerStillInGame[Player] = false):
                break
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

    PressLeft(Player: agent)<suspends>: void =
        if (set PlayerPressingLeft[Player] = true){}
        Sleep(0.2)
        var hitBufferDistance: float = 300.0
        var lastHitResource: ?Resource = false
        loop:
            if (PlayerPressingLeft[Player] = false):
                break
            Res := DamageClosestNeighbourProp(Player, hitBufferDistance, lastHitResource)
            set hitBufferDistance = Res(0)
            set lastHitResource = Res(1)
            Sleep(0.7)

    ReleaseLeft(Player: agent, Time: float): void =
        if (set PlayerPressingLeft[Player] = false){}


    FindClosestResource(Player: agent): tuple(float,?Resource) =
        LookingPoint := CalculatePoint(Player, 10.0, "Forward")
        LookingPoint2 := CalculatePoint(Player, 500.0, "Forward")
        if (ACurrentTile := CurrentPlayerTile[Player]):
            var ClosestResource: ?Resource = false
            var ClosestDistance: float = 100000.0
            for (neighbor : ACurrentTile.Neighbors + array{ACurrentTile}):
                if (resource := neighbor.pResource?):
                    if (resource.Prop.IsValid[]):
                        MDistance := ManhattenDistance(resource.Prop.GetTransform().Translation, LookingPoint)
                        MDistance2 := ManhattenDistance(resource.Prop.GetTransform().Translation, LookingPoint2)
                        if (MDistance < MDistance2):
                            if (MDistance < ClosestDistance):
                                set ClosestDistance = MDistance
                                set ClosestResource = option{resource}
                        else:
                            if (MDistance2 < ClosestDistance):
                                set ClosestDistance = MDistance2
                                set ClosestResource = option{resource}
            return (ClosestDistance, ClosestResource)
        return (99999999.0,false)

    DamageClosestNeighbourProp(Player: agent, initialHitBuffer: float, lastHitResource: ?Resource): tuple(float, ?Resource) =
        Res:=FindClosestResource(Player)
        ClosestDistance:=Res(0)
        ClosestResource:=Res(1)
        return (DamageClosest(Player, initialHitBuffer, lastHitResource, ClosestDistance, ClosestResource), ClosestResource)
                        
            
    DamageClosest(Player: agent, initialHitBuffer: float, lastHitResource: ?Resource,ClosestDistance:float,ClosestResource:?Resource):float=
        var hitBufferDistance: float = initialHitBuffer

            Print("Closest Distance: {ClosestDistance}")
            if (ClosestDistance < hitBufferDistance, AClosestResource := ClosestResource?):
                Print("damaging")
                spawn. AClosestResource.TakeDamage(Player, 20.0)
                
                # Check if the current closest resource is the same as the last hit resource
                if (AClosestResource.UUID = lastHitResource?.UUID):
                    set hitBufferDistance = 500.0  # Increase the buffer for smoother transition
                else:
                    set hitBufferDistance = initialHitBuffer  # Reset to initial buffer if different resource

                # Update last hit resource
                return (hitBufferDistance)
            else:
                set hitBufferDistance = initialHitBuffer  # Reset to initial buffer if no resource is found

        
        return (hitBufferDistance)

    GetActiveTileCount()<transacts>:int=
        var count:int = 0
        for (tile : TileArr):
            if(tile.isActive = true):
                set count += 1
        return count

    ResourceSpawnLoop()<suspends>: void =
        loop:
            Sleep(2.0)
            loop:
                Sleep(0.1)
                if (AliveProps >= MaxProps or AliveProps >= GetActiveTileCount()):
                    break

                var candidateTiles: []Tile = array{}
                # Gather tiles that either don't have resources or their resources are depleted
                for (tile : TileArr):
                    if (tile.isActive = true and (not tile.pResource? or tile.pResource?.HP <= 0.0)):
                        set candidateTiles += array{tile}

                if (candidateTiles.Length > 0):
                    Print("Selecting Tile")
                    # Select a tile in a round-robin fashion
                    if(var tileIndex: int = Mod[AliveProps, candidateTiles.Length]):
                        if(var selectedTile: Tile = candidateTiles[tileIndex]):
                            Print("Selected Tile")
                            # Create or respawn resource in the selected tile
                            selectedTile.CreateOrRespawnResource()

                Sleep(0.1)

                            
                        
                

                
            
            


    

    
            
        