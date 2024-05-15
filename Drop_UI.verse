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
    var Overlay: overlay_slot = overlay_slot{Widget := text_block{}}
    var TextWidget: text_block = text_block{DefaultTextColor := color{R := 0.0, G := 0.0, B := 0.0}}

    CreateCanvas(Player: agent, Amount: int, Type: string): void =
        TextWidget.SetText(SetText("+ {Amount}"))
        set Overlay = overlay_slot{
            HorizontalAlignment := horizontal_alignment.Center,
            Widget := TextWidget
        }
        set Canvas = canvas{
            Slots := array{
                canvas_slot{
                    Anchors := anchors{Minimum := vector2{X := 0.7, Y := 0.8}, Maximum := vector2{X := 0.7, Y := 0.8}},
                    Offsets := margin{Top := 0.0, Left := 0.0, Right := 0.0, Bottom := 0.0},
                    Alignment := vector2{X := 0.5, Y := 0.5},
                    Widget := overlay{
                        Slots := array{
                            Overlay
                        }
                    }
                }
            }
        }
        spawn. FadeUp(Player)

    FadeUp(Player: agent) <suspends>: void =
        for (I := 0..100):
            if (ActualOpacity := type{_X: float where 0.000000 <= _X, _X <= 1.000000}[1.0 - I * 1.0 / 100.0]):
                TextWidget.SetTextOpacity(ActualOpacity)
                NewOverlay:= overlay_slot{
                    HorizontalAlignment := horizontal_alignment.Center,
                    Widget := TextWidget,
                    Padding := margin{Bottom := I * 4.0}
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
                set Overlay = NewOverlay
                Canvas.AddWidget(NewSlot)
                Canvas.RemoveWidget(TextWidget)
            Sleep(0.01)
        RemoveUIFromPlayer(Player)

    ShowUIToPlayer(Player: agent, Amount: int, Type: string): void =
        CreateCanvas(Player, Amount, Type)
        if (PlayerUI := GetPlayerUI[player[Player]]):
            PlayerUI.AddWidget(Canvas, player_ui_slot{})

    RemoveUIFromPlayer(Player: agent): void =
        if (PlayerUI := GetPlayerUI[player[Player]]):
            PlayerUI.RemoveWidget(Canvas)
