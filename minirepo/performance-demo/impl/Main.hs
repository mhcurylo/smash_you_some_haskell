{-# language OverloadedStrings #-}
{-# language ScopedTypeVariables #-}
{-# language TemplateHaskell #-}

module Main (main) where

import qualified Data.Vector.Algorithms.Insertion as Insertion
import qualified Data.Vector.Algorithms.Merge as Merge
import qualified Data.Vector.Unboxed as Vector
import Criterion.Main
import Data.Int


main :: IO ()
main = do
  let vect1 = Vector.fromList $ reverse [-25..(25 :: Int8)]
      vect2 = Vector.fromList $ reverse [-50..(50 :: Int8)]
      vect3 = Vector.fromList $ reverse [-125..(125 :: Int8)]
  defaultMain [
      bench "51 elements - insertion sort (n2)" $ whnf (Vector.modify Insertion.sort) vect1
    , bench "51 elements - merge sort (n log n)" $ whnf (Vector.modify Merge.sort) vect1
    , bench "101 elements - insertion sort (n2)" $ whnf (Vector.modify Insertion.sort) vect2
    , bench "101 elements - merge sort (n log n)" $ whnf (Vector.modify Merge.sort) vect2
    , bench "251 elements - insertion sort (n2)" $ whnf (Vector.modify Insertion.sort) vect3
    , bench "251 elements - merge sort (n log n)" $ whnf (Vector.modify Merge.sort) vect3
    ]

