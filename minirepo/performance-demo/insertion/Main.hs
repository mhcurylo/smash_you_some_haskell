{-# language OverloadedStrings #-}
{-# language ScopedTypeVariables #-}
{-# language TemplateHaskell #-}

module Main (main) where

import qualified Data.Vector.Algorithms.Insertion as Insertion
import qualified Data.Vector.Unboxed as Vector
import qualified Data.Vector.Unboxed.Mutable as MVector
import Control.Monad
import Data.Int

vect :: Vector.Vector Int8
vect = Vector.fromList $ reverse [-50..(50 :: Int8)]

main :: IO ()
main = do
  forM_ [0..(10000 :: Int)] $ \_ -> copisort vect

copisort :: Vector.Vector Int8 -> IO (MVector.IOVector Int8)
copisort = Vector.unsafeThaw . Vector.modify Insertion.sort


