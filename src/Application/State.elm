module State exposing (init, subscriptions, update)

import Browser.Navigation as Navigation
import Explore.State as Explore
import Ipfs
import Ipfs.State as Ipfs
import Ipfs.Types as Ipfs
import Navigation.State as Navigation
import Ports
import Return exposing (return)
import Routing
import Types exposing (..)
import Url exposing (Url)



-- 🌱


init : Flags -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init flags url navKey =
    ( -----------------------------------------
      -- Model
      -----------------------------------------
      { directoryList = Ok []
      , exploreInput = flags.rootCid
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

        --
        ExploreMsg a ->
            Explore.update a

        IpfsMsg a ->
            Ipfs.update a

        NavigationMsg a ->
            Navigation.update a



-- 📰


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.ipfsCompletedSetup (IpfsMsg << always Ipfs.SetupCompleted)
        , Ports.ipfsGotDirectoryList (IpfsMsg << Ipfs.GotDirectoryList)
        , Ports.ipfsGotError (IpfsMsg << Ipfs.GotError)
        ]
