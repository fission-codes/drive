module State exposing (init, subscriptions, update)

import Browser.Navigation as Nav
import Ipfs
import Ports
import Return exposing (return)
import Routing
import State.Ipfs
import State.Traversal
import State.Url
import Types exposing (..)
import Url exposing (Url)



-- 🌱


init : Flags -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url navKey =
    ( -----------------------------------------
      -- Model
      -----------------------------------------
      { directoryList = Nothing
      , ipfs = Ipfs.Connecting
      , navKey = navKey
      , page = Routing.pageFromUrl url
      , rootCid = flags.rootCid
      , url = url
      }
      -----------------------------------------
      -- Command
      -----------------------------------------
    , Ports.ipfsSetup ()
    )



-- 📣


update : Msg -> Model -> ( Model, Cmd Msg )
update msg =
    case msg of
        Bypass ->
            Return.singleton

        -----------------------------------------
        -- IPFS
        -----------------------------------------
        IpfsGotDirectoryList encodedDirList ->
            State.Ipfs.gotDirectoryList encodedDirList

        IpfsSetupCompleted ->
            State.Ipfs.setupCompleted

        -----------------------------------------
        -- Traversal
        -----------------------------------------
        DigDeeper directoryName ->
            State.Traversal.digDeeper directoryName

        GoUp args ->
            State.Traversal.goUp args

        -----------------------------------------
        -- URL
        -----------------------------------------
        LinkClicked urlRequest ->
            State.Url.linkClicked urlRequest

        UrlChanged url ->
            State.Url.urlChanged url



-- 📰


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.ipfsCompletedSetup (\_ -> IpfsSetupCompleted)
        , Ports.ipfsGotDirectoryList IpfsGotDirectoryList
        ]
