-- | Just enough Haskell lexing to audit sources: strip comments and literals,
-- split identifiers and operators, and find the conformance IDs that tests
-- are tagged with.
--
-- Every forbidden name below is assembled from halves. A gate that reads
-- source must survive reading its own, and exempting this file would put a
-- hole exactly where a defect parked in the gate would hide.
module MP.Gate.Scan
  ( codeOnly
  , identifiers
  , operators
  , deferralMarkers
  , stubNames
  , partialNames
  , partialOperators
  , testTags
  , isConformanceId
  ) where

import Data.Char (isAlphaNum, isDigit, isUpper)
import Data.List (isPrefixOf)

-- | Comment and work-in-progress markers that mean "not finished".
deferralMarkers :: [String]
deferralMarkers = ["TO" <> "DO", "FIX" <> "ME", "XX" <> "X"]

-- | A placeholder standing in for code.
stubNames :: [String]
stubNames = ["unde" <> "fined"]

-- | Functions that are partial, or that defeat the type system.
partialNames :: [String]
partialNames =
  [ "err" <> "or"
  , "errorWithout" <> "StackTrace"
  , "he" <> "ad"
  , "ta" <> "il"
  , "in" <> "it"
  , "la" <> "st"
  , "from" <> "Just"
  , "re" <> "ad"
  , "maxi" <> "mum"
  , "mini" <> "mum"
  , "foldr" <> "1"
  , "foldl" <> "1"
  , "unsafePerform" <> "IO"
  , "unsafe" <> "Coerce"
  , "unsafeInterleave" <> "IO"
  ]

partialOperators :: [String]
partialOperators = ["!" <> "!"]

isIdChar :: Char -> Bool
isIdChar c = isAlphaNum c || c == '_' || c == '\''

isSymbolChar :: Char -> Bool
isSymbolChar c = c `elem` ("!#$%&*+./<=>?@\\^|-~:" :: String)

-- | The source with comments, string literals and character literals
-- replaced by spaces, so line structure survives.
codeOnly :: String -> String
codeOnly = go ' '
  where
    go _ [] = []
    go prev s@(c : rest)
      | "{-" `isPrefixOf` s = blockComment (1 :: Int) (drop 2 s)
      | "--" `isPrefixOf` s && not (isSymbolChar prev) && lineCommentStart s =
          let (_, after) = break (== '\n') s in go '\n' after
      | c == '"' = stringLit rest
      | c == '\'' && not (isIdChar prev) = charLit s
      | otherwise = c : go c rest
    lineCommentStart s = case dropWhile (== '-') s of
      (d : _) -> not (isSymbolChar d)
      [] -> True
    blockComment _ [] = []
    blockComment depth s@(c : rest)
      | "-}" `isPrefixOf` s = if depth == 1 then ' ' : go ' ' (drop 2 s) else blockComment (depth - 1) (drop 2 s)
      | "{-" `isPrefixOf` s = blockComment (depth + 1) (drop 2 s)
      | c == '\n' = '\n' : blockComment depth rest
      | otherwise = blockComment depth rest
    stringLit ('\\' : _ : rest) = stringLit rest
    stringLit ('"' : rest) = ' ' : go ' ' rest
    stringLit ('\n' : rest) = '\n' : go '\n' rest
    stringLit (_ : rest) = stringLit rest
    stringLit [] = []
    -- 'x' or '\n' or '\''; anything else (a promoted constructor) is code.
    charLit s = case s of
      ('\'' : '\\' : _ : '\'' : rest) -> ' ' : go ' ' rest
      ('\'' : _ : '\'' : rest) -> ' ' : go ' ' rest
      ('\'' : rest) -> '\'' : go '\'' rest
      [] -> []
      (c : rest) -> c : go c rest

-- | Maximal identifier tokens, with qualifiers split off (@Set.member@ gives
-- @Set@ and @member@).
identifiers :: String -> [String]
identifiers s = case dropWhile (not . isIdStart) s of
  [] -> []
  s' -> let (tok, rest) = span isIdChar s' in tok : identifiers rest
  where
    isIdStart c = isAlphaNum c || c == '_'

-- | Maximal operator tokens.
operators :: String -> [String]
operators s = case dropWhile (not . isSymbolChar) s of
  [] -> []
  s' -> let (tok, rest) = span isSymbolChar s' in tok : operators rest

-- | @XX-00@: two capitals, a hyphen, two digits.
isConformanceId :: String -> Bool
isConformanceId i = case i of
  [a, b, '-', c, d] -> isUpper a && isUpper b && isDigit c && isDigit d
  _ -> False

-- | The IDs in @unit "XX-00"@, @unitIO@, @prop@ and @propN@ calls.
testTags :: String -> [String]
testTags = go ' '
  where
    heads = ["unit ", "unitIO ", "prop ", "propN "]
    go _ [] = []
    go prev s@(c : rest)
      | not (isIdChar prev), Just after <- firstPrefix s = case after of
          ('"' : more) -> takeWhile (/= '"') more : go '"' (drop 1 (dropWhile (/= '"') more))
          _ -> go c rest
      | otherwise = go c rest
    firstPrefix s = case [drop (length h) s | h <- heads, h `isPrefixOf` s] of
      (a : _) -> Just a
      [] -> Nothing
