-- | Riemann–von Mangoldt explicit formula, truncated at finitely many zeros.
--
-- For @x > 1@ not a prime power,
--
-- > psi(x) = x - sum_rho x^rho / rho - log(2 pi) - (1/2) log(1 - x^-2)
--
-- with the sum over non-trivial zeros taken symmetrically. Pairing @rho@ with
-- its conjugate, each zero @1/2 + i gamma@ contributes
-- @2 Re(x^rho / rho)@. Truncating the sum is an approximation whose error this
-- module does not bound; @mp-analytic-report@ measures it and the ledger
-- records it as an @open@ quantity, never as a claim.
module MP.ExplicitFormula
  ( psiExplicit
  , zeroContribution
  ) where

import Data.Complex (Complex (..), realPart)

-- | @2 Re(x^rho / rho)@ for @rho = 1/2 + i gamma@.
zeroContribution :: Double -> Double -> Double
zeroContribution x gamma =
  let rho = 0.5 :+ gamma
   in 2 * realPart (exp (rho * (log x :+ 0)) / rho)

-- | The right-hand side with the given zeros (their positive imaginary parts).
psiExplicit :: [Double] -> Double -> Double
psiExplicit gammas x =
  x - sum (map (zeroContribution x) gammas) - log (2 * pi) - 0.5 * log (1 - 1 / (x * x))
