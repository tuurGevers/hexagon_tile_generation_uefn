using { /Fortnite.com/Devices }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { /Fortnite.com/Devices/CreativeAnimation }
using { /Verse.org/Assets }
using {mapProps}
using{numbers}

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
    var AdditionalPropAsset:?creative_prop_asset = false
    var AdditionalProp:?creative_prop = false
    var pResource:?Resource = false
    var UUID:string = ""
    var ResourcesRequired: []ResourceRequired = array{}
    Player:player
    Parent:Tiles

    CreateOrRespawnResource(): void =
        if (Self.isActive = true):
            resourceType: ResourceType = Parent.ChooseWeightedResource(Type)
            resource:= Resource{
                tile := Self,
                Main:=Parent,
                resourceType:=resourceType
                }
            Print("spawning resource")
            spawn. resource.Spawn()
            set Self.pResource = option{resource}
            

    InitSpecial(basePosition: vector3, moves: tuple(int, int,string, creative_prop_asset)): void =
        xMove := moves(0)
        yMove := moves(1)
        newPosition := Self.CalculatePositionFromBase(basePosition, xMove, yMove)
        set Self.Position = newPosition
        set Self.AdditionalPropAsset = option{moves(3)}
        Self.Init(Parent.TileArr, ?isActiveState:=false, ?InitType:=moves(2))

    CalculatePositionFromBase(basePosition: vector3, xMove: int, yMove: int): vector3 =
        var finalPosition:vector3 = basePosition
        var xOffset:vector3 = vector3{X:=1000.0, Y:=0.0, Z:=0.0}  # Adjust this value based on actual grid size and orientation
        var yOffset:vector3 = vector3{X:=500.0, Y:=850.0, Z:=0.0}  # This is typical for hex grids
        set finalPosition= finalPosition.Add(xOffset.Times(xMove).Add(yOffset.Times(yMove)))
        return finalPosition

    


    Init(TileArray: []Tile,  ?isActiveState: logic = false, ?InitType:string="Auto", ?HasResources:logic=true): void =
        set ResourcesRequired = array{ResourceRequired{Type:= "Wood", TargetAmount:= 50, tile:=Self, Main:=Parent}}
        
        set UUID = GenerateUUID()
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
            if(ActualAdditionalProp:=AdditionalPropAsset?):
                LocalPorp:= SpawnTarget(vector3{X:=Position.X, Y:=Position.Y, Z:=Position.Z+500.0}, ActualAdditionalProp)
                set AdditionalProp = option{LocalPorp}

        Self.UpdateNeighbors()

        if (isActiveState=true):
            spawn. Self.Activate()


    PutResourcesOnTile(): void =
        if(Persistance:=Parent.PlayerPersistanceLayer[Player]):
            var NotCompleted:int=0
            var DecreaseAmount:int=10
            for (resource: ResourcesRequired):
                if(resource.IsActive = false):
                    resource.Init()

                case(resource.Type):
                    "Wood"=>{
                        V:=Persistance.Wood.GetValue()
                        if(V>0):
                            if(V<10):
                                set DecreaseAmount=V      
                            if(Persistance.Wood.DecreasePositiveValue(DecreaseAmount)=true):
                                Print("Wood added new value {Persistance.Wood.GetValue()}")
                                resource.AddResource(DecreaseAmount)

                            else:
                                Print("Not enough wood")
                        
                    }
                    _=>

                if(resource.IsCompleted = false):
                    set NotCompleted+=1
            spawn. MoveUp()
            if(NotCompleted=0):
                spawn. Self.Activate()
            


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

    Activate()<suspends>: void =
        Print("Activating Tile")
        if(isActive = true):
            return
        set isActive = true
        set Neighbors = array{}
        Position.Print(?Msg:= "Activating Tile at position: ")
        set Prop = SpawnTarget(vector3{X:=Position.X, Y:=Position.Y, Z:=-500.0}, TilePropAsset)  # Spawn active tile
        Sleep(0.0)
        Prop.MoveTo(Position, IdentityRotation(), 1.0)
        if(InActiveProp.IsValid[]):
            InActiveProp.Dispose()
        # spawn. AnimateProp()
        for (position : neighborPositions):
            UPDated:= FindExistingOrInitialize(position)
            neighbor:= UPDated(0)
            if(UPDated(1) = true):
                set Parent.TileArr += array{neighbor}
            set Neighbors += array{neighbor}
        if(PersistanceLayer:= Parent.PlayerPersistanceLayer[Player], TileManager:=PersistanceLayer.persistableTile?):
            TileManager.AddPersistantTile(Self)

   
  

    FindExistingOrInitialize( position: vector3, ?TileType:string="Auto", ?IsInitial:logic=false): tuple(Tile,logic) =
        for (tile : Parent.TileArr):
            if (tile.Position.ApproxEquals(position, 10.0) = true):
                return (tile,false)
        if(TileType="Auto"):
            AutoType:= Parent.DetermineZoneType(position)
            Props:= Parent.GetPropsByType(AutoType)
            var newTile:Tile = Tile{ InactiveTileAsset := Props(1),TilePropAsset:=Props(0), Position:=position, Parent:=Parent, Player:=Player}
            newTile.Init(Parent.TileArr, ?HasResources:=IsInitial)  # Initialize as inactive
            return (newTile, true)
        else:
            Props:= Parent.GetPropsByType(TileType)
            var newTile:Tile = Tile{ InactiveTileAsset := Props(1),TilePropAsset:=Props(0), Position:=position, Parent:=Parent, Player:=Player}
            newTile.Init(Parent.TileArr, ?HasResources:=IsInitial)  # Initialize as inactive
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


    MoveUp()<suspends>:void=
        var CurrentAmount:int =0
        var TargetAmount:int =0
        for(requiredResource: ResourcesRequired):
            set CurrentAmount+=requiredResource.CurrentAmount
            set TargetAmount+=requiredResource.TargetAmount

        CompeltionPercentage:float=(CurrentAmount*1.0)/(TargetAmount*1.0)
        Print("current amount {CurrentAmount} target amount {TargetAmount} completion percentage {CompeltionPercentage}")
        ZIncrease:=(500.0*CompeltionPercentage)-500.0
        if(not Prop.IsValid[]):
            set Prop = SpawnTarget(vector3{X:=Position.X, Y:=Position.Y, Z:=-500.0}, TilePropAsset)  # Spawn active tile
            Sleep(0.0)
        spawn. Prop.MoveTo(vector3{X:=Position.X, Y:=Position.Y, Z:=ZIncrease}, IdentityRotation(), 1.0)

    (V:vector3).ApproxEquals(other: vector3, threshold: float) <transacts>: logic =
        if(ManhattenDistance(V , other) < threshold):
            return true
        return false

    (V:vector3).Magnitude() <transacts>: float =
        return Sqrt((V.X * V.X) + (V.Y * V.Y) + (V.Z * V.Z))

