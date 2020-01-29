module State exposing (init, subscriptions, update)

import Browser.Navigation as Nav
import Ipfs
import Ports
import Return exposing (return)
import State.Ipfs
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
    case Debug.log "" msg of
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
