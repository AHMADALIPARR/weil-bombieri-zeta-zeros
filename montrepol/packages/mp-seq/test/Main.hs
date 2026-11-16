module Main (main) where

import MP.Algebra
import MP.Check
import MP.Recurrence

main :: IO ()
main =
  runSuite
    "mp-seq"
    [ prop "SQ-01" "BM's polynomial regenerates the sequence over GF(2)" (listUpTo 40 gf2) regenerates
    , prop "SQ-01" "BM's polynomial regenerates the sequence over Q" (listUpTo 14 (rationalIn (-5) 5 3)) regenerates
    , propN "SQ-02" "BM is minimal: no shorter LFSR generates the sequence (GF(2), brute force)" 300 (listUpTo 11 gf2) minimal
    , propN "SQ-03" "a length-l LFSR is recovered from 2l terms and predicts the rest (Massey)" 300 genLFSR recovered
    , unit "SQ-04" "x^5 + x^2 + 1 is primitive: period 31, linear complexity 5" $
        let c = map GF2 [True, False, True, False, False, True] -- 1 + x^2 + x^5
            s = runLFSR c (map GF2 [True, False, False, False, False]) 62
         in period c (take 5 s) 100 === Just 31 .&&. fst (berlekampMassey s) === 5
    , unit "SQ-04" "x^4 + x^2 + 1 = (x^2 + x + 1)^2 is not primitive: period 6, not 15" $
        let c = map GF2 [True, False, True, False, True]
         in period c (map GF2 [True, False, False, False]) 100 === Just 6
    , unit "SQ-05" "Fibonacci over Q has connection polynomial 1 - x - x^2" $
        berlekampMassey (take 20 fibs) === (2, [1, -1, -1])
    , unit "SQ-05" "the zero sequence has linear complexity 0" $
        berlekampMassey (replicate 10 (0 :: Rational)) === (0, [1])
    ]
  where
    fibs = 0 : 1 : zipWith (+) fibs (drop 1 fibs) :: [Rational]

gf2 :: Gen GF2
gf2 = GF2 <$> boolG

regenerates :: (Field a, Show a) => [a] -> Result
regenerates s =
  let (l, c) = berlekampMassey s
   in assert ("C = " <> show c <> " does not generate it") (generates c s)
        .&&. length c === l + 1
        .&&. assert "L > length" (l <= length s)

-- Every connection polynomial over GF(2) of degree at most l.
allPolys :: Int -> [Poly GF2]
allPolys l = map (one :) (mapM (const [GF2 False, GF2 True]) [1 .. l])

minimal :: [GF2] -> Result
minimal s =
  let (l, _) = berlekampMassey s
      shorter = [c | k <- [0 .. l - 1], c <- allPolys k, generates c s]
   in assert ("a length " <> show (map (subtract 1 . length) shorter) <> " LFSR exists") (null shorter)

genLFSR :: Gen ([GF2], [GF2])
genLFSR = do
  l <- intIn 1 8
  taps <- listOfLength l gf2
  initial <- listOfLength l gf2
  pure (one : taps, initial)

recovered :: ([GF2], [GF2]) -> Result
recovered (c, initial) =
  let l = length initial
      long = runLFSR c initial (6 * l)
      (l', c') = berlekampMassey (take (2 * l) long)
   in assert ("complexity " <> show l' <> " exceeds " <> show l) (l' <= l)
        .&&. assert ("recovered " <> show c' <> " fails beyond 2l") (generates c' long)
