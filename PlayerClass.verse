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

    Init():void=
        if(not PlayerData[Player]):
            if(set PlayerData[Player] = PlayerPersistance{}){}

        set Wood.PPlayer = option{Player}
        set Stone.PPlayer = option{Player}
                


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
            }
            if(set PlayerData[Player] = NewPlayerData):
                return NewPlayerData.Wood

        return -1

    DecreaseValue<override>(value:int):int=
        if(Player:=PPlayer?,CurrentPlayerData:=PlayerData[Player]):
            NewPlayerData:=PlayerPersistance{
                Wood:=CurrentPlayerData.Wood-value
                Stone:=CurrentPlayerData.Stone
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
            }
            if(set PlayerData[Player] = NewPlayerData):
                return NewPlayerData.Stone

        return -1

    DecreaseValue<override>(value:int):int=
        if(Player:=PPlayer?,CurrentPlayerData:=PlayerData[Player]):
            NewPlayerData:=PlayerPersistance{
                Wood:=CurrentPlayerData.Wood
                Stone:=CurrentPlayerData.Stone-value
            }
            if(set PlayerData[Player] = NewPlayerData):
                return NewPlayerData.Stone

        return -1

    GetValue()<transacts>:int=
        if(Player:=PPlayer?,CurrentPlayerData:=PlayerData[Player]):
            return CurrentPlayerData.Stone

        return -1


    
PlayerPersistance:=class<final><persistable>:
    Wood:int =0
    Stone:int =0

var PlayerData:weak_map(player,PlayerPersistance)= map{}
