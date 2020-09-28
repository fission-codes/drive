module Html.Events.Ext exposing (..)

import Html
import Html.Events
import Json.Decode as Decode


onTap : msg -> Html.Attribute msg
onTap msg =
    Html.Events.custom
        "click"
        (Decode.andThen
            (\button ->
                case button of
                    Just 2 ->
                        Decode.fail "Ignore right click"

                    _ ->
                        Decode.succeed
                            { message = msg
                            , stopPropagation = True
                            , preventDefault = True
                            }
            )
            (Decode.int
                |> Decode.at [ "originalEvent", "button" ]
                |> Decode.maybe
            )
        )
