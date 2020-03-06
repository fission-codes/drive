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
import Other.State as Other
import Ports
import Return exposing (return)
import Routing
import Task
import Time
import Types exposing (..)
import Url exposing (Url)



-- 🌱


init : Flags -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init flags url navKey =
    ( -----------------------------------------
      -- Model
      -----------------------------------------
      { currentTime = Time.millisToPosix 0
      , directoryList = Ok []
      , exploreInput = Just (Maybe.withDefault defaultCid flags.rootCid)
      , ipfs = Ipfs.Connecting
      , largePreview = False
      , navKey = navKey
      , page = Routing.pageFromUrl url
      , pressedKeys = []
      , rootCid = flags.rootCid
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

        -- Keep track of which keyboard keys are pressed
        , Sub.map KeyboardInteraction Keyboard.subscriptions

        -- Check every 30 seconds what the current time is
        , Time.every (30 * 1000) SetCurrentTime
        ]
