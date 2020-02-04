module Drive.Types exposing (..)

-- 📣


type Msg
    = DigDeeper { directoryName : String }
    | GoUp { floor : Int }
    | Select { cid : String }