ResourceRequired:=class:
    Type: string
    var CurrentAmount: int = 0
    TargetAmount: int
    var IsCompleted: logic = false
    var Display: ?ResourceDisplay = false 
    tile:Tile
    Main:Tiles
    var IsActive:logic=false

    Init():void=
        set IsActive = true
        NewDisplay:=ResourceDisplay{Main:=Main, tile:=tile, resource:=Self}
        set Display = option{NewDisplay}
        NewDisplay.Init()

    AddResource(Amount: int): void =
        set CurrentAmount = CurrentAmount + Amount
        if (CurrentAmount >= TargetAmount):
            set IsCompleted = true
            set CurrentAmount = TargetAmount
        if(CurrentDisplay:= Display?):
            CurrentDisplay.Update()

    
ResourceDisplay:=class:
    Main:Tiles
    tile:Tile
    resource:ResourceRequired
    var CurrentProp: creative_prop = creative_prop{}
    Init(): void =
        set CurrentProp = SpawnTarget(vector3{X:=tile.Position.X, Y:=tile.Position.Y-350.0, Z:=tile.Position.Z+400.0}, Main.CounterProp, ?Scale:=vector3{X:=0.5, Y:=0.5, Z:=0.5})

    Update(): void =
        if(CurrentProp.TeleportTo[
            transform{
                Translation:=vector3{X:=tile.Position.X, Y:=tile.Position.Y-200.0, Z:=tile.Position.Z+800.0},
                Rotation:=IdentityRotation(),
                Scale:=vector3{X:=0.5, Y:=0.1+resource.TargetAmount*1.0, Z:=0.1+resource.CurrentAmount*1.0}}
        ]){}
        
        if (resource.IsCompleted = true):
            CurrentProp.Dispose()
    

    