module List.Ext exposing (..)

{-| Some additional functions for handling lists.
-}


{-| Flipped version of `append`.

    >>> add [2, 3] [1]
    [1, 2, 3]

-}
add : List a -> List a -> List a
add a b =
    List.append b a


{-| Flipped version of (::).

    >>> addTo [2, 3] 1
    [1, 2, 3]

-}
addTo : List a -> a -> List a
addTo list item =
    item :: list
