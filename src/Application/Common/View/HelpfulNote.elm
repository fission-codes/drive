module Common.View.HelpfulNote exposing (view)

import Html exposing (Html)
import Html.Events as E
import Html.Extra as Html
import Styling as S
import Tailwind as T
import Types exposing (Msg(..))



-- 🖼


view : { faded : Bool, note : String } -> Html Msg
view note =
    Html.div
        [ E.onClick HideHelpfulNote

        --
        , T.antialiased
        , T.bg_purple
        , T.bottom_0
        , T.cursor_pointer
        , S.default_transition_duration
        , S.default_transition_easing
        , T.fixed
        , T.font_bold
        , T.left_1over2
        , T.mb_20
        , T.neg_translate_x_1over2
        , T.px_5
        , T.py_4
        , T.rounded_lg
        , T.text_purple_tint
        , T.tracking_tight
        , T.transform
        , T.transition_opacity
        , T.z_50

        --
        , if note.faded then
            T.opacity_0

          else
            T.opacity_90

        --
        , if note.faded then
            T.pointer_events_none

          else
            T.pointer_events_auto
        ]
        [ Html.text note.note ]
