module Common.State exposing (..)

import ContextMenu exposing (ContextMenu)
import Debouncing
import Html.Events.Extra.Mouse as Mouse
import Return exposing (return)
import Return.Extra as Return
import Types exposing (..)



-- 📣


hideHelpfulNote : Manager
hideHelpfulNote model =
    model.helpfulNote
        |> Maybe.map (\n -> { n | faded = True })
        |> (\h -> { model | helpfulNote = h })
        |> Return.singleton
        |> Return.command
            (RemoveHelpfulNote
                |> Debouncing.notificationsInput
                |> Return.task
            )


removeContextMenu : Manager
removeContextMenu model =
    Return.singleton { model | contextMenu = Nothing }


removeHelpfulNote : Manager
removeHelpfulNote model =
    case Maybe.map .faded model.helpfulNote of
        Just True ->
            Return.singleton { model | helpfulNote = Nothing }

        _ ->
            Return.singleton model


showContextMenu : ContextMenu Msg -> Mouse.Event -> Manager
showContextMenu menu event model =
    let
        menuWithPosition =
            { x = Tuple.first event.clientPos - Tuple.first event.offsetPos + 22
            , y = Tuple.second event.clientPos - Tuple.second event.offsetPos + 40
            }
                |> ContextMenu.position menu
    in
    Return.singleton { model | contextMenu = Just menuWithPosition }


showHelpfulNote : String -> Manager
showHelpfulNote note model =
    return
        { model | helpfulNote = Just { faded = False, note = note } }
        (HideHelpfulNote
            |> Debouncing.notificationsInput
            |> Return.task
        )
