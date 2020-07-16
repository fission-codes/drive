module Common.State exposing (..)

import Browser.Navigation as Navigation
import Common exposing (defaultDnsLink)
import ContextMenu exposing (ContextMenu, Hook(..))
import Coordinates exposing (Coordinates)
import Debouncing
import Dict
import Drive.Item
import Html.Events.Extra.Mouse as Mouse
import List.Extra as List
import Maybe.Extra as Maybe
import Ports
import Return exposing (andThen, return)
import Return.Extra as Return
import Routing exposing (Route)
import Types exposing (..)
import Url



-- 📣


goToRoute : Route -> Manager
goToRoute route model =
    route
        |> Routing.adjustUrl model.url
        |> Url.toString
        |> Navigation.pushUrl model.navKey
        |> return model


hideHelpfulNote : Manager
hideHelpfulNote model =
    model.helpfulNote
        |> Maybe.map (\n -> { n | faded = True })
        |> (\h -> { model | helpfulNote = h })
        |> Return.singleton
        |> Return.command
            (RemoveHelpfulNote
                |> Debouncing.notifications.provideInput
                |> Return.task
            )


hideModal : Manager
hideModal model =
    Return.singleton { model | modal = Nothing }


potentiallyRenderMedia : Manager
potentiallyRenderMedia model =
    case
        Maybe.andThen
            (\path ->
                model.directoryList
                    |> Result.map .items
                    |> Result.withDefault []
                    |> List.find (.path >> (==) path)
            )
            model.selectedPath
    of
        Just item ->
            if Drive.Item.canRenderKind item.kind then
                { id = item.id
                , name = item.name
                , path = item.path
                , useFS = Maybe.isJust model.authenticated
                }
                    |> Ports.renderMedia
                    |> return model

            else
                Return.singleton model

        Nothing ->
            Return.singleton model


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


reset : Route -> Manager
reset route model =
    [ Ports.annihilateKeys ()
    , Ports.deauthenticate ()
    , Ports.removeStoredFoundation ()
    ]
        |> Cmd.batch
        |> return
            { model
                | directoryList = Ok { floor = 1, items = [] }
                , exploreInput = Just defaultDnsLink
                , foundation = Nothing
                , selectedPath = Nothing
            }
        |> andThen
            (goToRoute route)


setModalState : String -> String -> Manager
setModalState k v model =
    case model.modal of
        Just modal ->
            { modal | state = Dict.insert k v modal.state }
                |> (\m -> { model | modal = Just m })
                |> Return.singleton

        Nothing ->
            Return.singleton model


showContextMenu : ContextMenu Msg -> Mouse.Event -> Manager
showContextMenu menu event model =
    let
        xOffset =
            -- TODO: We need to get the element width
            case ContextMenu.hook menu of
                BottomCenter ->
                    Tuple.first event.offsetPos - 9

                TopCenterWithoutOffset ->
                    0

                TopRight ->
                    Tuple.first event.offsetPos - 22

        yOffset =
            case ContextMenu.hook menu of
                BottomCenter ->
                    Tuple.second event.offsetPos + 15

                TopCenterWithoutOffset ->
                    -15

                TopRight ->
                    Tuple.second event.offsetPos - 40

        menuWithPosition =
            { x = Tuple.first event.clientPos - xOffset
            , y = Tuple.second event.clientPos - yOffset
            }
                |> ContextMenu.position menu
    in
    Return.singleton { model | contextMenu = Just menuWithPosition }


showContextMenuWithCoordinates : Coordinates -> ContextMenu Msg -> Manager
showContextMenuWithCoordinates coordinates menu model =
    coordinates
        |> ContextMenu.position menu
        |> (\c -> { model | contextMenu = Just c })
        |> Return.singleton


showHelpfulNote : String -> Manager
showHelpfulNote note model =
    return
        { model | helpfulNote = Just { faded = False, note = note } }
        (HideHelpfulNote
            |> Debouncing.notifications.provideInput
            |> Return.task
        )
