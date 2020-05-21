module Drive.ContextMenu exposing (hamburger, item)

import Authentication.External exposing (authenticationUrl)
import Common
import ContextMenu exposing (..)
import Drive.Item exposing (Kind(..))
import Drive.Sidebar as Sidebar
import FeatherIcons
import List.Ext as List
import Maybe.Extra as Maybe
import Routing
import Types exposing (..)



-- 🍔


hamburger : Model -> ContextMenu Msg
hamburger model =
    (if Common.isAuthenticatedAndNotExploring model then
        yourBurgers

     else if Maybe.isJust model.authenticated then
        model.authenticated
            |> Maybe.map .dnsLink
            |> Maybe.withDefault ""
            |> authenticatedOtherBurgers

     else
        unauthenticatedBurgers model
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

    -- TODO:
    --
    -- , Item
    --     { icon = FeatherIcons.user
    --     , label = "Sign out"
    --     , active = False
    --
    --     --
    --     , href = Nothing
    --     , msg = Just (Reset Routing.Undecided)
    --     }
    ]


authenticatedOtherBurgers dnsLink =
    [ Item
        { icon = FeatherIcons.hardDrive
        , label = "My Drive"
        , active = False

        --
        , href = Nothing
        , msg =
            []
                |> Routing.Tree { root = dnsLink }
                |> GoToRoute
                |> Just
        }
    ]


unauthenticatedBurgers model =
    [ Item
        { icon = FeatherIcons.user
        , label = "Sign in"
        , active = False

        --
        , href = Just { newTab = False, url = authenticationUrl model.didKey model.url }
        , msg = Nothing
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
                List.append
                    [ driveLink context
                    , copyCid context
                    ]
                    (if isGroundFloor && context.name == "public" then
                        []

                     else
                        [ Divider
                        , removeItem context
                        ]
                    )

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
