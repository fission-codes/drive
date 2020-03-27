module Drive.ContextMenu exposing (..)

import ContextMenu exposing (..)
import Drive.Item exposing (Kind(..))
import Drive.Sidebar as Sidebar
import FeatherIcons
import Types exposing (..)



-- 🍔


hamburger : ContextMenu Msg
hamburger =
    ContextMenu.build
        TopRight
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
        , Divider

        --
        , Item
            { icon = FeatherIcons.hash
            , label = "Change CID"
            , active = False

            --
            , href = Nothing
            , msg = Just Reset
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


item : Drive.Item.Item -> ContextMenu Msg
item context =
    ContextMenu.build
        BottomCenter
        (case context.kind of
            Directory ->
                [ driveLink context
                , copyCid context
                ]

            _ ->
                [ driveLink context
                , contentLink context
                , copyCid context
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
