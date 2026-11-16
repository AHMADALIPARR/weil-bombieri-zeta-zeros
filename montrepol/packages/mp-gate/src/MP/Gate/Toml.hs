-- | The subset of TOML the model files use, parsed by hand.
--
-- Supported: comments, blank lines, top-level @key = value@, @[[name]]@
-- arrays of tables, and values that are basic strings, integers, booleans or
-- single-line arrays of strings. Anything else is a parse error with its line
-- number, rather than a silent misreading: a model the gate cannot read is a
-- model it cannot check.
module MP.Gate.Toml
  ( Value (..)
  , Table
  , Doc (..)
  , parseToml
  , lookupString
  , lookupStrings
  ) where

import Data.Char (isAlphaNum, isDigit, isSpace)

data Value = VString String | VInt Integer | VBool Bool | VStrings [String]
  deriving (Eq, Show)

type Table = [(String, Value)]

data Doc = Doc
  { docTop :: Table
  , docArrays :: [(String, [Table])]
  }
  deriving (Eq, Show)

lookupString :: String -> Table -> Maybe String
lookupString k t = case lookup k t of
  Just (VString s) -> Just s
  _ -> Nothing

lookupStrings :: String -> Table -> [String]
lookupStrings k t = case lookup k t of
  Just (VStrings ss) -> ss
  Just (VString s) -> [s]
  _ -> []

parseToml :: String -> Either String Doc
parseToml src = finish <$> foldl step (Right (Doc [] [], Nothing)) (zip [1 :: Int ..] (lines src))
  where
    finish (Doc top arrs, current) = Doc top (close current arrs)
    close Nothing arrs = arrs
    close (Just (name, t)) arrs = appendTable name (reverse t) arrs
    step (Left e) _ = Left e
    step (Right (doc, current)) (n, raw) =
      let line = trim (stripComment raw)
       in case line of
            "" -> Right (doc, current)
            ('[' : '[' : rest)
              | Just name <- stripSuffix "]]" rest, validKey (trim name) ->
                  Right (doc {docArrays = close current (docArrays doc)}, Just (trim name, []))
            _ -> case break (== '=') line of
              (k, '=' : v)
                | validKey (trim k) -> case parseValue (trim v) of
                    Right val -> Right (insert (trim k) val doc current)
                    Left e -> Left ("line " <> show n <> ": " <> e)
              _ -> Left ("line " <> show n <> ": cannot read " <> show raw)
    insert k v doc Nothing = (doc {docTop = docTop doc ++ [(k, v)]}, Nothing)
    insert k v doc (Just (name, t)) = (doc, Just (name, (k, v) : t))

appendTable :: String -> Table -> [(String, [Table])] -> [(String, [Table])]
appendTable name t arrs = case break ((== name) . fst) arrs of
  (before, (_, ts) : after) -> before ++ (name, ts ++ [t]) : after
  (_, []) -> arrs ++ [(name, [t])]

validKey :: String -> Bool
validKey k = not (null k) && all (\c -> isAlphaNum c || c == '-' || c == '_') k

trim :: String -> String
trim = dropWhileEnd' isSpace . dropWhile isSpace
  where
    dropWhileEnd' p = reverse . dropWhile p . reverse

stripSuffix :: String -> String -> Maybe String
stripSuffix suf s =
  let n = length s - length suf
   in if n >= 0 && drop n s == suf then Just (take n s) else Nothing

-- | Remove a @#@ comment that is not inside a string.
stripComment :: String -> String
stripComment = go False
  where
    go _ [] = []
    go inStr ('\\' : c : rest) | inStr = '\\' : c : go inStr rest
    go inStr ('"' : rest) = '"' : go (not inStr) rest
    go False ('#' : _) = []
    go inStr (c : rest) = c : go inStr rest

parseValue :: String -> Either String Value
parseValue v = case v of
  "true" -> Right (VBool True)
  "false" -> Right (VBool False)
  ('"' : _) -> case parseString v of
    Right (s, "") -> Right (VString s)
    Right (_, junk) -> Left ("unexpected " <> show junk <> " after a string")
    Left e -> Left e
  ('[' : rest) -> VStrings <$> parseArray (trim rest)
  ('-' : ds) | isInt ds -> Right (VInt (negate (digits ds)))
  ds | isInt ds -> Right (VInt (digits ds))
  _ -> Left ("unsupported value " <> show v)
  where
    isInt ds = not (null ds) && all isDigit ds
    digits = foldl (\acc c -> acc * 10 + toInteger (fromEnum c - fromEnum '0')) 0

parseString :: String -> Either String (String, String)
parseString ('"' : rest) = go [] rest
  where
    go acc ('\\' : c : more) = case c of
      'n' -> go ('\n' : acc) more
      't' -> go ('\t' : acc) more
      '"' -> go ('"' : acc) more
      '\\' -> go ('\\' : acc) more
      _ -> Left ("unsupported escape \\" <> [c])
    go acc ('"' : more) = Right (reverse acc, trim more)
    go acc (c : more) = go (c : acc) more
    go _ [] = Left "unterminated string"
parseString s = Left ("expected a string at " <> show s)

-- | The remainder of @[ "a", "b" ]@ after the opening bracket.
parseArray :: String -> Either String [String]
parseArray (']' : rest) | null (trim rest) = Right []
parseArray s = do
  (x, more) <- parseString s
  case more of
    (',' : more') -> (x :) <$> parseArray (trim more')
    (']' : rest) | null (trim rest) -> Right [x]
    _ -> Left ("expected , or ] in an array, got " <> show more)
