-- | Linear recurrences over a field.
--
-- A connection polynomial @C(x) = 1 + c_1 x + ... + c_L x^L@ generates @s@
-- when @s_n + c_1 s_(n-1) + ... + c_L s_(n-L) = 0@ for every @n >= L@. The
-- linear complexity of a finite sequence is the least @L@ for which some such
-- @C@ exists. Berlekamp–Massey computes it, and a minimal @C@, in @O(N^2)@
-- field operations.
--
-- The algorithm is written once, over any 'Field'. The prism-ciris kernel only
-- verified that a given recurrence held; this finds the recurrence.
module MP.Recurrence
  ( Poly
  , berlekampMassey
  , generates
  , runLFSR
  , period
  ) where

import MP.Algebra

-- | Coefficients, constant term first.
type Poly a = [a]

-- | Linear complexity and a minimal connection polynomial of exactly
-- @L + 1@ coefficients.
berlekampMassey :: Field a => [a] -> (Int, Poly a)
berlekampMassey s = finish (go 0 [one] [one] 0 1 one)
  where
    n = length s
    finish (l, c) = (l, take (l + 1) (c ++ repeat zero))
    go k c b l m bInv0
      | k >= n = (l, c)
      | otherwise =
          let d = discrepancy k c l
           in if isZero d
                then go (k + 1) c b l (m + 1) bInv0
                else
                  let coef = d .*. bInv0
                      c' = polySub c (shiftScale m coef b)
                   in if 2 * l <= k
                        then go (k + 1) c' c (k + 1 - l) 1 (maybe zero id (recipF d))
                        else go (k + 1) c' b l (m + 1) bInv0
    -- d = s_k + sum_{i=1..L} c_i s_(k-i)
    discrepancy k c l =
      sumS [ci .*. sk | (i, ci) <- zip [0 ..] (take (l + 1) c), Just sk <- [ix (k - i)]]
    ix i = if i < 0 then Nothing else case drop i s of
      (v : _) -> Just v
      [] -> Nothing

-- | @x^m * coef * b(x)@.
shiftScale :: Semiring a => Int -> a -> Poly a -> Poly a
shiftScale m coef b = replicate m zero ++ map (coef .*.) b

polySub :: Ring a => Poly a -> Poly a -> Poly a
polySub (x : xs) (y : ys) = (x .-. y) : polySub xs ys
polySub xs [] = xs
polySub [] ys = map neg ys

-- | Whether @c@ generates every term of @s@ from its predecessors.
generates :: Ring a => Poly a -> [a] -> Bool
generates c s = all holds [l .. length s - 1]
  where
    l = length c - 1
    window k = reverse (take (l + 1) (drop (k - l) s)) -- s_k, s_(k-1), .., s_(k-L)
    holds k = isZero (sumS (zipWith (.*.) c (window k)))

-- | Extend @l@ initial terms by the recurrence, for @count@ terms in total.
runLFSR :: Ring a => Poly a -> [a] -> Int -> [a]
runLFSR c initial count = take count (initial ++ continue (reverse initial))
  where
    taps = drop 1 c -- c_1 .. c_L
    -- @recent@ is s_(n-1), s_(n-2), ..; zipWith stops at the last tap.
    continue recent =
      let v = neg (sumS (zipWith (.*.) taps recent))
       in v : continue (v : recent)

-- | The least @p >= 1@ with the state after @p@ steps equal to the initial
-- state, searching up to @bound@ steps. Over GF(2) a primitive connection
-- polynomial of degree @L@ gives the maximal period @2^L - 1@.
period :: (Ring a, Eq a) => Poly a -> [a] -> Int -> Maybe Int
period c initial bound =
  let l = length initial
      s = runLFSR c initial (bound + l)
      stateAt k = take l (drop k s)
   in case [p | p <- [1 .. bound], stateAt p == initial] of
        (p : _) -> Just p
        [] -> Nothing
