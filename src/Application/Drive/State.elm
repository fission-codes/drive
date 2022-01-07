module Drive.State exposing (..)

import Browser.Dom as Dom
import Browser.Navigation as Navigation
import Common exposing (ifThenElse)
import Common.State as Common
import Debouncing
import Dict
import Drive.Item as Item exposing (Item, Kind(..))
import Drive.Item.Inventory as Inventory exposing (Inventory)
import Drive.Modals
import Drive.Sidebar as Sidebar
import Drive.Sidebar.State as Sidebar
import FileSystem exposing (Operation(..))
import FileSystem.Actions
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
import Webnative exposing (DecodedResponse(..))
import Webnative.Path as Path exposing (Path)
import Webnative.Path.Encapsulated as Path
import Webnative.Path.Extra as Path
import Wnfs



-- 📣


activateSidebarAddOrCreate : Manager
activateSidebarAddOrCreate model =
    Return.singleton
        { model
            | sidebar = Just (Sidebar.AddOrCreate Sidebar.addOrCreate)
            , sidebarExpanded = False
        }


addFiles : { blobs : List { path : String, url : String } } -> Manager
addFiles { blobs } model =
    case Routing.treeDirectory model.route of
        Just path ->
            { blobs = blobs
            , toPath = Path.encode path
            }
                |> Ports.fsAddContent
                |> return { model | fileSystemStatus = FileSystem.Operation AddingFiles }
                -- Notification
                |> Toasty.addConditionalToast
                    (\m -> m.fileSystemStatus == FileSystem.Operation AddingFiles)
                    Notifications.config
                    ToastyMsg
                    (Notifications.loadingIndication "Uploading files")

        Nothing ->
            -- Invalid scenario
            Return.singleton model


clearSelection : Manager
clearSelection model =
    model.directoryList
        |> Result.map Inventory.clearSelection
        |> assignNewDirectoryList { model | sidebar = Nothing }
        |> Return.singleton


