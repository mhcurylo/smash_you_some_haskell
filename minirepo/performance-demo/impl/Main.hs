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
  let vect1 = Vector.fromList $ reverse [-49..(50 :: Int8)]
      vect2 = Vector.fromList $ reverse [-49..(50 :: Int64)]
  defaultMain [
      bench "100 elements Int8  - insertion sort (n2)" $ whnf (Vector.modify Insertion.sort) vect1
    , bench "100 elements Int8  - merge sort (n log n)" $ whnf (Vector.modify Merge.sort) vect1
    , bench "100 elements Int64 - insertion sort (n2)" $ whnf (Vector.modify Insertion.sort) vect2
    , bench "100 elements Int64 - merge sort (n log n)" $ whnf (Vector.modify Merge.sort) vect2
    ]

