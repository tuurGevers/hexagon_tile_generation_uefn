using { /Fortnite.com/Devices }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { /Fortnite.com/Devices/CreativeAnimation }
using {mapProps}
Tile := class:
    var TilePropAsset: creative_prop_asset
    var isActive: logic = false
    var Neighbors: []Tile = array{}
    var neighborPositions: []vector3 = array{}
    var InactiveTileAsset: creative_prop_asset
    var Prop: creative_prop = creative_prop{}
    var InActiveProp : creative_prop = creative_prop{}
    var Position:vector3 
    var Listenable: ?cancelable = false
    var Type:string = "Default"

    Parent:Tiles
    InitSpecial(basePosition: vector3, moves: tuple(int, int,string)): void =
        xMove := moves(0)
        yMove := moves(1)
        newPosition := Self.CalculatePositionFromBase(basePosition, xMove, yMove)
        set Self.Position = newPosition
        Self.Init(Parent.TileArr, ?isActiveState:=false, ?InitType:=moves(2))

    CalculatePositionFromBase(basePosition: vector3, xMove: int, yMove: int): vector3 =
        var finalPosition:vector3 = basePosition
        var xOffset:vector3 = vector3{X:=1000.0, Y:=0.0, Z:=0.0}  # Adjust this value based on actual grid size and orientation
        var yOffset:vector3 = vector3{X:=500.0, Y:=850.0, Z:=0.0}  # This is typical for hex grids
        set finalPosition= finalPosition.Add(xOffset.Times(xMove).Add(yOffset.Times(yMove)))
        return finalPosition

    


    Init(TileArray: []Tile, ?isActiveState: logic = false, ?InitType:string="Auto"): void =
        Self.CalculateNeighborPositions()
        set isActive = isActiveState

        if(InitType = "Auto"):
            set Type = Parent.DetermineZoneType(Self.Position)
        else:
            set Type = InitType

        # Get props after type is determined
        Assets := Parent.GetPropsByType(Type)
        set TilePropAsset = Assets(0)
        set InactiveTileAsset = Assets(1)

        Print("Initializing Tile: Type = {Type}")

        if (isActiveState = true):
            set Prop = SpawnTarget(Position, TilePropAsset)  # Spawn active tile
            set Position = Prop.GetTransform().Translation  # Get the exact position after spawning
        else:
            set InActiveProp = SpawnTarget(Position, InactiveTileAsset)
            set Position = InActiveProp.GetTransform().Translation

        Self.UpdateNeighbors()

        if (isActiveState=true):
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
   
  

    FindExistingOrInitialize( position: vector3, ?TileType:string="Auto"): tuple(Tile,logic) =
        for (tile : Parent.TileArr):
            if (tile.Position.ApproxEquals(position, 10.0) = true):
                return (tile,false)
        if(TileType="Auto"):
            AutoType:= Parent.DetermineZoneType(position)
            Props:= Parent.GetPropsByType(AutoType)
            var newTile:Tile = Tile{ InactiveTileAsset := Props(1),TilePropAsset:=Props(0), Position:=position, Parent:=Parent}
            newTile.Init(Parent.TileArr)  # Initialize as inactive
            return (newTile, true)
        else:
            Props:= Parent.GetPropsByType(TileType)
            var newTile:Tile = Tile{ InactiveTileAsset := Props(1),TilePropAsset:=Props(0), Position:=position, Parent:=Parent}
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