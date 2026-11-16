module MP.Matrix where

import MP.Algebra

-- A square matrix stored row-major.
data Matrix = Matrix Int [Scalar]
  deriving (Eq, Show)

trace :: Matrix -> Scalar
trace (Matrix n xs) = sum [ xs !! (i*n + i) | i <- [0..n-1] ]

hsNormSq :: Matrix -> Scalar
hsNormSq (Matrix _ xs) = sum (map (\x -> x*x) xs)

-- rho = (tr R)^2 / (n * ||R||_HS^2)
rho :: Matrix -> Scalar
rho m@(Matrix n _) =
  let t = trace m
      h = hsNormSq m
  in if h == 0 then 0 else (t*t) / (fromIntegral n * h)
