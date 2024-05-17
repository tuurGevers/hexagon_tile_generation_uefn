using { /Fortnite.com/Devices }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { /Fortnite.com/Devices/CreativeAnimation }
using { /Verse.org/Random }
using { /Verse.org/Assets }
PlayerClass:=class:
    Player:player
    var Wood:PersistableWood = PersistableWood{}
    var Stone:PersistableStone= PersistableStone{}
    var persistableTile:?PersistableTile= false
    
    Init(Main:Tiles)<suspends>:void=
        Print("Init player: ")
        if(not PlayerData[Player]):
            Print("Playerdata not found: ")
            if(set PlayerData[Player] = PlayerPersistance{}){}

        set Wood.PPlayer = option{Player}
        set Stone.PPlayer = option{Player}
        set persistableTile = option{PersistableTile{Main:=Main, PPlayer:=option{Player}}}
        Sleep(0.5)
        if(PlayerData[Player].ActiveTiles.Length>0):
            Print("Tiles found for player: " )
            if(ApersistableTile:=persistableTile?):
                Main.InitTiles(Player)
                Print("adding tiles")
                ApersistableTile.InitTileArray()
        else:
            Print("No tiles found for player: ")
            Main.InitTiles(Player)

                


PersistableItem:=class:
    var PPlayer:?player=false

    IncreaseValue(value:int):int=0
    DecreaseValue(value:int):int=0
    IncreaseValue(value:float):float=0.0
    DecreaseValue(value:float):float=0.0

    DecreasePositiveValue(value:int)<transacts>:logic={false}



PersistableWood:=class(PersistableItem):

    IncreaseValue<override>(value:int):int=
        if(Player:=PPlayer?, CurrentPlayerData:=PlayerData[Player]):
            NewPlayerData:=PlayerPersistance{
                Wood:=CurrentPlayerData.Wood+value
                Stone:=CurrentPlayerData.Stone
                ActiveTiles:= CurrentPlayerData.ActiveTiles

            }
            if(set PlayerData[Player] = NewPlayerData):
                return NewPlayerData.Wood

        return -1

    DecreaseValue<override>(value:int):int=
        if(Player:=PPlayer?,CurrentPlayerData:=PlayerData[Player]):
            NewPlayerData:=PlayerPersistance{
                Wood:=CurrentPlayerData.Wood-value
                Stone:=CurrentPlayerData.Stone
                ActiveTiles:= CurrentPlayerData.ActiveTiles

            }
            if(set PlayerData[Player] = NewPlayerData):
                return NewPlayerData.Wood

        return -1

    DecreasePositiveValue<override>(value:int)<transacts>:logic=
        if(Player:=PPlayer?,CurrentPlayerData:=PlayerData[Player]):
            if(CurrentPlayerData.Wood>=value):
                NewPlayerData:=PlayerPersistance{
                    Wood:=CurrentPlayerData.Wood-value
                    Stone:=CurrentPlayerData.Stone
                    ActiveTiles:= CurrentPlayerData.ActiveTiles

                }
                if(set PlayerData[Player] = NewPlayerData):
                    return true

        return false


    GetValue()<transacts>:int=
        if(Player:=PPlayer?,CurrentPlayerData:=PlayerData[Player]):
            return CurrentPlayerData.Wood

        return -1

PersistableStone:=class(PersistableItem):

    IncreaseValue<override>(value:int):int=
        if(Player:=PPlayer?, CurrentPlayerData:=PlayerData[Player]):
            NewPlayerData:=PlayerPersistance{
                Wood:=CurrentPlayerData.Wood
                Stone:=CurrentPlayerData.Stone+value
                ActiveTiles:= CurrentPlayerData.ActiveTiles
            }
            if(set PlayerData[Player] = NewPlayerData):
                return NewPlayerData.Stone

        return -1

    DecreaseValue<override>(value:int):int=
        if(Player:=PPlayer?,CurrentPlayerData:=PlayerData[Player]):
            NewPlayerData:=PlayerPersistance{
                Wood:=CurrentPlayerData.Wood
                Stone:=CurrentPlayerData.Stone-value
                ActiveTiles:= CurrentPlayerData.ActiveTiles
            }
            if(set PlayerData[Player] = NewPlayerData):
                return NewPlayerData.Stone

        return -1

    GetValue()<transacts>:int=
        if(Player:=PPlayer?,CurrentPlayerData:=PlayerData[Player]):
            return CurrentPlayerData.Stone

        return -1

PersistableTile:=class(PersistableItem):
    Main:Tiles

    AddPersistantTile(tile:Tile):void=
        if(Player:=PPlayer?,CurrentPlayerData:=PlayerData[Player]):
            NewPlayerData:=PlayerPersistance{
                Wood:=CurrentPlayerData.Wood
                Stone:=CurrentPlayerData.Stone
                ActiveTiles:= CurrentPlayerData.ActiveTiles + array{PersistantTile{Position:=tile.Position}}
            }
            if(set PlayerData[Player] = NewPlayerData):
                Print("Tile added to player: ")
                return

        return

    InitTileArray()<suspends>:void=
        if(Player:=PPlayer?,CurrentPlayerData:=PlayerData[Player]):
            DBTiles:=CurrentPlayerData.ActiveTiles
            var CreatedTiles: []Tile= array{}
            for (tile : DBTiles):

                Type:=Main.DetermineZoneType(tile.Position)
                Props:= Main.GetPropsByType(Type)
                var PossibleTIle:Tile=Tile{Position:=tile.Position, Type:=Type, TilePropAsset:=Props(0), InactiveTileAsset:=Props(1), Parent:=Main, Player:=Player}
                for(Ltile:Main.TileArr):
                    if(Ltile.Position.Compare(PossibleTIle.Position)=0):
                        set PossibleTIle=Ltile
                set CreatedTiles += array{PossibleTIle}

            
            for(tile:CreatedTiles):
                tile.Activate()
        return


PersistantTile:=class<final><persistable>:
    Position:vector3

    
PlayerPersistance:=class<final><persistable>:
    Wood:int =0
    Stone:int =0
    ActiveTiles:[]PersistantTile = array{}

var PlayerData:weak_map(player,PlayerPersistance)= map{}
