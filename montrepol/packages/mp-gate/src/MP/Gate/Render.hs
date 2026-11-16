module MP.Gate.Render where

import MP.Gate.Model

-- Render a list of claims as a human-readable report.
renderClaims :: [Claim] -> String
renderClaims cs = unlines [claimFile c ++ ":" ++ show (claimLine c) ++ ": " ++ claimText c | c <- cs]
