module Return.Extra exposing (..)

{-| Extends the `Return` module.
-}


{-| Flipped version of `Return.return`.

    >>> communicate Cmd.none ()
    ( (), Cmd.none )

-}
communicate : Cmd msg -> model -> ( model, Cmd msg )
communicate cmd model =
    ( model, cmd )
