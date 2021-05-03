module FileSystem.Actions exposing (..)

import Codec exposing (Codec)
import Drive.Sidebar
import Json.Decode
import Ports
import Radix exposing (..)
import Webnative
import Webnative.Path as Path exposing (Path)
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
            { private = [ Path.encapsulate Path.root ]
            , public = [ Path.encapsulate Path.root ]
            }
    }



-- Actions


createDirectory : { path : List String, tag : Tag } -> Cmd Msg
createDirectory { path, tag } =
    let
        resolved =
            splitPath path
    in
    Wnfs.mkdir resolved.base
        { path = Path.directory resolved.path
        , tag = tagToString tag
        }
        |> Ports.webnativeRequest


publish : { tag : Tag } -> Cmd Msg
publish { tag } =
    Wnfs.publish
        { tag = tagToString tag }
        |> Ports.webnativeRequest


writeUtf8 : { path : List String, tag : Tag, content : String } -> Cmd Msg
writeUtf8 { path, tag, content } =
    let
        resolved =
            splitPath path
    in
    Wnfs.writeUtf8 resolved.base
        { path = Path.file resolved.path
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
        { path = Path.file resolved.path
        , tag = tagToString tag
        }
        |> Ports.webnativeRequest



-- Codecs


codecTag : Codec Tag
codecTag =
    Codec.custom
        (\cSidebarTag cCreatedEmptyFile cCreatedDirectory cUpdatedFileSystem value ->
            case value of
                SidebarTag a ->
                    cSidebarTag a

                CreatedEmptyFile a ->
                    cCreatedEmptyFile a

                CreatedDirectory ->
                    cCreatedDirectory

                UpdatedFileSystem ->
                    cUpdatedFileSystem
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
                |> Codec.variant1 "SavedFile" Drive.Sidebar.SavedFile (codecPathRecord Codec.string)
                |> Codec.variant1 "LoadedFile" Drive.Sidebar.LoadedFile (codecPathRecord Codec.string)
                |> Codec.buildCustom
            )
        |> Codec.variant1 "CreatedEmptyFile" CreatedEmptyFile (codecPathRecord (Codec.list Codec.string))
        |> Codec.variant0 "CreatedDirectory" CreatedDirectory
        |> Codec.variant0 "UpdatedFileSystem" UpdatedFileSystem
        |> Codec.buildCustom


codecPathRecord : Codec a -> Codec { path : a }
codecPathRecord codecPath =
    Codec.object (\path -> { path = path })
        |> Codec.field "path" .path codecPath
        |> Codec.buildObject


decodeResponse : Webnative.Response -> Webnative.DecodedResponse Tag
decodeResponse =
    Webnative.decodeResponse tagFromString


tagToString : Tag -> String
tagToString tag =
    Codec.encodeToString 0 codecTag tag


tagFromString : String -> Result String Tag
tagFromString string =
    string
        |> Codec.decodeString codecTag
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
            { base = Wnfs.Private, path = path }
