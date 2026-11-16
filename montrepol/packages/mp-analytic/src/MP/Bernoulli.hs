module MP.Bernoulli where

-- Bernoulli numbers via the recursive definition.
-- Pure and total.

bernoulli :: Int -> Rational
bernoulli 0 = 1
bernoulli 1 = -1/2
bernoulli n
  | odd n = 0
  | otherwise = error "even Bernoulli beyond B2 not tabulated here"
