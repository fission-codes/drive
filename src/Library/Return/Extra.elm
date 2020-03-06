module Return.Extra exposing (..)

{-| Extends the `Return` module.
-}

import Task


{-| Flipped version of `Return.return`.

    >>> communicate Cmd.none ()
    ( (), Cmd.none )

-}
communicate : Cmd msg -> model -> ( model, Cmd msg )
communicate cmd model =
    ( model, cmd )


{-| Send a message using a command.
-}
task : msg -> Cmd msg
task msg =
    msg
        |> Task.succeed
        |> Task.perform identity
