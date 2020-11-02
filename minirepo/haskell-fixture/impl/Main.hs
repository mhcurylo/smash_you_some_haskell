module Main where

import Data.Aeson
import Data.Text (Text)
import qualified Data.Text as Text
import Data.Pool
import Data.ByteString (ByteString)
import Data.ByteString.Char8 (pack)
import Control.Concurrent
import Control.Exception (bracket)
import Database.PostgreSQL.Simple
import GHC.Generics
import Network.Wai
import Network.Wai.Handler.Warp
import Servant
import System.IO
import System.Environment.Blank
import Control.Monad.IO.Class
import Data.Maybe (fromMaybe)

type ItemApi =
  "item" :> Get '[JSON] [Item] :<|>
  "item" :> Capture "itemId" Int :> Get '[JSON] Item :<|>
  "work" :> Capture "workLoad" Int :> Get '[JSON] WorkResult :<|>
  "wait" :> Capture "waitTime" Int :> Get '[JSON] WaitResult

itemApi :: Proxy ItemApi
itemApi = Proxy

initDB :: ByteString -> IO ()
initDB connstr = bracket (connectPostgreSQL connstr) close $ \conn -> do
  _ <- execute_ conn
    "CREATE TABLE IF NOT EXISTS item (itemid bigint PRIMARY KEY, itemmsg text not null, itemtitle text not null)"
  _ <- executeMany conn
    "INSERT INTO item (itemid, itemmsg, itemtitle) values (?, ?, ?) ON CONFLICT DO NOTHING" $ map (\x -> (x, "I am message number " <> show x <> " and I tell you I am indeed fine, so fine I could make this message even longer.", "The message " <> show x <> " out of 1000")) ([0..1000] :: [Int])
  return ()

-- * app

main :: IO ()
main = do
  hPutStrLn stderr "Starting service!"
  ps <- getEnv "PSQL_SERVICE_HOST"
  conn_num <- fmap read <$> getEnv "PSQL_CONNECTIONS"
  let port = 8080
      settings =
        setPort port $
        setBeforeMainLoop (hPutStrLn stderr ("Listening on port " ++ show port)) $
          defaultSettings
      connStr = "host=" <> (pack . fromMaybe "0.0.0.0" $ ps ) <> " sslmode=disable port=5432 dbname=db connect_timeout=10 user=admin password=admin"
  initDB connStr
  pool <- do
    createPool (connectPostgreSQL connStr) close 2 30 (fromMaybe 40 conn_num)
  runSettings settings =<< mkApp pool

mkApp :: Pool Connection ->
  IO Application
mkApp pool = return $ serve itemApi (server pool)

server :: Pool Connection ->
  Server ItemApi
server pool =
  getItems pool :<|>
  getItemById pool :<|>
  getWorkResult :<|>
  getWaitResult

getItems :: Pool Connection -> Handler [Item]
getItems pool =
  liftIO $
    withResource pool \conn ->
      query_ conn "SELECT itemid, itemmsg, itemtitle FROM item LIMIT 100"

getItemById :: Pool Connection -> Int -> Handler Item
getItemById pool int = do
  items <- liftIO $ withResource pool \conn ->
    query conn "SELECT itemid, itemmsg, itemtitle FROM item WHERE itemid=(?)" (Only int)
  case items of
    item : _ -> pure item
    _ -> throwError err404

getWorkResult :: Int -> Handler WorkResult
getWorkResult i = do
  pure $ WorkResult . Text.pack . show $ fib i
  where
    fib :: Int -> Int
    fib 0 = 0
    fib 1 = 1
    fib n = fib (n-1) + fib (n-2)

getWaitResult :: Int -> Handler WaitResult
getWaitResult t = do
  liftIO $ threadDelay (t * 1000)
  pure $ WaitResult $ "Did wait, yeah, " <> (Text.pack . show) t

-- * items

data WorkResult
  = WorkResult {
    workResult :: Text
  }
  deriving (ToJSON, FromJSON, Eq, Show, Generic)

data WaitResult
  = WaitResult {
    waitResult :: Text
  }
  deriving (ToJSON, FromJSON, Eq, Show, Generic)

data Item
  = Item {
    itemId :: Int,
    itemMsg :: Text,
    itemTitle :: Text
  }
  deriving (ToJSON, FromJSON, Eq, Show, Generic, FromRow)

