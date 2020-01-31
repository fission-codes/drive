module State.Traversal exposing (..)

import Browser.Navigation as Nav
import Result.Extra as Result
import Return
import Routing exposing (Page(..))
import Types exposing (..)
import Url
import Url.Builder



-- 🛠


digDeeper : String -> Model -> ( Model, Cmd Msg )
digDeeper directoryName model =
    let
        directoryList =
            Result.withDefault [] model.directoryList

        shouldntDig =
            Result.isErr model.directoryList || List.any .loading directoryList

        newPage =
            Routing.addDrivePathSegments [ directoryName ] model.page

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
    if shouldntDig then
        Return.singleton model

    else
        newPage
            |> Routing.adjustUrl model.url
            |> Url.toString
            |> Nav.pushUrl model.navKey
            |> Return.return { model | directoryList = Ok updatedDirectoryList }


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
