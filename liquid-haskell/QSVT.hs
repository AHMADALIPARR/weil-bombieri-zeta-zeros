module QSVT where

{-@ type Degree = {v:Int | v >= 0} @-}
{-@ type Gap = {v:Double | v > 0} @-}
{-@ type Alpha = {v:Double | v > 0} @-}

{-@ qsvtDegree :: Alpha -> Gap -> Double -> Degree @-}
qsvtDegree :: Double -> Double -> Double -> Int
qsvtDegree alpha gap eps = ceiling (alpha / gap * (-log eps))

{-@ policyCheck :: Alpha -> Gap -> Bool @-}
policyCheck :: Double -> Double -> Bool
policyCheck alpha gap = alpha <= 3.0 && gap >= 0.05

--
{-@ ql_0 :: Double -> Double -> Bool @-}
ql_0 :: Double -> Double -> Bool
ql_0 _ _ = True

