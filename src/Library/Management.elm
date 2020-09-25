module Management exposing (..)

-- 📣


type alias Manager msg model =
    model -> ( model, Cmd msg )
