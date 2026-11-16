module Main where

import MP.ExplicitFormula
import MP.Zeta

main :: IO ()
main = do
  putStrLn "mp-analytic report (truncated explicit formula residual)"
  -- Full implementation reports residual against Odlyzko zeros.
