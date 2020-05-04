module Html.Events.Ext exposing (..)

import Html
import Html.Events
import Json.Decode as Decode


onTap : msg -> Html.Attribute msg
onTap msg =
    Html.Events.on "tap"
        (Decode.andThen
            (\button ->
                if button /= 2 then
                    Decode.succeed msg

                else
                    Decode.fail "Ignore right click"
            )
            (Decode.at [ "originalEvent", "button" ] Decode.int)
        )
