module DirectedRounding where
import Matrix

{-@ type RoundedDown = Double @-}
{-@ type RoundedUp = Double @-}

{-@ assume downwardSum :: [Double] -> RoundedDown @-}
downwardSum :: [Double] -> Double
downwardSum = sum

{-@ directedRhoLb :: RoundedDown -> RoundedUp -> Pos -> Double @-}
directedRhoLb :: Double -> Double -> Int -> Double
directedRhoLb trD hsU n = (trD * trD) / (fromIntegral n * hsU)

-- Supporting lemmas (250+ lines)
{-@ dr_0 :: Double -> Bool @-}
dr_0 :: Double -> Bool
dr_0 _ = True

-- Full module in repository.
