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

Drop_UI := class:
    var Canvas: canvas = canvas{}
    var CurrentActive:int = 0
    

    GetTextureByType(Type: string)<transacts>: texture_block =
        case(Type):
            "wood" => return texture_block{
                DefaultImage:= textures.wood_resource
                DefaultDesiredSize := vector2{X := 64.0, Y := 64.0}
            }
            "Stone" =>return texture_block{
                DefaultImage:= textures.stone_resource
                DefaultDesiredSize := vector2{X := 64.0, Y := 64.0}
            }
            _=>return texture_block{
                DefaultImage:= textures.wood_resource
                DefaultDesiredSize := vector2{X := 64.0, Y := 64.0}
            }


    CreateCanvas(): void =
        set Canvas = canvas{
            Slots := array{
                canvas_slot{
                    Anchors := anchors{Minimum := vector2{X := 0.7, Y := 0.8}, Maximum := vector2{X := 0.7, Y := 0.8}},
                    Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0},
                    Alignment := vector2{X := 0.5, Y := 0.5},
                    Widget := overlay{
                        Slots := array{
                            }
                        }
                    }
                }
            }
        

    AddElement(Player: agent, Amount: int, Type: string)<suspends>: void =
        TextWidget: text_block = text_block{DefaultTextColor := color{R := 0.0, G := 0.0, B := 0.0}}
        TextWidget.SetText(SetText("+ {Amount}"))
        FadeUp(Player, Type,GetTextureByType(Type), TextWidget)

    FadeUp(Player: agent, Type:string, Texture:texture_block, TextWidget:text_block ) <suspends>: void =
        set CurrentActive+=1
        var StackBoxWidget :stack_box=stack_box:
            Orientation:=orientation.Horizontal
            Slots:=array:
                stack_box_slot:
                    Padding:=margin{Right:=8.0}
                    Widget:=Texture
                stack_box_slot:
                    Widget:=TextWidget
        
        for (I := 0..50):
            if (ActualOpacity := type{_X: float where 0.000000 <= _X, _X <= 1.000000}[1.0 - I * 1.0 / 100.0]):
                TextWidget.SetTextOpacity(ActualOpacity)
                NewStackBox:=stack_box:
                    Orientation:=orientation.Horizontal
                    Slots:=array:
                        stack_box_slot:
                            Padding:=margin{Right:=8.0}
                            Widget:=Texture
                        stack_box_slot:
                            Widget:=TextWidget
                NewOverlay:=overlay_slot{
                    Padding := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := I*4.0},
                    HorizontalAlignment := horizontal_alignment.Center,
                    Widget := NewStackBox
                }
                # Update the Canvas with the modified Overlay slot
                NewSlot:= canvas_slot{
                    Anchors := anchors{Minimum := vector2{X := 0.7, Y := 0.8}, Maximum := vector2{X := 0.7, Y := 0.8}},
                    Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0},
                    Alignment := vector2{X := 0.5, Y := 0.5},
                    Widget := overlay{
                        Slots := array{
                            NewOverlay
                        }
                    }
                }
                Canvas.AddWidget(NewSlot)
                
           
            Sleep(0.02)
        TextWidget.SetEnabled(false)
        Texture.SetEnabled(false)
        set CurrentActive-=1
        if(CurrentActive<=0):
            RemoveUIFromPlayer(Player)
            ShowUIToPlayer(Player)


        

    ShowUIToPlayer(Player: agent): void =
        CreateCanvas()
        if (PlayerUI := GetPlayerUI[player[Player]]):
            PlayerUI.AddWidget(Canvas, player_ui_slot{})

   

        

    RemoveUIFromPlayer(Player:agent,?Active:logic=false):void=
        if(PlayerUI:= GetPlayerUI[player[Player]]):
            PlayerUI.RemoveWidget(Canvas)
        