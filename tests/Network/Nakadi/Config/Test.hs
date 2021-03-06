{-# LANGUAGE FlexibleContexts           #-}
{-# LANGUAGE FlexibleInstances          #-}
{-# LANGUAGE MultiParamTypeClasses      #-}
{-# LANGUAGE RankNTypes                 #-}
{-# LANGUAGE ScopedTypeVariables        #-}
{-# LANGUAGE UndecidableInstances       #-}

module Network.Nakadi.Config.Test where

import           ClassyPrelude

import           Control.Monad.Catch            ( MonadThrow(..) )
import qualified Data.ByteString.Lazy          as LB
import           Data.Conduit                   ( ConduitM
                                                , transPipe
                                                )
import           Network.HTTP.Client
import           Network.HTTP.Client.Conduit    ( bodyReaderSource )
import           Network.HTTP.Client.TLS        ( getGlobalManager )
import           Network.Nakadi
import           Network.Nakadi.Tests.Common
import           System.IO.Unsafe
import           Test.Tasty
import           Test.Tasty.HUnit

testConfig :: TestTree
testConfig = testGroup "Config" [testCase "Use Custom HttpBackend" testCustomHttpBackend]

{-# NOINLINE requestsExecuted #-}
requestsExecuted :: TVar [Request]
requestsExecuted = unsafePerformIO . newTVarIO $ []

mockHttpBackendLbs :: Config b -> Request -> Maybe Manager -> App (Response LB.ByteString)
mockHttpBackendLbs _conf req _mngr = do
  atomically $ modifyTVar requestsExecuted (req :)
  throwM (HttpExceptionRequest req ResponseTimeout)

mockHttpBackendResponseOpen
  :: Config b -> Request -> Maybe Manager -> App (Response (ConduitM i ByteString App ()))
mockHttpBackendResponseOpen _config req _maybeMngr = do
  mngr <- liftIO getGlobalManager
  response <- liftIO $ responseOpen req mngr
  pure $ fmap (transPipe liftIO . bodyReaderSource) response

mockHttpBackendResponseClose :: Response a -> App ()
mockHttpBackendResponseClose = liftIO . responseClose

testCustomHttpBackend :: Assertion
testCustomHttpBackend = runApp $ do
  res0 <- try $ runNakadiT mockConfig registryPartitionStrategies -- This uses httpLbs.
  liftIO $ case res0 of
    Left (HttpExceptionRequest _ ResponseTimeout) -> return ()
    _ -> assertFailure "Expected ResponseTimeout exception from dummy HttpBackend"
  requests <- atomically . readTVar $ requestsExecuted
  liftIO $ 1 @=? length requests
 where
  mockConfig      = newConfig mockHttpBackend defaultRequest
  mockHttpBackend = HttpBackend
    { _httpLbs           = mockHttpBackendLbs
    , _httpResponseOpen  = mockHttpBackendResponseOpen
    , _httpResponseClose = mockHttpBackendResponseClose
    }
