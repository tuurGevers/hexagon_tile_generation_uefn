using { /Fortnite.com/Devices }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { /Fortnite.com/Devices/CreativeAnimation }
using {mapProps}
Tile := class:
    TilePropAsset: creative_prop_asset
    var isActive: logic = false
    var Neighbors: []Tile = array{}
    var neighborPositions: []vector3 = array{}
    var InactiveTileAsset: creative_prop_asset
    var Prop: creative_prop = creative_prop{}
    var InActiveProp : creative_prop = creative_prop{}
    var Position:vector3 
    var Listenable: ?cancelable = false
    Parent:Tiles
    Init(TileArray: []Tile, ?isActiveState: logic = false): void =
        Self.CalculateNeighborPositions()
        set isActive = isActiveState
        if (isActiveState = true):
            set Prop = SpawnTarget(Position, TilePropAsset)  # Spawn active tile immediately if active
            set Position = Prop.GetTransform().Translation  # Get the exact position after spawning

        else:
            set InActiveProp = SpawnTarget(Position, InactiveTileAsset, ?Scale:=vector3{X:=0.9, Y:=0.9, Z:=0.9})  # Spawn inactive tile if not active
            set Position = InActiveProp.GetTransform().Translation  # Get the exact position after spawning
            for (position : neighborPositions):
                ExistingNeighbours:= FindExisting(position)
                if(neighbor:=ExistingNeighbours?):
                    set Neighbors += array{neighbor}
        Self.UpdateNeighbors()

        if (isActiveState = true):
            Self.Activate()

    CalculateNeighborPositions(): void =
        var offsets: []vector3 = {
            vector3{X:=-1000.0, Y:=0.0, Z:=0.0},
            vector3{X:=-500.0, Y:=850.0, Z:=0.0},
            vector3{X:=500.0, Y:=850.0, Z:=0.0},
            vector3{X:=1000.0, Y:=0.0, Z:=0.0},
            vector3{X:=500.0, Y:=-850.0, Z:=0.0},
            vector3{X:=-500.0, Y:=-850.0, Z:=0.0}
        }
        for (offset : offsets):
            var potentialPosition:vector3 = Position + offset
            set neighborPositions += array{potentialPosition}

    Activate(): void =
        set isActive = true
        set Neighbors = array{}
     
        if(InActiveProp.IsValid[]):
            InActiveProp.Dispose()
        set Prop = SpawnTarget(Position, TilePropAsset)  # Spawn active tile
        # spawn. AnimateProp()
        for (position : neighborPositions):
            UPDated:= FindExistingOrInitialize(position)
            neighbor:= UPDated(0)
            if(UPDated(1) = true):
                set Parent.TileArr += array{neighbor}
            set Neighbors += array{neighbor}

        Print("Total Neighbors added: {Neighbors.Length}")

    AnimateProp()<suspends>: void =
        spawn. Prop.MoveTo(vector3{X:=Position.X, Y:=Position.Y, Z:=Position.Z+500.0}, IdentityRotation().ApplyYaw(DegreesToRadians(270.0)), 1.0)
        Sleep(0.99)
        spawn. Prop.MoveTo(vector3{X:=Position.X, Y:=Position.Y, Z:=Position.Z-100.0}, IdentityRotation().ApplyYaw(DegreesToRadians(-360.0)), 1.0)
        Sleep(0.99)
        Prop.MoveTo(vector3{X:=Position.X, Y:=Position.Y, Z:=Position.Z}, IdentityRotation(), 1.0)
   
  

    FindExistingOrInitialize( position: vector3): tuple(Tile,logic) =
        for (tile : Parent.TileArr):
            if (tile.Position.ApproxEquals(position, 10.0) = true):
                return (tile,false)
        var newTile:Tile = Tile{ InactiveTileAsset := InactiveTileAsset,TilePropAsset:=TilePropAsset, Position:=position, Parent:=Parent}
        newTile.Init(Parent.TileArr)  # Initialize as inactive
        return (newTile, true)

    UpdateNeighbors(): void =
        for (position : neighborPositions):
            pexistingTile := FindExisting(position)
            if (ExistingTIle:= pexistingTile?):
                set Neighbors += array{ExistingTIle}
                ExistingTIle.UpdateNeighbor(Self)  # Notify the found neighbor to update its list
    
    FindExisting(position: vector3)<transacts>: ?Tile =
        for (tile : Parent.TileArr):
            if (tile.Position.ApproxEquals(position, 10.0)=true):
                return option{tile}
        return false
    
    UpdateNeighbor(newNeighbor: Tile): void =
        if (not FindExisting(newNeighbor.Position)? ):
            set Neighbors += array{newNeighbor} 

    (V:vector3).ApproxEquals(other: vector3, threshold: float) <transacts>: logic =
        if(ManhattenDistance(V , other) < threshold):
            return true
        return false

    (V:vector3).Magnitude() <transacts>: float =
        return Sqrt((V.X * V.X) + (V.Y * V.Y) + (V.Z * V.Z))

Tiles := class(creative_device):
    @editable InActiveTile: creative_prop_asset = DefaultCreativePropAsset
    @editable ActiveTile: creative_prop_asset = DefaultCreativePropAsset
    @editable DebugCube:creative_prop = creative_prop{}
    @editable DebugCubeAsset:creative_prop_asset = DefaultCreativePropAsset
    @editable TransitionAnim: cinematic_sequence_device = cinematic_sequence_device{}

    var TileArr: []Tile = array{}
    var CurrentTile: ?Tile = false
    OnBegin<override>() <suspends>: void =
        var newTile:Tile = Tile{InactiveTileAsset := InActiveTile, TilePropAsset:=ActiveTile, Position:=vector3{X:=0.0, Y:=0.0, Z:=0.0}, Parent:=Self}
        newTile.Init(TileArr, ?isActiveState:=true)  # Initialize as active
        set TileArr += array{newTile}
        set CurrentTile = option{newTile}
        for (neighborPos : newTile.neighborPositions):
            var neighborTile:Tile = newTile.FindExistingOrInitialize( neighborPos)(0)           
            if ( neighborTile.isActive = false):
                neighborTile.Activate()

        for(LocalTIle:TileArr):
        
            # for(I:=0..LocalTIle.Neighbors.Length-1):
            #     SpawnTarget(vector3{X:=LocalTIle.Position.X,Y:=LocalTIle.Position.Y,Z:=LocalTIle.Position.Z+800.0+I*100.0}, DebugCubeAsset)

        if(Player:=GetPlayspace().GetPlayers()[0]):
            spawn. DelayedActivate()
            loop:
                if(ACurrentTile:=CurrentTile?):
                    Sleep(1.0)
                    LocalTile:=GetCurrentTile(Player, ACurrentTile)
                    DebugCube.MoveTo(vector3{X:=LocalTile.Position.X, Y:=LocalTile.Position.Y, Z:= LocalTile.Position.Z+800.0}, IdentityRotation(), 0.1)


    
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
                
            Sleep(1.0)

    
            
        