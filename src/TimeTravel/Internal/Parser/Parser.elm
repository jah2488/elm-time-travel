module TimeTravel.Internal.Parser.Parser exposing (..) -- where

import String
import Parser exposing (..)
import Char
import Parser.Char exposing (braced, upper)
import Parser.Number exposing (integer, float)

import TimeTravel.Internal.Parser.AST exposing (..)
import TimeTravel.Internal.Parser.Util exposing (..)


parse : String -> Result String AST
parse s = Parser.parse (spaced expression) s


----

expression : Parser AST
expression =
  recursively (\_ ->
  record
  `or` union
  `or` expressionWithoutUnion
  )

expressionWithoutUnion : Parser AST
expressionWithoutUnion =
  recursively (\_ ->
    record `or`
    function `or`
    intLiteral `or`
    floatLiteral `or`
    stringLiteral
  )


stringLiteral : Parser AST
stringLiteral =
  map StringLiteral <|
  (\_ s _ -> s)
  `map` symbol '"'
  `and` stringChars
  `and` symbol '"'


intLiteral : Parser AST
intLiteral =
  map (Value << toString) integer

floatLiteral : Parser AST
floatLiteral =
  map (Value << toString) float


function : Parser AST
function =
  (\_ name _ -> Value name)
  `map` token "<function:"
  `and` someChars (satisfy (\c -> c /= '>'))
  `and` symbol '>'

-- TODO
-- listLiteral


union : Parser AST
union =
  recursively (\_ ->
  (\tag tail -> Union tag tail)
  `map` tag
  `and` many unionParam
  )


unionParam : Parser AST
unionParam =
  recursively (\_ ->
  (\_ exp  -> exp)
  `map` spaces
  `and` expressionWithoutUnion
  )


tag : Parser String
tag =
  (\h t -> String.fromList (h :: t))
  `map` upper
  `and` many (satisfy (\c -> Char.isUpper c || Char.isLower c || Char.isDigit c))


record : Parser AST
record =
  recursively (\_ ->
  map Record <| braced properties
  )

properties : Parser (List AST)
properties =
  recursively (\_ ->
  spaced (separatedBy property comma)
  )

propertyKey : Parser String
propertyKey =
  recursively (\_ ->
  someChars (satisfy (\c -> not (isSpace c) && c /= '='))
  )

property : Parser AST
property =
  recursively (\_ ->
  (\_ key _ _ _ value _ -> Property key value)
  `map` spaces
  `and` propertyKey
  `and` spaces
  `and` equal
  `and` spaces
  `and` expression
  `and` spaces
  )
