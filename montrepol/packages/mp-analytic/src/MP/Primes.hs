module MP.Primes where

-- Simple sieve for primes up to a bound. Pure and total.
primesUpTo :: Int -> [Int]
primesUpTo n = sieve [2..n]
  where
    sieve [] = []
    sieve (p:xs) = p : sieve [x | x <- xs, x `mod` p /= 0]
