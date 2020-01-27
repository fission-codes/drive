module Item exposing (..)

import FeatherIcons



-- 🧩


type Kind
    = Directory
      --
    | Audio
    | Image
    | Video



-- 🖼


kindIcon : Kind -> FeatherIcons.Icon
kindIcon kind =
    case kind of
        Directory ->
            FeatherIcons.folder

        Audio ->
            FeatherIcons.music

        Image ->
            FeatherIcons.image

        Video ->
            FeatherIcons.video
