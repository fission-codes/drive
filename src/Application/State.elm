module State exposing (init, subscriptions, update)

import Browser.Navigation as Navigation
import Drive.State as Drive
import Explore.State as Explore
import Ipfs
import Ipfs.State as Ipfs
import Ipfs.Types as Ipfs
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
      , exploreInput = flags.rootCid
      , ipfs = Ipfs.Connecting
      , navKey = navKey
      , page = Routing.pageFromUrl url
      , rootCid = flags.rootCid
      , selectedCid = Nothing
      , url = url
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
        -- Bits
        -----------------------------------------
        DriveMsg a ->
            Drive.update a

        ExploreMsg a ->
            Explore.update a

        IpfsMsg a ->
            Ipfs.update a

        -----------------------------------------
        -- Other
        -----------------------------------------
        LinkClicked a ->
            Other.linkClicked a

        SetCurrentTime a ->
            Other.setCurrentTime a

        UrlChanged a ->
            Other.urlChanged a



-- 📰


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.ipfsCompletedSetup (IpfsMsg << always Ipfs.SetupCompleted)
        , Ports.ipfsGotDirectoryList (IpfsMsg << Ipfs.GotDirectoryList)
        , Ports.ipfsGotError (IpfsMsg << Ipfs.GotError)

        -- Check every 30 seconds what the current time is
        , Time.every (30 * 1000) SetCurrentTime
        ]
