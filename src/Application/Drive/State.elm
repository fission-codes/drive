module Drive.State exposing (..)

import Browser.Navigation as Navigation
import Common
import Common.State as Common
import Debouncing
import Drive.Item exposing (Item)
import Drive.Sidebar
import File exposing (File)
import File.Download
import File.Select
import Html.Events.Extra.Drag as Drag
import Ipfs exposing (Status(..))
import List.Ext as List
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


addFiles : { blobs : List { name : String, url : String } } -> Manager
addFiles { blobs } model =
    { blobs = blobs
    , pathSegments = Routing.treePathSegments model.route
    }
        |> Ports.ffsAddContent
        |> return { model | ipfs = FileSystemOperation }


closeSidebar : Manager
closeSidebar model =
    if model.sidebarMode == Drive.Sidebar.defaultMode then
        Return.singleton
            { model
                | expandSidebar = False
                , selectedPath = Nothing
                , showPreviewOverlay = False
            }

    else
        Common.potentiallyRenderMedia
            { model
                | expandSidebar = False
                , sidebarMode = Drive.Sidebar.defaultMode
            }


copyPublicUrl : { item : Item, presentable : Bool } -> Manager
copyPublicUrl { item, presentable } model =
    let
        base =
            Common.base { presentable = presentable } model

        notification =
            if presentable then
                "Copied Drive URL to clipboard."

            else
                "Copied Content URL to clipboard."
    in
    item
        |> Drive.Item.publicUrl base
        |> Ports.copyToClipboard
        |> Return.return model
        |> Return.command (Ports.showNotification notification)


copyToClipboard : { clip : String, notification : String } -> Manager
copyToClipboard { clip, notification } model =
    clip
        |> Ports.copyToClipboard
        |> Return.return model
        |> Return.command (Ports.showNotification notification)


createDirectory : Manager
createDirectory model =
    case String.trim model.createDirectoryInput of
        "" ->
            Return.singleton model

        directoryName ->
            model.route
                |> Routing.treePathSegments
                |> List.add [ directoryName ]
                |> (\p -> Ports.ffsCreateDirectory { pathSegments = p })
                |> return { model | ipfs = FileSystemOperation }


digDeeper : { directoryName : String } -> Manager
digDeeper { directoryName } model =
    let
        items =
            model.directoryList
                |> Result.map .items
                |> Result.withDefault []

        currentPathSegments =
            Routing.treePathSegments model.route

        pathSegments =
            case model.ipfs of
                Ipfs.AdditionalListing ->
                    Maybe.withDefault [] (List.init currentPathSegments)

                _ ->
                    currentPathSegments

        updatedItems =
            List.map
                (\i ->
                    if i.name == directoryName then
                        { i | loading = True }

                    else
                        { i | loading = False }
                )
                items

        updatedDirectoryList =
            Result.map (\l -> { l | items = updatedItems }) model.directoryList
    in
    [ directoryName ]
        |> List.append pathSegments
        |> Routing.replaceTreePathSegments model.route
        |> Routing.adjustUrl model.url
        |> Url.toString
        |> Navigation.pushUrl model.navKey
        |> Return.return { model | directoryList = updatedDirectoryList }


digDeeperUsingSelection : Manager
digDeeperUsingSelection model =
    case ( model.directoryList, model.selectedPath ) of
        ( Ok { items }, Just path ) ->
            items
                |> List.find
                    (.path >> (==) path)
                |> Maybe.map
                    (\item ->
                        if item.kind == Drive.Item.Directory then
                            digDeeper { directoryName = item.name } model

                        else
                            Return.singleton model
                    )
                |> Maybe.withDefault
                    (Return.singleton model)

        _ ->
            Return.singleton model


downloadItem : Item -> Manager
downloadItem item model =
    item
        |> Drive.Item.publicUrl (Common.base { presentable = False } model)
        |> File.Download.url
        |> return model


gotCreateDirectoryInput : String -> Manager
gotCreateDirectoryInput input model =
    Return.singleton { model | createDirectoryInput = input }


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
            |> Return.return { model | selectedPath = Nothing }
            |> Return.command
                ({ on = True }
                    |> ToggleLoadingOverlay
                    |> Debouncing.loading.provideInput
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
    Common.potentiallyRenderMedia
        { model
            | selectedPath = Just item.path
            , sidebarMode = Drive.Sidebar.DetailsForSelection
        }


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
        Common.potentiallyRenderMedia
            { model
                | expandSidebar = False
                , sidebarMode = Drive.Sidebar.defaultMode
            }



-- ㊙️


makeItemSelector : (Int -> Int) -> (List Item -> Int) -> Manager
makeItemSelector indexModifier fallbackIndexFn model =
    case ( model.directoryList, model.selectedPath ) of
        ( Ok { items }, Just selectedPath ) ->
            items
                |> List.findIndex (.path >> (==) selectedPath)
                |> Maybe.map indexModifier
                |> Maybe.andThen (\idx -> List.getAt idx items)
                |> Maybe.map (\item -> select item model)
                |> Maybe.withDefault (Return.singleton model)

        ( Ok { items }, Nothing ) ->
            items
                |> List.getAt (fallbackIndexFn items)
                |> Maybe.map (\item -> select item model)
                |> Maybe.withDefault (Return.singleton model)

        _ ->
            Return.singleton model
