module Debouncing exposing (..)

import Debouncer.Messages as Debouncer exposing (Debouncer, Milliseconds, fromSeconds)
import Radix exposing (..)
import Return



-- 🏔


loading =
    makeConfig
        { getter = .loadingDebouncer
        , setter = \debouncer model -> { model | loadingDebouncer = debouncer }

        --
        , msg = LoadingDebouncerMsg
        , settleAfter = fromSeconds 1.5
        }


notifications =
    makeConfig
        { getter = .notificationsDebouncer
        , setter = \debouncer model -> { model | notificationsDebouncer = debouncer }

        --
        , msg = NotificationsDebouncerMsg
        , settleAfter = fromSeconds 1
        }


usernameLookup =
    makeConfig
        { getter = .usernameLookupDebouncer
        , setter = \debouncer model -> { model | usernameLookupDebouncer = debouncer }

        --
        , msg = UsernameLookupDebouncerMsg
        , settleAfter = fromSeconds 1.5
        }



-- CANCELLING


cancelLoading : Manager
cancelLoading model =
    Return.singleton { model | loadingDebouncer = Debouncer.cancel model.loadingDebouncer }



-- ⚗️


type alias Config model msg =
    { getter : model -> Debouncer msg
    , setter : Debouncer msg -> model -> model

    --
    , msg : Debouncer.Msg msg -> msg
    , settleAfter : Milliseconds
    }
    ->
        { debouncer : Debouncer msg
        , provideInput : msg -> msg
        , updateConfig : Debouncer.UpdateConfig msg model
        }


makeConfig : Config Model Msg
makeConfig { getter, msg, setter, settleAfter } =
    { debouncer =
        Debouncer.manual
            |> Debouncer.settleWhenQuietFor (Just settleAfter)
            |> Debouncer.toDebouncer

    --
    , provideInput =
        Debouncer.provideInput >> msg

    --
    , updateConfig =
        { mapMsg = msg
        , getDebouncer = getter
        , setDebouncer = setter
        }
    }
