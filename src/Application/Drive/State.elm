module Drive.State exposing (..)

import Browser.Dom as Dom
import Browser.Navigation as Navigation
import Common
import Common.State as Common
import Debouncing
import Dict
import Drive.Item as Item exposing (Item, Kind(..))
import Drive.Modals
import Drive.Sidebar
import Drive.State.Sidebar
import File
import File.Download
import FileSystem exposing (Operation(..))
import List.Ext as List
import List.Extra as List
import Notifications
import Ports
import Radix exposing (..)
import Result.Extra as Result
import Return exposing (andThen, return)
import Return.Extra as Return
import Routing
import Set
import Task
import Toasty
import Url



-- 📣


activateSidebarAddOrCreate : Manager
activateSidebarAddOrCreate model =
    Return.singleton
        { model
            | sidebar = Just (Drive.Sidebar.AddOrCreate Drive.Sidebar.addOrCreate)
            , sidebarExpanded = False
        }


addFiles : { blobs : List { path : String, url : String } } -> Manager
addFiles { blobs } model =
    { blobs = blobs
    , pathSegments = Routing.treePathSegments model.route
    }
        |> Ports.fsAddContent
        |> return { model | fileSystemStatus = FileSystem.Operation AddingFiles }
        -- Notification
        |> Toasty.addConditionalToast
            (\m -> m.fileSystemStatus == FileSystem.Operation AddingFiles)
            Notifications.config
            ToastyMsg
            (Notifications.loadingIndication "Uploading files")


closeSidebar : Manager
closeSidebar model =
    { model
        | sidebar = Nothing
        , selectedPath = Nothing
    }
        |> (case model.sidebar of
                Just (Drive.Sidebar.Details _) ->
                    if Common.isSingleFileView model then
                        goUpOneLevel

                    else
                        Return.singleton

                _ ->
                    Return.singleton
           )


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
        |> Item.publicUrl base
        |> Ports.copyToClipboard
        |> Return.return model
        |> Return.command (Ports.showNotification notification)


copyToClipboard : { clip : String, notification : String } -> Manager
copyToClipboard { clip, notification } model =
    clip
        |> Ports.copyToClipboard
        |> Return.return model
        |> Return.command (Ports.showNotification notification)


createFileOrFolder : Maybe { extension : String } -> Manager
createFileOrFolder option model =
    case ( option, sidebarAddOrCreateInput model ) of
        ( Nothing, Just directoryName ) ->
            model.route
                |> Routing.treePathSegments
                |> List.add [ directoryName ]
                |> (\p -> Ports.fsCreateDirectory { pathSegments = p })
                |> return
                    ({ model | fileSystemStatus = FileSystem.Operation CreatingDirectory }
                        |> sidebarAddOrCreateClearInput
                    )

        ( Just { extension }, maybeFileName ) ->
            let
                ensureUniqueFileName m fileName =
                    m.directoryList
                        |> Result.toMaybe
                        |> Maybe.map
                            (.items
                                >> List.map .name
                                >> Set.fromList
                                >> ensureUnique fileName Nothing
                            )

                makeName prefix maybeSuffixNum =
                    case maybeSuffixNum of
                        Just suffixNum ->
                            prefix ++ " " ++ String.fromInt suffixNum ++ "." ++ extension

                        Nothing ->
                            prefix ++ "." ++ extension

                ensureUnique prefix maybeSuffix blacklisted =
                    let
                        name =
                            makeName prefix maybeSuffix
                    in
                    if Set.member name blacklisted then
                        maybeSuffix
                            |> Maybe.map ((+) 1)
                            |> Maybe.withDefault 2
                            |> Just
                            |> (\suff -> ensureUnique prefix suff blacklisted)

                    else
                        name
            in
            maybeFileName
                |> Maybe.withDefault "Untitled"
                |> ensureUniqueFileName model
                |> Maybe.map
                    (\fileName ->
                        model.route
                            |> Routing.treePathSegments
                            |> List.add [ fileName ]
                            |> (\p -> Ports.fsWriteItemUtf8 { pathSegments = p, text = "" })
                            |> return (sidebarAddOrCreateClearInput model)
                    )
                |> Maybe.withDefault (Return.singleton model)

        ( Nothing, _ ) ->
            Return.singleton model


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
            case model.fileSystemStatus of
                FileSystem.AdditionalListing ->
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
        |> Return.return
            { model
                | directoryList = updatedDirectoryList
            }


digDeeperUsingSelection : Manager
digDeeperUsingSelection model =
    case ( model.directoryList, model.selectedPath ) of
        ( Ok { items }, Just path ) ->
            items
                |> List.find
                    (.path >> (==) path)
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


