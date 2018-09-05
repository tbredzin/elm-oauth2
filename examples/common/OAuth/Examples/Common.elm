module OAuth.Examples.Common exposing (Model, Profile, authorizationEndpoint, clientId, clientSecret, errorResponseToString, makeInitModel, profileDecoder, profileEndpoint, tokenEndpoint, view, viewBody, viewFetching, viewProfile, viewSignInButton)

import Browser exposing (Document, application)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json
import OAuth
import Url exposing (Protocol(..), Url)



-- Model


type alias Model =
    { redirectUri : Url
    , state : String
    , error : Maybe String
    , token : Maybe OAuth.Token
    , profile : Maybe Profile
    }


type alias Profile =
    { email : String
    , name : String
    , picture : String
    }


makeInitModel : Url -> Model
makeInitModel origin =
    { redirectUri = { origin | query = Nothing, fragment = Nothing }
    , state = "CSRF" -- NOTE In theory, this state is securely generated before each request and stored somewhere.
    , error = Nothing
    , token = Nothing
    , profile = Nothing
    }


profileDecoder : Json.Decoder Profile
profileDecoder =
    Json.map3 Profile
        (Json.field "email" Json.string)
        (Json.field "name" Json.string)
        (Json.field "picture" Json.string)



--
-- View
--


view : String -> { onSignIn : msg } -> Model -> Document msg
view title { onSignIn } model =
    let
        content =
            case ( model.token, model.profile ) of
                ( Nothing, Nothing ) ->
                    viewSignInButton onSignIn

                ( Just token, Nothing ) ->
                    viewFetching

                ( _, Just profile ) ->
                    viewProfile profile
    in
    { title = title
    , body = [ viewBody model content ]
    }


viewBody : Model -> Html msg -> Html msg
viewBody model content =
    div
        [ style "display" "flex"
        , style "flex-direction" "column"
        , style "align-items" "center"
        , style "justify-content" "center"
        , style "height" "95vh"
        , style "overflow" "hidden"
        ]
        [ case model.error of
            Nothing ->
                div [ style "display" "none" ] []

            Just msg ->
                div
                    [ style "display" "block"
                    , style "width" "100%"
                    , style "position" "absolute"
                    , style "top" "0"
                    , style "padding" "1em"
                    , style "font-family" "Roboto Arial sans-serif"
                    , style "text-align" "center"
                    , style "background" "#e74c3c"
                    , style "color" "#ffffff"
                    ]
                    [ text msg ]
        , content
        ]


viewSignInButton : msg -> Html msg
viewSignInButton msg =
    button
        [ style "background" "0 center no-repeat url('data:image/png;base64,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')"
        , style "background-size" "100px"
        , style "border" "none"
        , style "box-shadow" "rgba(0,0,0,0.25) 0px 2px 4px 0px"
        , style "color" "#757575"
        , style "font" "24px Roboto, Arial"
        , style "outline" "none"
        , style "cursor" "pointer"
        , style "height" "100px"
        , style "width" "200px"
        , style "text-align" "right"
        , style "padding" "0 0.5em"
        , onClick msg
        ]
        [ text "Sign in" ]


viewFetching : Html msg
viewFetching =
    div
        [ style "color" "#757575"
        , style "font" "Roboto Arial"
        , style "text-align" "center"
        ]
        [ text "fetching profile..." ]


viewProfile : Profile -> Html msg
viewProfile profile =
    div
        [ style "display" "flex"
        , style "flex-direction" "column"
        , style "align-items" "center"
        ]
        [ img
            [ src profile.picture
            , style "height" "25vh"
            , style "width" "25vh"
            , style "border-radius" "50%"
            , style "box-shadow" "rgba(0,0,0,0.25) 0 0 4px 2px"
            ]
            []
        , div
            [ style "margin" "2em"
            , style "font" "24px Roboto, Arial"
            , style "color" "#757575"
            ]
            [ text <| profile.name ]
        ]



--
-- Helpers
--


{-| Gets a `String` representation of an `ErrorResponse`
-}
errorResponseToString : { error : OAuth.ErrorCode, errorDescription : Maybe String } -> String
errorResponseToString { error, errorDescription } =
    let
        code =
            OAuth.errorCodeToString error

        desc =
            Maybe.withDefault "" (Maybe.map (\s -> "(" ++ s ++ ")") errorDescription)
    in
    code ++ " " ++ desc



--
-- Constants
--


{-| Demo clientId, configured to target the github repository's gh-pages / localhost only
-}
clientId : String
clientId =
    "909608474358-apio86lq9hvjobd3hiepgtrclthnc4q0.apps.googleusercontent.com"


{-| Demo clientSecret, configured to target the github repository's gh-pages / localhost only
-}
clientSecret : String
clientSecret =
    "Z0byMAzeGnGBzaYzK63usOn2"


authorizationEndpoint : Url
authorizationEndpoint =
    { protocol = Https
    , host = "accounts.google.com"
    , path = "/o/oauth2/v2/auth"
    , port_ = Nothing
    , query = Nothing
    , fragment = Nothing
    }


profileEndpoint : Url
profileEndpoint =
    { protocol = Https
    , host = "www.googleapis.com"
    , path = "/oauth2/v1/userinfo"
    , port_ = Nothing
    , query = Nothing
    , fragment = Nothing
    }


tokenEndpoint : Url
tokenEndpoint =
    { protocol = Https
    , host = "www.googleapis.com"
    , path = "/oauth2/v4/token"
    , port_ = Nothing
    , query = Nothing
    , fragment = Nothing
    }
