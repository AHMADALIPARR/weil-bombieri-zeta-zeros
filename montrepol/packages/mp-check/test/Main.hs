-- The harness tests itself. A property runner that cannot fail is the most
-- dangerous kind of vacuous gate, so CK-02 plants a false property and
-- requires the runner to catch it.
module Main (main) where

import Data.List (nub, sort)
import MP.Check
import MP.Check.Random

main :: IO ()
main =
  runSuite
    "mp-check"
    [ prop "CK-01" "integerIn stays inside its closed interval" range $ \(lo, w, x) ->
        assert "below lower bound" (x >= lo) .&&. assert "above upper bound" (x <= lo + w)
    , unit "CK-02" "the runner reports a property that fails on one value in ten" $
        assert "runner accepted x /= 7 over [0, 9]" (checkProperty 200 (integerIn 0 9) (\x -> assert "is 7" (x /= 7)) 1 /= Nothing)
    , unit "CK-02" "the runner accepts a true property" $
        checkProperty 200 (integerIn 0 9) (\x -> assert "out of range" (x >= 0 && x <= 9)) 1 === Nothing
    , unit "CK-03" "integerIn reaches every value of a small range" $
        sort (nub (fst (runGen (listOfLength 400 (integerIn 0 9)) (mkSeed 1)))) === [0 .. 9]
    , unit "CK-04" "SplitMix64 matches the reference stream for seed 0" $
        -- First outputs of the reference SplittableRandom/SplitMix64 for seed 0.
        take 3 (stream (mkSeed 0))
          === [0xe220a8397b1dcdaf, 0x6e789e6aa1b965f4, 0x06c45d188009454f]
    ]
  where
    range = do
      lo <- integerIn (-1000) 1000
      w <- integerIn 0 50
      x <- integerIn lo (lo + w)
      pure (lo, w, x)
    stream s = let (w, s') = nextWord64 s in w : stream s'
