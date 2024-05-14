using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Characters }
using { /Verse.org/Assets }
using { /Verse.org/Random }
using { /UnrealEngine.com/Temporary/UI }
using { /Fortnite.com/UI }
using { /Verse.org/Colors }
using {hp_ui}
Health_UI := class:
    var Canvas:canvas =canvas{}
    Main:Tiles
    var DefaultWidth:float = 500.0
    var DefaultHeight:float = 50.0
    var IsActive : logic =false
    var LastUUID:string = ""
    var FullHP:texture_block= texture_block{
        DefaultImage:= HP_full,
        DefaultDesiredSize:=vector2{X:=500.0, Y:=50.0}
    }
    var DrainingHP:texture_block= texture_block{
        DefaultImage:= HP_drain,
        DefaultDesiredSize:=vector2{X:=500.0, Y:=50.0}
    }
    var EmptyHP:texture_block= texture_block{
        DefaultImage:= HP_empty,
        DefaultDesiredSize:=vector2{X:=500.0, Y:=50.0}
    }
    var TextWidget:text_block=text_block{
        DefaultTextColor:=color{R:=0.0, G:=0.0, B:=0.0}
    }

    CreateCanvas():void=
        set Canvas=  canvas: 
            Slots := array:
                canvas_slot:
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.1}, Maximum := vector2{X := 0.5, Y := 0.1}}
                    Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.5, Y := 0.5}
                    Widget :=  
                         overlay: 
                            Slots:=array: 
                                overlay_slot:
                                    Widget:=EmptyHP
                                overlay_slot:
                                    HorizontalAlignment:=horizontal_alignment.Left
                                    Widget:=DrainingHP
                                overlay_slot:
                                    HorizontalAlignment:=horizontal_alignment.Left
                                    Widget:=FullHP
                                overlay_slot:
                                    HorizontalAlignment:=horizontal_alignment.Center
                                    Widget:=TextWidget
            
    


    SHowUiToPlayer(Player:agent):void=
        CreateCanvas()
        if(PlayerUI:= GetPlayerUI[player[Player]]):
            PlayerUI.AddWidget(Canvas, player_ui_slot{})

        
            
    
    RemoveUIFromPlayer(Player:agent):void=
        if(PlayerUI:= GetPlayerUI[player[Player]]):
            set IsActive= false
            PlayerUI.RemoveWidget(Canvas)

    UpdateUI(Player:agent, resource:Resource)<suspends>:void=
        if(not LastUUID = resource.UUID or IsActive = false):
            set IsActive= true
            set LastUUID= resource.UUID
            if(not LastUUID = ""):
                RemoveUIFromPlayer(Player)
            SHowUiToPlayer(Player)
        if(IntHP:= Floor[resource.HP], IntFullHP:= Floor[resource.resourceType.FullHP]):
            TextWidget.SetText(SetText("HP: {IntHP}/{IntFullHP}"))
            HPPercentage:= resource.HP/resource.resourceType.FullHP
            NewWidth:= DefaultWidth*HPPercentage
            CurrentWidth:= DrainingHP.GetDesiredSize().X
            FullHP.SetDesiredSize(vector2{X:=NewWidth, Y:=DefaultHeight})
            Decrements:= (CurrentWidth-NewWidth)/10.0
            
            for(I:=1..10):
                DrainingHP.SetDesiredSize(vector2{X:=CurrentWidth-Decrements*I, Y:=DefaultHeight})
                Sleep(0.1)





