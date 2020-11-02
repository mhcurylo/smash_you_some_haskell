{-# language OverloadedStrings #-}
{-# language ScopedTypeVariables #-}
{-# language TemplateHaskell #-}

module Main (main) where

import qualified Data.Vector.Algorithms.Insertion as Insertion
import qualified Data.Vector.Unboxed as Vector
import qualified Data.Vector.Unboxed.Mutable as MVector
import Control.Monad
import Data.Int

vect :: Vector.Vector Int64
vect = Vector.fromList $ reverse [-50..0]

main :: IO ()
main = do
  forM_ [0..(10000 :: Int)] $ \_ -> copisort vect

copisort :: Vector.Vector Int64 -> IO (MVector.IOVector Int64)
copisort = Vector.unsafeThaw . Vector.modify Insertion.sort


