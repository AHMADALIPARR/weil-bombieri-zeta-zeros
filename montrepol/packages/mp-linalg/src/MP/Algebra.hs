module MP.Algebra where

-- Minimal field-like operations for the rank-trace bound.
-- These are pure and total.

type Scalar = Double

add :: Scalar -> Scalar -> Scalar
add = (+)

mul :: Scalar -> Scalar -> Scalar
mul = (*)

-- The rank-trace lower bound on the number of positive eigenvalues.
rankTraceBound :: Scalar -> Scalar -> Scalar
rankTraceBound tr tr2
  | tr2 == 0 = 0
  | otherwise = (tr * tr) / tr2
