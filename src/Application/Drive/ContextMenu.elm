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
        yourBurgers

     else
        case model.authenticated of
            Just a ->
                distractedBurgers a.username

            Nothing ->
                unauthenticatedBurgers
    )
        |> List.add ([ Divider ] ++ alwaysBurgers)
        |> ContextMenu.build TopRight


yourBurgers =
    [ Item
        { icon = FeatherIcons.upload
        , label = "Add files"
        , active = False

        --
        , href = Nothing
        , msg = Just (ActivateSidebarMode Sidebar.AddOrCreate)
        }

    --
    , Item
        { icon = FeatherIcons.folderPlus
        , label = "Create directory"
        , active = False

        --
        , href = Nothing
        , msg = Just (ActivateSidebarMode Sidebar.AddOrCreate)
        }

    --
    , Item
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


item : ContextMenu.Hook -> { isGroundFloor : Bool } -> Drive.Item.Item -> ContextMenu Msg
item hook { isGroundFloor } context =
    ContextMenu.build
        hook
        (case context.kind of
            Directory ->
                [ driveLink context
                ]
                    |> (if String.startsWith "public/" context.path then
                            List.add [ copyCid context ]

                        else
                            identity
                       )
                    |> List.add
                        (if isGroundFloor && context.name == "public" then
                            []

                         else
                            [ Divider
                            , renameItem context
                            , removeItem context
                            ]
                        )

            _ ->
                [ driveLink context
                ]
                    |> (if String.startsWith "public/" context.path then
                            List.add [ contentLink context ]

                        else
                            identity
                       )
                    |> (if String.startsWith "public/" context.path then
                            List.add [ copyCid context ]

                        else
                            identity
                       )
                    |> List.add
                        [ Divider
                        , renameItem context
                        , removeItem context
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
