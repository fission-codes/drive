module Html.Events.Ext exposing (..)

import Html
import Html.Events
import Json.Decode as Decode


onTap : msg -> Html.Attribute msg
onTap msg =
    Html.Events.on "tap"
        (Decode.andThen
            (\button ->
                case button of
                    Just 2 ->
                        Decode.fail "Ignore right click"

                    _ ->
                        Decode.succeed msg
            )
            (Decode.maybe (Decode.at [ "originalEvent", "button" ] Decode.int))
        )
