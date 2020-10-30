module Drive.ContextMenu exposing (hamburger, item)

import Authentication.Essentials as Authentication
import Common
import ContextMenu exposing (..)
import Drive.Item exposing (Kind(..))
import Drive.Sidebar as Sidebar
import FeatherIcons
import List.Ext as List
import Maybe.Extra as Maybe
import Radix exposing (..)
import Routing



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
    List.append
        (if Common.isSingleFileView model then
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
        , msg = Just (GoToRoute <| Routing.Tree { root = username } [])
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


item : ContextMenu.Hook -> { isGroundFloor : Bool, enableDownload : Bool } -> Drive.Item.Item -> ContextMenu Msg
item hook { isGroundFloor, enableDownload } context =
    let
        isPublicPath =
            String.startsWith "public/" context.path
                || (context.path
                        |> String.split "/"
                        |> List.drop 1
                        |> List.head
                        |> (==) (Just "pretty")
                   )
    in
    ContextMenu.build
        hook
        (case context.kind of
            Directory ->
                List.concat
                    [ [ driveLink context ]
                    , Common.when isPublicPath
                        [ copyCid context ]
                    , Common.when (not (isGroundFloor && context.name == "public"))
                        [ Divider
                        , renameItem context
                        , removeItem context
                        ]
                    ]

            _ ->
                List.concat
                    [ Common.when enableDownload
                        [ downloadItem context
                        , Divider
                        ]
                    , [ driveLink context ]
                    , Common.when isPublicPath
                        [ contentLink context
                        , copyCid context
                        ]
                    , [ Divider ]
                    , [ renameItem context
                      , removeItem context
                      ]
                    ]
        )


contentLink context =
    Item
        { icon = FeatherIcons.file
        , label = "Link to file"
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
    Item
        { icon = FeatherIcons.hash
        , label = "Copy CID"
        , active = False

        --
        , href = Nothing
        , msg =
            { clip = context.cid
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