closeSidebar : Manager
closeSidebar model =
    { model | sidebar = Nothing }
        |> clearDirectoryListSelection
        |> (case model.sidebar of
                Just (Sidebar.EditPlaintext _) ->
                    if Common.isSingleFileView model then
                        goUpOneLevel

                    else
                        Return.singleton

                Just (Sidebar.Details _) ->
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


createFolder : Manager
createFolder model =
    case ( sidebarAddOrCreateInput model, Routing.treeDirectory model.route ) of
        ( Just directoryName, Just currentPath ) ->
            currentPath
                |> Path.endWith directoryName
                |> (\p ->
                        FileSystem.Actions.createDirectory
                            { path = p
                            , tag = CreatedDirectory
                            }
                   )
                |> return
                    (model.sidebar
                        |> Maybe.map
                            (Sidebar.mapAddOrCreate
                                (\m -> { m | isCreating = True })
                            )
                        |> replaceSidebar
                            { model
                                | fileSystemStatus =
                                    FileSystem.Operation CreatingDirectory
                            }
                    )

        _ ->
            Return.singleton model


createFile : Manager
createFile model =
    let
        maybeFileName =
            sidebarAddOrCreateInput model

        ensureUniqueFileName m fileName =
            m.directoryList
                |> Result.toMaybe
                |> Maybe.map
                    (.items
                        >> List.map .name
                        >> Set.fromList
                        >> ensureUnique fileName Nothing
                    )

        extension =
            case model.sidebar of
                Just (Sidebar.AddOrCreate { kind }) ->
                    Item.generateExtensionForKind kind

                _ ->
                    ""

        makeName prefix maybeSuffixNum =
            case maybeSuffixNum of
                Just suffixNum ->
                    prefix ++ " " ++ String.fromInt suffixNum ++ extension

                Nothing ->
                    prefix ++ extension

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
        |> Maybe.map2
            (\currentPath fileName ->
                currentPath
                    |> Path.addFile fileName
                    |> (\path ->
                            FileSystem.Actions.writeUtf8
                                { path = path
                                , tag = CreatedEmptyFile { path = Path.encapsulate path }
                                , content = ""
                                }
                       )
                    |> return
                        (model.sidebar
                            |> Maybe.map
                                (Sidebar.mapAddOrCreate
                                    (\m -> { m | isCreating = True })
                                )
                            |> replaceSidebar
                                model
                        )
            )
            (Routing.treeDirectory model.route)
        |> Maybe.withDefault
            (Return.singleton model)


digDeeper : { directoryName : String } -> Manager
digDeeper { directoryName } model =
    case Routing.treePath model.route of
        Just currentPath ->
            let
                items =
                    model.directoryList
                        |> Result.map .items
                        |> Result.withDefault []

                path =
                    case model.fileSystemStatus of
                        FileSystem.AdditionalListing ->
                            Path.init currentPath

                        _ ->
                            currentPath

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
            path
                |> Path.endWith directoryName
                |> Routing.replaceTreePath model.route
                |> Routing.routeToUrl model.url
                |> Url.toString
                |> Navigation.pushUrl model.navKey
                |> Return.return { model | directoryList = updatedDirectoryList }

        Nothing ->
            Return.singleton model


digDeeperUsingSelection : Manager
digDeeperUsingSelection model =
    case model.directoryList of
        Ok { items, selection } ->
            selection
                |> List.head
                |> Maybe.andThen
                    (\{ index } -> List.getAt index items)
                |> Maybe.map
                    (\item ->
                        if item.kind == Item.Directory then
                            digDeeper { directoryName = item.name } model

                        else
                            Return.singleton model
                    )
                |> Maybe.withDefault
                    (Return.singleton model)

        Err _ ->
            Return.singleton model


downloadItem : Item -> Manager
downloadItem item model =
    item
        |> Item.portablePath
        |> Ports.fsDownloadItem
        |> return model


followSymlink : Item -> Manager
followSymlink item model =
    item
        |> Item.portablePath
        |> Ports.fsFollowItem
        |> return model


gotAddCreateInput : String -> Manager
gotAddCreateInput input model =
    model.sidebar
        |> Maybe.map (Sidebar.mapAddOrCreate (\m -> { m | input = input }))
        |> replaceSidebar model
        |> Return.singleton


gotWebnativeResponse : Webnative.Response -> Manager
gotWebnativeResponse response model =
    case FileSystem.Actions.decodeResponse response of
        -- NOTE: We don't initialize webnative
        Webnative _ ->
            Return.singleton model

        -----------------------------------------
        -- WNFS
        -----------------------------------------
        Wnfs (SidebarTag sidebarTag) artifact ->
            updateSidebarTag sidebarTag artifact model

        Wnfs (CreatedEmptyFile { path }) _ ->
            model.sidebar
                |> Maybe.map
                    (Sidebar.mapAddOrCreate
                        (\m -> { m | input = "", isCreating = False })
                    )
                |> replaceSidebar
                    model
                |> Return.singleton
                |> Return.command
                    (FileSystem.Actions.publish
                        { tag = UpdatedFileSystem }
                    )

        Wnfs CreatedDirectory _ ->
            model.sidebar
                |> Maybe.map
                    (Sidebar.mapAddOrCreate
                        (\m -> { m | input = "", isCreating = False })
                    )
                |> replaceSidebar
                    model
                |> Return.singleton
                |> Return.command
                    (FileSystem.Actions.publish
                        { tag = UpdatedFileSystem }
                    )

        Wnfs UpdatedFileSystem _ ->
            case Routing.treePath model.route of
                Just path ->
                    { path = Path.encode path }
                        |> Ports.fsListDirectory
                        |> return model

                Nothing ->
                    Return.singleton model

        -----------------------------------------
        -- TODO: Error handling
        -----------------------------------------
        Webnative.WnfsError err ->
            Return.singleton model

        Webnative.WebnativeError err ->
            Return.singleton model


goUp : { floor : Int } -> Manager
goUp { floor } model =
    case Routing.treePath model.route of
        Just currentPath ->
            currentPath
                |> Path.map (List.take <| max 0 <| floor - 1)
                |> Routing.replaceTreePath model.route
                |> Routing.routeToUrl model.url
                |> Url.toString
                |> Navigation.pushUrl model.navKey
                |> Return.return (clearDirectoryListSelection model)
                |> Return.command
                    ({ on = True }
                        |> ToggleLoadingOverlay
                        |> Debouncing.loading.provideInput
                        |> Return.task
                    )

        _ ->
            Return.singleton model


goUpOneLevel : Manager
goUpOneLevel model =
    model.route
        |> Routing.treePathSegments
        |> List.length
        |> (\x -> goUp { floor = x } model)


individualSelect : Int -> Item -> Manager
individualSelect idx item model =
    case model.directoryList of
        Ok ({ selection } as directoryList) ->
            let
                selectedIndexes =
                    List.map .index selection

                newSelection =
                    if List.member idx selectedIndexes then
                        List.filter (.index >> (/=) idx) selection

                    else
                        selection
                            |> (::) { index = idx, isFirst = False }
                            |> List.sortBy .index

                newInventory =
                    { directoryList | selection = newSelection }
            in
            if List.length newSelection > 1 then
                Return.singleton
                    { model
                        | directoryList = Ok newInventory
                        , sidebar =
                            newInventory
                                |> Inventory.selectionItems
                                |> List.map .path
                                |> Sidebar.details
                                |> Just
                    }

            else
                select idx item model

        Err _ ->
            Return.singleton model


rangeSelect : Int -> Item -> Manager
rangeSelect targetIndex item model =
    case Result.map (\a -> ( a, a.selection )) model.directoryList of
        Ok ( { selection } as directoryList, { index } :: _ ) ->
            -- Adjust existing selection
            let
                startIndex =
                    index

                range =
                    if startIndex <= targetIndex then
                        List.range startIndex targetIndex

                    else
                        List.range targetIndex startIndex

                newInventory =
                    range
                        |> List.map (\i -> { index = i, isFirst = i == startIndex })
                        |> (\s -> { directoryList | selection = s })

                sidebar =
                    if List.length range > 1 then
                        newInventory
                            |> Inventory.selectionItems
                            |> List.map .path
                            |> Sidebar.details
                            |> Just

                    else
                        model.sidebar
            in
            Return.singleton
                { model
                    | directoryList = Ok newInventory
                    , sidebar = sidebar
                }

        _ ->
            -- New selection
            select targetIndex item model


removeItem : Item -> Manager
removeItem item model =
    item
        |> Item.portablePath
        |> Ports.fsRemoveItem
        |> return
            { model
                | fileSystemStatus = FileSystem.Operation Deleting
                , sidebar =
                    case model.sidebar of
                        Just (Sidebar.Details { paths }) ->
                            ifThenElse (List.member item.path paths) Nothing model.sidebar

                        Just (Sidebar.EditPlaintext { path }) ->
                            ifThenElse (Path.encapsulate path == item.path) Nothing model.sidebar

                        a ->
                            a
            }
        -- Notification
        |> Toasty.addConditionalToast
            (\m -> m.fileSystemStatus == FileSystem.Operation Deleting)
            Notifications.config
            ToastyMsg
            (Notifications.loadingIndication <| "Removing “" ++ item.name ++ "”")


removeSelectedItems : Manager
removeSelectedItems model =
    model.directoryList
        |> Result.map Inventory.selectionItems
        |> Result.withDefault []
        |> List.foldl
            (\item -> Return.andThen <| removeItem item)
            (Return.singleton model)


renameItem : Item -> Manager
renameItem item model =
    case
        ( Maybe.andThen (.state >> Dict.get "name") model.modal
        , Routing.treeDirectory model.route
        )
    of
        ( Just rawNewName, Just currentPath ) ->
            let
                newName =
                    rawNewName
                        |> String.replace "../" ""
                        |> String.replace "./" ""
                        |> String.replace "/" "-"

                newNameProps =
                    case item.kind of
                        Directory ->
                            { base = newName
                            , extension = ""
                            }

                        _ ->
                            Item.nameProperties newName

                newDirectoryListItems =
                    model.directoryList
                        |> Result.map .items
                        |> Result.withDefault []
                        |> List.map
                            (\i ->
                                if i.id == item.id then
                                    { i | name = newName, nameProperties = newNameProps }

                                else
                                    i
                            )

                newDirectoryList =
                    Result.map
                        (\a -> { a | items = newDirectoryListItems })
                        model.directoryList
            in
            { fromPath = Path.encode item.path
            , toPath = Path.encode (Path.addFile newName currentPath)
            }
                |> Ports.fsMoveItem
                |> return { model | directoryList = newDirectoryList }
                |> andThen Common.hideModal

        _ ->
            Common.hideModal model


replaceAddOrCreateKind : Kind -> Manager
replaceAddOrCreateKind kind model =
    model.sidebar
        |> Maybe.map (Sidebar.mapAddOrCreate (\m -> { m | kind = kind }))
        |> replaceSidebar model
        |> Return.singleton


select : Int -> Item -> Manager
select idx item model =
    let
        showEditor =
            Item.canBeOpenedWithEditor item
    in
    return
        { model
            | directoryList =
                Result.map
                    (\d -> { d | selection = [ { index = idx, isFirst = True } ] })
                    model.directoryList
            , sidebar =
                if showEditor then
                    Maybe.map
                        (\filePath ->
                            Sidebar.EditPlaintext
                                { path = filePath
                                , editor = Nothing
                                }
                        )
                        (Path.toFile item.path)

                else
                    [ item.path ]
                        |> Sidebar.details
                        |> Just
        }
        (case ( showEditor, Path.toFile item.path ) of
            ( True, Just filePath ) ->
                FileSystem.Actions.readUtf8
                    { path =
                        filePath
                    , tag =
                        { path = filePath }
                            |> Sidebar.LoadedFile
                            |> SidebarTag
                    }

            _ ->
                Cmd.none
        )


selectNextItem : Manager
selectNextItem model =
    makeItemSelector
        (\i -> i + 1)
        (\_ -> 0)
        (case model.directoryList of
            Ok { selection } ->
                List.last selection

            Err _ ->
                Nothing
        )
        model


selectPreviousItem : Manager
selectPreviousItem model =
    makeItemSelector
        (\i -> i - 1)
        (\l -> List.length l - 1)
        (case model.directoryList of
            Ok { selection } ->
                List.head selection

            Err _ ->
                Nothing
        )
        model


showRenameItemModal : Item -> Manager
showRenameItemModal item model =
    return
        { model | modal = Just (Drive.Modals.renameItem item) }
        (Task.attempt (\_ -> Bypass) <| Dom.focus "modal__rename-item__input")


sidebarAddOrCreateInput : Model -> Maybe String
sidebarAddOrCreateInput model =
    case model.sidebar of
        Just (Sidebar.AddOrCreate { input }) ->
            case String.trim input of
                "" ->
                    Nothing

                s ->
                    Just s

        _ ->
            Nothing


toggleExpandedSidebar : Manager
toggleExpandedSidebar model =
    Return.singleton
        { model
            | sidebarExpanded = not model.sidebarExpanded
        }


toggleSidebarAddOrCreate : Manager
toggleSidebarAddOrCreate model =
    (case model.sidebar of
        Just (Sidebar.AddOrCreate _) ->
            Nothing

        _ ->
            Just (Sidebar.AddOrCreate Sidebar.addOrCreate)
    )
        |> (\newSidebar ->
                { model
                    | sidebar = newSidebar
                    , sidebarExpanded = False
                }
           )
        |> Return.singleton


updateSidebar : Sidebar.Msg -> Manager
updateSidebar sidebarMsg model =
    case model.sidebar of
        Just sidebar ->
            Sidebar.update sidebarMsg sidebar model

        Nothing ->
            Return.singleton model


updateSidebarTag : Sidebar.Tag -> Wnfs.Artifact -> Manager
updateSidebarTag sidebarTag artifact model =
    case model.sidebar of
        Just sidebar ->
            Sidebar.updateTag sidebarTag artifact sidebar model

        Nothing ->
            Return.singleton model



-- ㊙️


assignNewDirectoryList : Model -> Result String Inventory -> Model
assignNewDirectoryList model directoryList =
    { model | directoryList = directoryList }


clearDirectoryListSelection : Model -> Model
clearDirectoryListSelection model =
    model.directoryList
        |> Result.map Inventory.clearSelection
        |> assignNewDirectoryList model


makeItemSelector : (Int -> Int) -> (List Item -> Int) -> Maybe { index : Int, isFirst : Bool } -> Manager
makeItemSelector indexModifier fallbackIndexFn maybeSelected model =
    case ( model.directoryList, maybeSelected ) of
        ( Ok { items }, Just { index } ) ->
            let
                idx =
                    indexModifier index
            in
            items
                |> List.getAt idx
                |> Maybe.map (\item -> select idx item model)
                |> Maybe.withDefault (Return.singleton model)

        ( Ok { items }, Nothing ) ->
            let
                idx =
                    fallbackIndexFn items
            in
            items
                |> List.getAt idx
                |> Maybe.map (\item -> select idx item model)
                |> Maybe.withDefault (Return.singleton model)

        _ ->
            Return.singleton model


replaceSidebar : Model -> Maybe Sidebar.Model -> Model
replaceSidebar model maybeSidebar =
    { model | sidebar = maybeSidebar }
