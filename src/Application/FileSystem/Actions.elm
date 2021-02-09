module FileSystem.Actions exposing (..)

import Codec exposing (Codec)
import Drive.Sidebar
import Json.Decode
import Ports
import Radix exposing (..)
import Webnative
import Wnfs



-- App Info


appData : Wnfs.Base
appData =
    Wnfs.AppData appPermissions


appPermissions : Webnative.AppPermissions
appPermissions =
    { creator = "Fission"
    , name = "Drive"
    }


permissions : Webnative.Permissions
permissions =
    { app = Just appPermissions
    , fs =
        Just
            { privatePaths = [ "/" ]
            , publicPaths = [ "/" ]
            }
    }



-- Actions


decodeResponse : Webnative.Response -> Webnative.DecodedResponse Tag
decodeResponse =
    Webnative.decodeResponse tagFromString


writeUtf8 : { path : List String, tag : Tag, content : String } -> Cmd Msg
writeUtf8 { path, tag, content } =
    let
        resolved =
            splitPath path
    in
    Wnfs.writeUtf8 resolved.base
        { path = resolved.path
        , tag = tagToString tag
        }
        content
        |> Ports.webnativeRequest


readUtf8 : { path : List String, tag : Tag } -> Cmd Msg
readUtf8 { path, tag } =
    let
        resolved =
            splitPath path
    in
    Wnfs.readUtf8 resolved.base
        { path = resolved.path
        , tag = tagToString tag
        }
        |> Ports.webnativeRequest



-- Codecs


codecTag : Codec Tag
codecTag =
    Codec.custom
        (\cSidebarTag cCreatedEmptyFile value ->
            case value of
                SidebarTag a ->
                    cSidebarTag a

                CreatedEmptyFile ->
                    cCreatedEmptyFile
        )
        |> Codec.variant1 "SidebarTag"
            SidebarTag
            (Codec.custom
                (\cSavedFile cLoadedFile value ->
                    case value of
                        Drive.Sidebar.SavedFile a ->
                            cSavedFile a

                        Drive.Sidebar.LoadedFile a ->
                            cLoadedFile a
                )
                |> Codec.variant1 "SavedFile"
                    Drive.Sidebar.SavedFile
                    (Codec.object (\path -> { path = path })
                        |> Codec.field "path" .path (Codec.list Codec.string)
                        |> Codec.buildObject
                    )
                |> Codec.variant1 "LoadedFile"
                    Drive.Sidebar.LoadedFile
                    (Codec.object (\path -> { path = path })
                        |> Codec.field "path" .path (Codec.list Codec.string)
                        |> Codec.buildObject
                    )
                |> Codec.buildCustom
            )
        |> Codec.variant0 "CreatedEmptyFile" CreatedEmptyFile
        |> Codec.buildCustom


tagToString : Tag -> String
tagToString tag =
    Codec.encodeToString 0 codecTag tag


tagFromString : String -> Result String Tag
tagFromString string =
    Codec.decodeString codecTag string
        |> Result.mapError Json.Decode.errorToString



-- Utilities


splitPath : List String -> { base : Wnfs.Base, path : List String }
splitPath path =
    case path of
        "public" :: rest ->
            { base = Wnfs.Public, path = rest }

        "private" :: rest ->
            { base = Wnfs.Private, path = rest }

        _ ->
            { base = appData, path = path }
