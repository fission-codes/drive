module Drive.State exposing (..)

import Browser.Navigation as Navigation
import Common
import Item exposing (Item)
import Ports
import Result.Extra as Result
import Return exposing (return)
import Routing
import Types exposing (..)
import Url



-- 📣


copyLink : Item -> Manager
copyLink item model =
    item
        |> Item.publicUrl (Common.directoryPath model)
        |> Ports.copyToClipboard
        |> Return.return model
        |> Return.command (Ports.showNotification "Copied shareable link to clipboard.")


digDeeper : { directoryName : String } -> Manager
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


goUp : { floor : Int } -> Manager
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
        |> Return.return model
        |> Return.andThen removeSelection


removeSelection : Manager
removeSelection model =
    Return.singleton
        { model
            | largePreview = False
            , selectedCid = Nothing
            , showPreviewOverlay = False
        }


select : Item -> Manager
select item model =
    return
        { model | selectedCid = Just item.path }
        (if Item.canRenderKind item.kind then
            Ports.renderMedia
                { id = item.id
                , name = item.name
                , path = item.path
                }

         else
            Cmd.none
        )


showPreviewOverlay : Manager
showPreviewOverlay model =
    Return.singleton { model | showPreviewOverlay = True }


toggleLargePreview : Manager
toggleLargePreview model =
    Return.singleton { model | largePreview = not model.largePreview }
