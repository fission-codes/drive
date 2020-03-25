module Drive.State exposing (..)

import Browser.Navigation as Navigation
import Common
import Common.State as Common
import Debouncing
import Drive.Sidebar
import File exposing (File)
import File.Select
import Html.Events.Extra.Drag as Drag
import Ipfs
import Item exposing (Item)
import List.Extra as List
import Ports
import Result.Extra as Result
import Return exposing (return)
import Return.Extra as Return
import Routing
import Types exposing (..)
import Url



-- 📣


activateSidebarMode : Drive.Sidebar.Mode -> Manager
activateSidebarMode mode model =
    Return.singleton { model | sidebarMode = mode }


addFiles : File -> List File -> Manager
addFiles file otherFiles =
    -- TODO
    Return.singleton


askUserForFilesToAdd : Manager
askUserForFilesToAdd =
    Return.communicate (File.Select.files [] AddFiles)


closeSidebar : Manager
closeSidebar model =
    Return.singleton
        (if model.sidebarMode == Drive.Sidebar.defaultMode then
            { model
                | expandSidebar = False
                , selectedCid = Nothing
                , showPreviewOverlay = False
            }

         else
            { model
                | expandSidebar = False
                , sidebarMode = Drive.Sidebar.defaultMode
            }
        )


copyLink : Item -> Manager
copyLink item model =
    item
        |> Item.publicUrl (Common.base model)
        |> Ports.copyToClipboard
        |> Return.return model
        |> Return.command (Ports.showNotification "Copied shareable link to clipboard.")


digDeeper : { directoryName : String } -> Manager
digDeeper { directoryName } model =
    let
        directoryList =
            Result.withDefault [] model.directoryList

        currentPathSegments =
            Routing.treePathSegments model.route

        pathSegments =
            case model.ipfs of
                Ipfs.AdditionalListing ->
                    Maybe.withDefault [] (List.init currentPathSegments)

                _ ->
                    currentPathSegments

        updatedDirectoryList =
            List.map
                (\i ->
                    if i.name == directoryName then
                        { i | loading = True }

                    else
                        { i | loading = False }
                )
                directoryList
    in
    [ directoryName ]
        |> List.append pathSegments
        |> Routing.replaceTreePathSegments model.route
        |> Routing.adjustUrl model.url
        |> Url.toString
        |> Navigation.pushUrl model.navKey
        |> Return.return { model | directoryList = Ok updatedDirectoryList }


digDeeperUsingSelection : Manager
digDeeperUsingSelection model =
    case ( model.directoryList, model.selectedCid ) of
        ( Ok items, Just cid ) ->
            items
                |> List.find
                    (.path >> (==) cid)
                |> Maybe.map
                    (\item ->
                        if item.kind == Item.Directory then
                            digDeeper { directoryName = item.name } model

                        else
                            Return.singleton model
                    )
                |> Maybe.withDefault
                    (Return.singleton model)

        _ ->
            Return.singleton model


droppedSomeFiles : Drag.Event -> Manager
droppedSomeFiles event =
    -- TODO
    let
        _ =
            Debug.log "dropped" (List.map File.name event.dataTransfer.files)

        files =
            event.dataTransfer.files
    in
    Common.hideHelpfulNote


goUp : { floor : Int } -> Manager
goUp { floor } model =
    if floor >= 0 then
        (case floor of
            0 ->
                []

            x ->
                List.take (x - 1) (Routing.treePathSegments model.route)
        )
            |> Routing.replaceTreePathSegments model.route
            |> Routing.adjustUrl model.url
            |> Url.toString
            |> Navigation.pushUrl model.navKey
            |> Return.return model
            |> Return.andThen closeSidebar
            |> Return.command
                ({ on = True }
                    |> ToggleLoadingOverlay
                    |> Debouncing.loadingInput
                    |> Return.task
                )

    else
        Return.singleton model


goUpOneLevel : Manager
goUpOneLevel model =
    model.route
        |> Routing.treePathSegments
        |> List.length
        |> (\x -> goUp { floor = x } model)


select : Item -> Manager
select item model =
    return
        { model
            | selectedCid = Just item.path
            , sidebarMode = Drive.Sidebar.DetailsForSelection
        }
        (if Item.canRenderKind item.kind then
            Ports.renderMedia
                { id = item.id
                , name = item.name
                , path = item.path
                }

         else
            Cmd.none
        )


selectNextItem : Manager
selectNextItem =
    makeItemSelector
        (\i -> i + 1)
        (\_ -> 0)


selectPreviousItem : Manager
selectPreviousItem =
    makeItemSelector
        (\i -> i - 1)
        (\l -> List.length l - 1)


showPreviewOverlay : Manager
showPreviewOverlay model =
    Return.singleton { model | showPreviewOverlay = True }


toggleExpandedSidebar : Manager
toggleExpandedSidebar model =
    Return.singleton { model | expandSidebar = not model.expandSidebar }


toggleSidebarMode : Drive.Sidebar.Mode -> Manager
toggleSidebarMode mode model =
    if model.sidebarMode == Drive.Sidebar.defaultMode then
        Return.singleton
            { model
                | expandSidebar = False
                , sidebarMode = mode
            }

    else
        Return.singleton
            { model
                | expandSidebar = False
                , sidebarMode = Drive.Sidebar.defaultMode
            }



-- ㊙️


makeItemSelector : (Int -> Int) -> (List Item -> Int) -> Manager
makeItemSelector indexModifier fallbackIndexFn model =
    case ( model.directoryList, model.selectedCid ) of
        ( Ok items, Just selectedCid ) ->
            items
                |> List.findIndex (.path >> (==) selectedCid)
                |> Maybe.map indexModifier
                |> Maybe.andThen (\idx -> List.getAt idx items)
                |> Maybe.map (\item -> select item model)
                |> Maybe.withDefault (Return.singleton model)

        ( Ok items, Nothing ) ->
            items
                |> List.getAt (fallbackIndexFn items)
                |> Maybe.map (\item -> select item model)
                |> Maybe.withDefault (Return.singleton model)

        _ ->
            Return.singleton model
