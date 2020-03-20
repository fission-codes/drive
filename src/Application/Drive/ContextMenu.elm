module Drive.ContextMenu exposing (..)

import ContextMenu exposing (..)
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
