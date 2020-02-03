module Management exposing (..)

-- 📣


type alias Manager msg model =
    model -> ( model, Cmd msg )



-- 🛠


{-| For working with nested models.

    manage : Nested.Manager -> UI.Manager
    manage =
        Management.supervise
            { getter = .nested
            , setter = \ui nested -> { ui | nested = nested }
            }

    update : Nested.Msg -> UI.Manager
    update msg =
        case msg of
            NestedMsg ->
                manage handleNestedMsg

-}
supervise :
    { getter : parent -> nested
    , setter : parent -> nested -> parent
    }
    -> Manager msg nested
    -> Manager msg parent
supervise { getter, setter } manager parent =
    parent
        |> getter
        |> manager
        |> Tuple.mapFirst (setter parent)
