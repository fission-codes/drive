module Drive.State exposing (..)

import Browser.Navigation as Navigation
import Drive.Types as Drive exposing (..)
import Result.Extra as Result
import Return exposing (return)
import Routing
import Types as Root
import Url



-- 📣


update : Drive.Msg -> Root.Manager
update msg =
    case msg of
        DigDeeper a ->
            digDeeper a

        GoUp a ->
            goUp a

        Select a ->
            select a



-- 🛠


digDeeper : { directoryName : String } -> Root.Manager
digDeeper { directoryName } model =
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
            |> Navigation.pushUrl model.navKey
            |> Return.return { model | directoryList = Ok updatedDirectoryList }


goUp : { floor : Int } -> Root.Manager
goUp { floor } model =
    (case floor of
        0 ->
            []

        x ->
            List.take (x - 1) (Routing.drivePathSegments model.page)
    )
        |> Routing.Drive
        |> Routing.adjustUrl model.url
        |> Url.toString
        |> Navigation.pushUrl model.navKey
        |> Return.return { model | selectedCid = Nothing }


select : { cid : String } -> Root.Manager
select { cid } model =
    Return.singleton { model | selectedCid = Just cid }
