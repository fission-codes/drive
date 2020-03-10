module State exposing (init, subscriptions, update)

import Browser.Navigation as Navigation
import Common exposing (defaultCid)
import Debouncer.Messages as Debouncer exposing (Debouncer)
import Debouncing
import Drive.State as Drive
import Explore.State as Explore
import Ipfs
import Ipfs.State as Ipfs
import Keyboard
import Maybe.Extra as Maybe
import Other.State as Other
import Ports
import Return exposing (return)
import Routing exposing (Route(..))
import Task
import Time
import Types exposing (..)
import Url exposing (Url)



-- 🌱


init : Flags -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init flags url navKey =
    let
        route =
            Routing.routeFromUrl url

        foundation =
            -- `flags.foundation` is a cached version of a resolved ipfs address.
            -- We only want to keep that, if the unresolved ipfs address in
            -- the url is the same. Otherwise we should resolve the requested
            -- ipfs address first (this happens after the ipfs setup).
            case ( flags.foundation, route ) of
                ( Just cachedFoundation, Tree { root } _ ) ->
                    if root /= cachedFoundation.unresolved then
                        Nothing

                    else
                        Just cachedFoundation

                _ ->
                    Nothing

        exploreInput =
            foundation
                |> Maybe.map .unresolved
                |> Maybe.orElse (Routing.treeRoot route)
                |> Maybe.withDefault defaultCid
    in
    ( -----------------------------------------
      -- Model
      -----------------------------------------
      { currentTime = Time.millisToPosix 0
      , directoryList = Ok []
      , exploreInput = Just exploreInput
      , ipfs = Ipfs.Connecting
      , largePreview = False
      , navKey = navKey
      , route = Routing.routeFromUrl url
      , pressedKeys = []
      , foundation = foundation
      , selectedCid = Nothing
      , showLoadingOverlay = False
      , showPreviewOverlay = False
      , url = url

      -- Debouncers
      -------------
      , loadingDebouncer = Debouncing.loading
      }
      -----------------------------------------
      -- Command
      -----------------------------------------
    , Cmd.batch
        [ Ports.ipfsSetup ()
        , Task.perform SetCurrentTime Time.now
        ]
    )



-- 📣


update : Msg -> Model -> ( Model, Cmd Msg )
update msg =
    case msg of
        Bypass ->
            Return.singleton

        -----------------------------------------
        -- Debouncers
        -----------------------------------------
        LoadingDebouncerMsg a ->
            Debouncer.update update Debouncing.loadingUpdateConfig a

        -----------------------------------------
        -- Drive
        -----------------------------------------
        CopyLink a ->
            Drive.copyLink a

        DigDeeper a ->
            Drive.digDeeper a

        GoUp a ->
            Drive.goUp a

        RemoveSelection ->
            Drive.removeSelection

        Select a ->
            Drive.select a

        ShowPreviewOverlay ->
            Drive.showPreviewOverlay

        ToggleLargePreview ->
            Drive.toggleLargePreview

        -----------------------------------------
        -- Explore
        -----------------------------------------
        Explore ->
            Explore.explore

        GotInput a ->
            Explore.gotInput a

        Reset ->
            Explore.reset

        -----------------------------------------
        -- Ipfs
        -----------------------------------------
        GotDirectoryList a ->
            Ipfs.gotDirectoryList a

        GotError a ->
            Ipfs.gotError a

        GotResolvedAddress a ->
            Ipfs.gotResolvedAddress a

        SetupCompleted ->
            Ipfs.setupCompleted

        -----------------------------------------
        -- Other
        -----------------------------------------
        KeyboardInteraction a ->
            Other.keyboardInteraction a

        LinkClicked a ->
            Other.linkClicked a

        SetCurrentTime a ->
            Other.setCurrentTime a

        ToggleLoadingOverlay a ->
            Other.toggleLoadingOverlay a

        UrlChanged a ->
            Other.urlChanged a



-- 📰


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.ipfsCompletedSetup (always SetupCompleted)
        , Ports.ipfsGotDirectoryList GotDirectoryList
        , Ports.ipfsGotError GotError
        , Ports.ipfsGotResolvedAddress GotResolvedAddress

        -- Keep track of which keyboard keys are pressed
        , Sub.map KeyboardInteraction Keyboard.subscriptions

        -- Check every 30 seconds what the current time is
        , Time.every (30 * 1000) SetCurrentTime
        ]