downloadItem : Item -> Manager
downloadItem item model =
    item
        |> Item.pathProperties
        |> Ports.fsDownloadItem
        |> return model


gotAddCreateInput : String -> Manager
gotAddCreateInput input model =
    case model.sidebar of
        Just (Drive.Sidebar.AddOrCreate addOrCreate) ->
            Return.singleton
                { model
                    | sidebar =
                        { addOrCreate | input = input }
                            |> Drive.Sidebar.AddOrCreate
                            |> Just
                }

        _ ->
            Return.singleton model


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


removeItem : Item -> Manager
removeItem item model =
    item
        |> Item.pathProperties
        |> Ports.fsRemoveItem
        |> return { model | fileSystemStatus = FileSystem.Operation Deleting }
        -- Notification
        |> Toasty.addConditionalToast
            (\m -> m.fileSystemStatus == FileSystem.Operation Deleting)
            Notifications.config
            ToastyMsg
            (Notifications.loadingIndication <| "Removing “" ++ item.name ++ "”")


renameItem : Item -> Manager
renameItem item model =
    case Maybe.andThen (.state >> Dict.get "name") model.modal of
        Just newName ->
            let
                newNameProps =
                    case item.kind of
                        Directory ->
                            { base = newName
                            , extension = ""
                            }

                        _ ->
                            Item.nameProperties newName

                newDirectoryList =
                    case model.directoryList of
                        Ok a ->
                            a.items
                                |> List.map
                                    (\i ->
                                        if i.id == item.id then
                                            { i | name = newName, nameProperties = newNameProps }

                                        else
                                            i
                                    )
                                |> (\items -> Ok { a | items = items })

                        Err e ->
                            Err e
            in
            { currentPathSegments = String.split "/" item.path
            , pathSegments = Routing.treePathSegments model.route ++ [ newName ]
            }
                |> Ports.fsMoveItem
                |> return { model | directoryList = newDirectoryList }
                |> andThen Common.hideModal

        Nothing ->
            Common.hideModal model


select : Item -> Manager
select item model =
    if item.kind == Code || item.kind == Text then
        Ports.fsReadItemUtf8 (Item.pathProperties item)
            |> return
                { model
                    | selectedPath = Just item.path
                    , sidebar =
                        { path = item.path
                        , editor = Nothing
                        }
                            |> Drive.Sidebar.EditPlaintext
                            |> Just
                }

    else
        Return.singleton
            { model
                | selectedPath = Just item.path
                , sidebar =
                    item.path
                        |> Drive.Sidebar.details
                        |> Just
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


showRenameItemModal : Item -> Manager
showRenameItemModal item model =
    return
        { model | modal = Just (Drive.Modals.renameItem item) }
        (Task.attempt (\_ -> Bypass) <| Dom.focus "modal__rename-item__input")


sidebarAddOrCreateInput : Model -> Maybe String
sidebarAddOrCreateInput model =
    case model.sidebar of
        Just (Drive.Sidebar.AddOrCreate { input }) ->
            case String.trim input of
                "" ->
                    Nothing

                directoryName ->
                    Just directoryName

        _ ->
            Nothing


sidebarAddOrCreateClearInput : Model -> Model
sidebarAddOrCreateClearInput model =
    case model.sidebar of
        Just (Drive.Sidebar.AddOrCreate addOrCreate) ->
            { addOrCreate | input = "" }
                |> Drive.Sidebar.AddOrCreate
                |> Just
                |> (\newSidebar -> { model | sidebar = newSidebar })

        _ ->
            model


toggleExpandedSidebar : Manager
toggleExpandedSidebar model =
    Return.singleton
        { model
            | sidebarExpanded = not model.sidebarExpanded
        }


toggleSidebarAddOrCreate : Manager
toggleSidebarAddOrCreate model =
    (case model.sidebar of
        Just (Drive.Sidebar.AddOrCreate _) ->
            Nothing

        _ ->
            Just (Drive.Sidebar.AddOrCreate Drive.Sidebar.addOrCreate)
    )
        |> (\newSidebar ->
                { model
                    | sidebar = newSidebar
                    , sidebarExpanded = False
                }
           )
        |> Return.singleton


updateSidebar : Drive.Sidebar.Msg -> Manager
updateSidebar sidebarMsg model =
    case model.sidebar of
        Just sidebar ->
            Drive.State.Sidebar.update sidebarMsg sidebar model

        Nothing ->
            Return.singleton model



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
