module Navigation.State exposing (..)

import Browser
import Browser.Navigation as Navigation
import Ipfs.State
import Navigation.Types as Navigation exposing (..)
import Ports
import Result.Extra as Result
import Return exposing (return)
import Return.Extra as Return exposing (returnWith)
import Routing exposing (Page(..))
import Types as Root exposing (Model, Msg)
import Url exposing (Url)
import Url.Builder



-- 📣


update : Navigation.Msg -> Root.Manager
update msg =
    case msg of
        DigDeeper a ->
            digDeeper a

        GoUp a ->
            goUp a

        LinkClicked a ->
            linkClicked a

        UrlChanged a ->
            urlChanged a



-- TRAVERSAL


digDeeper : String -> Root.Manager
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
        |> Drive
        |> Routing.adjustUrl model.url
        |> Url.toString
        |> Navigation.pushUrl model.navKey
        |> Return.return model



-- URL


linkClicked : Browser.UrlRequest -> Root.Manager
linkClicked urlRequest model =
    case urlRequest of
        Browser.Internal url ->
            returnWith (Navigation.pushUrl model.navKey <| Url.toString url) model

        Browser.External href ->
            returnWith (Navigation.load href) model


urlChanged : Url -> Root.Manager
urlChanged url oldModel =
    let
        newPage =
            Routing.pageFromUrl url

        newModel =
            { oldModel | page = newPage, url = url }
    in
    return
        newModel
        (if newPage /= oldModel.page then
            Ipfs.State.getDirectoryListCmd newModel

         else
            Cmd.none
        )
