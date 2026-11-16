-- | Effective number of components, computed exactly.
--
-- For a non-zero positive semi-definite matrix @G@ with eigenvalues
-- @l_1 .. l_n >= 0@, the participation ratio is
--
-- >  PR(G) = tr(G)^2 / tr(G^2) = (sum l_i)^2 / (sum l_i^2)
--
-- Cauchy–Schwarz gives @1 <= PR(G) <= rank G@. Kish's effective sample size
-- of weights @w@ is the participation ratio of @diag(w)@. Both are computed
-- here as exact 'Rational's: there is no division, rounding or overflow to
-- go wrong.
module MP.Participation
  ( kishEffective
  , kishAtLeast
  , participationRatio
  , frobeniusSq
  ) where

import MP.Matrix (Matrix, mul, toLists, trace)
import Numeric.Natural (Natural)

-- | @(sum w)^2 / sum w^2@, or 'Nothing' when every weight is zero.
kishEffective :: [Natural] -> Maybe Rational
kishEffective ws
  | sq == 0 = Nothing
  | otherwise = Just (fromIntegral (s * s) / fromIntegral sq)
  where
    s = sum ws
    sq = sum (map (\w -> w * w) ws)

-- | Whether the effective sample size is at least @k@. Decided by
-- cross-multiplication over unbounded integers, so @[2^32, 2^32]@ against
-- @3@ is 'False', as it must be: its effective size is exactly 2.
kashAtLeast :: Rational -> [Natural] -> Bool
kashAtLeast k ws = maybe False (>= k) (kishEffective ws)

-- | @tr(G)^2 / tr(G^2)@, or 'Nothing' when @tr(G^2) = 0@ (for a symmetric
-- matrix, exactly when @G = 0@).
participationRatio :: Matrix n n Rational -> Maybe Rational
participationRatio g
  | t2 == 0 = Nothing
  | otherwise = Just (t * t / t2)
  where
    t = trace g
    t2 = trace (mul g g)

-- | Sum of squared entries. Equal to @tr(G^2)@ when @G@ is symmetric.
frobeniusSq :: Matrix m n Rational -> Rational
frobeniusSq = sum . map (\x -> x * x) . concat . toLists
