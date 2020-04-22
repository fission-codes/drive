module Drive.ContextMenu exposing (hamburger, item)

import ContextMenu exposing (..)
import Drive.Item exposing (Kind(..))
import Drive.Sidebar as Sidebar
import FeatherIcons
import Routing
import Types exposing (..)



-- 🍔


hamburger : { authenticated : Bool } -> ContextMenu Msg
hamburger { authenticated } =
    ContextMenu.build
        TopRight
        (if authenticated then
            authenticatedBurgers ++ [ Divider ] ++ alwaysBurgers

         else
            unauthenticatedBurgers ++ [ Divider ] ++ alwaysBurgers
        )


authenticatedBurgers =
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


unauthenticatedBurgers =
    [ Item
        { icon = FeatherIcons.hardDrive
        , label = "Sign in"
        , active = False

        --
        , href = Nothing
        , msg = Just SignIn
        }
    ]


alwaysBurgers =
    [ Item
        { icon = FeatherIcons.hash
        , label = "Explore"
        , active = False

        --
        , href = Nothing
        , msg = Just (Reset Routing.Explore)
        }

    --
    , Item
        { icon = FeatherIcons.book
        , label = "Guide"
        , active = False

        --
        , href = Just "https://guide.fission.codes/drive"
        , msg = Nothing
        }

    --
    , Item
        { icon = FeatherIcons.lifeBuoy
        , label = "Support"
        , active = False

        --
        , href = Just "https://fission.codes/support"
        , msg = Nothing
        }
    ]



-- ITEM


item : ContextMenu.Hook -> Drive.Item.Item -> ContextMenu Msg
item hook context =
    ContextMenu.build
        hook
        (case context.kind of
            Directory ->
                [ driveLink context
                , copyCid context

                --
                , Divider

                --
                , removeItem context
                ]

            _ ->
                [ driveLink context
                , contentLink context
                , copyCid context

                --
                , Divider

                --
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
