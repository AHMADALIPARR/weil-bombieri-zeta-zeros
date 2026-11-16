module Main where

import MP.ExplicitFormula
import Test.Tasty
import Test.Tasty.HUnit

main :: IO ()
main = defaultMain tests

tests :: TestTree
tests = testGroup "Explicit formula"
  [ testCase "psi at 2 with no zeros" $ psiExplicit [] 2.0 @?= 2.0 - log (2 * pi) - 0.5 * log (1 - 1/4)
  ]
