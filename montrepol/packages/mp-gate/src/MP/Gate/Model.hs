module MP.Gate.Model where

-- The model of what counts as a numeric claim.
-- A string literal is a claim if it matches a floating-point pattern
-- and is not on the allow-list.

data Claim = Claim
  { claimFile :: FilePath
  , claimLine :: Int
  , claimText :: String
  } deriving (Eq, Show)
