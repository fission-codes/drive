module Return.Extra exposing (..)

{-| Extends the `Return` module.
-}


{-| Flipped version of `Return.return`.

    >>> returnWith Cmd.none ()
    ( (), Cmd.none )

-}
returnWith : Cmd msg -> model -> ( model, Cmd msg )
returnWith cmd model =
    ( model, cmd )
