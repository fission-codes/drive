module Drive.ContextMenu exposing (hamburger, item, kind, selection)

import Common
import ContextMenu exposing (..)
import Drive.Item exposing (Kind(..))
import FeatherIcons
import List.Ext as List
import Radix exposing (..)
import Result.Extra as Result
import Routing
import Webnative.Path as Path



-- 🍔


hamburger : Model -> ContextMenu Msg
hamburger model =
    (if Routing.isAuthenticatedTree model.authenticated model.route then
        yourBurgers model

     else
        case model.authenticated of
            Just a ->
                distractedBurgers a.username

            Nothing ->
                unauthenticatedBurgers
    )
        |> List.add ([ Divider ] ++ alwaysBurgers)
        |> ContextMenu.build TopRight


yourBurgers model =
    let
        isReadOnlyDirectory =
            Result.unwrap False .readOnly model.directoryList
    in
    List.append
        (if Common.isSingleFileView model || isReadOnlyDirectory then
            []

         else
            [ Item
                { icon = FeatherIcons.upload
                , label = "Add files"
                , active = False

                --
                , href = Nothing
                , msg = Just ActivateSidebarAddOrCreate
                }

            --
            , Item
                { icon = FeatherIcons.folderPlus
                , label = "Create directory"
                , active = False

                --
                , href = Nothing
                , msg = Just ActivateSidebarAddOrCreate
                }
            ]
        )
        [ Item
            { icon = FeatherIcons.user
            , label = "Sign out"
            , active = False

            --
            , href = Nothing
            , msg = Just (Reset Routing.Undecided)
            }
        ]


distractedBurgers username =
    [ Item
        { icon = FeatherIcons.hardDrive
        , label = "My Drive"
        , active = False

        --
        , href = Nothing
        , msg = Just (GoToRoute <| Routing.treeRootTopLevel username)
        }
    ]


unauthenticatedBurgers =
    [ Item
        { icon = FeatherIcons.user
        , label = "Sign in"
        , active = False

        --
        , href = Nothing
        , msg = Just RedirectToLobby
        }
    ]


alwaysBurgers =
    [ Item
        { icon = FeatherIcons.book
        , label = "Guide"
        , active = False

        --
        , href = Just { newTab = True, url = "https://guide.fission.codes/drive" }
        , msg = Nothing
        }

    --
    , Item
        { icon = FeatherIcons.lifeBuoy
        , label = "Support"
        , active = False

        --
        , href = Just { newTab = True, url = "https://fission.codes/support" }
        , msg = Nothing
        }
    ]



-- ITEM


item : ContextMenu.Hook -> { isGroundFloor : Bool } -> Drive.Item.Item -> ContextMenu Msg
item hook { isGroundFloor } context =
    let
        isPublicPath =
            case Path.unwrap context.path of
                "public" :: _ ->
                    True

                _ :: "p" :: _ ->
                    True

                _ ->
                    False

        isPrivatePath =
            not isPublicPath
    in
    ContextMenu.build
        hook
        (case context.kind of
            Directory ->
                List.concat
                    [ [ driveLink context ]

                    --
                    , Common.when isPrivatePath
                        [ share context ]

                    --
                    , Common.when isPublicPath
                        [ contentLink context
                        , copyCid context
                        ]

                    --
                    , Common.when
                        (not (isGroundFloor && context.name == "public")
                            && not context.readOnly
                        )
                        [ Divider
                        , renameItem context
                        , removeItem context
                        ]
                    ]

            _ ->
                List.concat
                    [ [ downloadItem context
                      , driveLink context
                      ]

                    --
                    , Common.when isPrivatePath
                        [ share context ]

                    --
                    , Common.when isPublicPath
                        [ contentLink context
                        , copyCid context
                        ]

                    --
                    , Common.when
                        (not context.readOnly)
                        [ Divider
                        , renameItem context
                        , removeItem context
                        ]
                    ]
        )


contentLink context =
    Item
        { icon =
            case context.kind of
                Directory ->
                    FeatherIcons.folder

                _ ->
                    FeatherIcons.file
        , label =
            case context.kind of
                Directory ->
                    "Link to directory"

                _ ->
                    "Link to file"
        , active = False

        --
        , href = Nothing
        , msg =
            { item = context
            , presentable = False
            }
                |> CopyPublicUrl
                |> Just
        }


copyCid context =
    -- TODO: Add replacement for symlinks
    Item
        { icon = FeatherIcons.hash
        , label = "Copy CID"
        , active = False

        --
        , href = Nothing
        , msg =
            { clip = context.id
            , notification = "Copied CID to clipboard."
            }
                |> CopyToClipboard
                |> Just
        }


driveLink context =
    Item
        { icon = FeatherIcons.share
        , label = "Link to Drive page"
        , active = False

        --
        , href = Nothing
        , msg =
            { item = context
            , presentable = True
            }
                |> CopyPublicUrl
                |> Just
        }


renameItem context =
    Item
        { icon = FeatherIcons.edit2
        , label = "Rename"
        , active = False

        --
        , href = Nothing
        , msg =
            context
                |> ShowRenameItemModal
                |> Just
        }


removeItem context =
    Item
        { icon = FeatherIcons.trash2
        , label = "Remove"
        , active = False

        --
        , href = Nothing
        , msg =
            context
                |> RemoveItem
                |> Just
        }


downloadItem context =
    Item
        { icon = FeatherIcons.download
        , label = "Download"
        , active = False

        --
        , href = Nothing
        , msg =
            context
                |> DownloadItem
                |> Just
        }


share context =
    Item
        { icon = FeatherIcons.share
        , label = "Share with Fission user"
        , active = False

        --
        , href = Nothing
        , msg =
            context
                |> ShowShareItemModal
                |> Just
        }



-- KIND


kind : ContextMenu.Hook -> Kind -> ContextMenu Msg
kind hook active =
    [ Directory

    --
    , Text
    , RichText
    , Code
    , Other
    ]
        |> List.map
            (\k ->
                Item
                    { icon = Drive.Item.kindIcon k
                    , label = Drive.Item.generateExtensionForKindDescription k
                    , active = active == k

                    --
                    , href = Nothing
                    , msg = Just (ReplaceAddOrCreateKind k)
                    }
            )
        |> ContextMenu.build
            hook



-- SELECTION


selection : ContextMenu.Hook -> ContextMenu Msg
selection hook =
    ContextMenu.build
        hook
        [ Item
            { icon = FeatherIcons.trash2
            , label = "Remove all"
            , active = False

            --
            , href = Nothing
            , msg = Just RemoveSelectedItems
            }
        ]
