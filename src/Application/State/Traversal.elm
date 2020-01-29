module State.Traversal exposing (..)

import Browser.Navigation as Nav
import Return
import Routing exposing (Page(..))
import Types exposing (..)
import Url
import Url.Builder



-- 🛠


digDeeper : String -> Model -> ( Model, Cmd Msg )
digDeeper directoryName model =
    let
        newPage =
            Routing.addDrivePathSegments [ directoryName ] model.page

        directoryList =
            Maybe.withDefault [] model.directoryList

        alreadyDigging =
            List.any .loading directoryList

        updatedDirectoryList =
            List.map
                (\i ->
                    if i.name == directoryName then
                        { i | loading = True }

                    else
                        i
                )
                directoryList
    in
    if alreadyDigging then
        Return.singleton model

    else
        newPage
            |> Routing.adjustUrl model.url
            |> Url.toString
            |> Nav.pushUrl model.navKey
            |> Return.return { model | directoryList = Just updatedDirectoryList }


goUp : { floor : Int } -> Model -> ( Model, Cmd Msg )
goUp { floor } model =
    (case floor of
        0 ->
            []

        x ->
            List.take (x - 1) (Routing.drivePathSegments model.page)
    )
        |> Drive
        |> Routing.adjustUrl model.url
        |> Url.toString
        |> Nav.pushUrl model.navKey
        |> Return.return model
