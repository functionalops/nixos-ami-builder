{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import Options.Applicative
import Cloud.CLI

import Prelude (Maybe (..), ($), (.), (>>=), undefined)

import           Control.Lens
import           Control.Monad.IO.Class
import           Control.Monad.Trans.AWS
import           Data.ByteString.Builder (hPutBuilder)
import           Data.Conduit
import qualified Data.Conduit.List       as CL
import           Data.Monoid
import           Network.AWS.Data
import           Network.AWS.EC2
import           System.IO

data BuilderConfig = AMIBuilderConfig
  { hostExpression :: FilePath
  , deploymentExpression :: FilePath }

data ListInstances = ListInstances { cmdRegion :: Region }

main = listInstances

-- helper functions

amiBuilder :: IO ()
amiBuilder = execParser opts >>= act
  where
    act = undefined
    opts = info (helper <*> cfgParser)
      (fullDesc <>
        progDesc "Build AMI from Nix expression." <>
        header "nixos-ami-builder")

cfgParser :: Parser BuilderConfig
cfgParser =
  AMIBuilderConfig
    <$> (mkNamedOpt 'c' "config" "FILE" Nothing "Host Nix expression.")
    <*> (mkNamedOpt 'b' "base" "FILE" Nothing "Deployment Nix expression.")

-- AWS

listInstances :: IO ()
listInstances = execParser opts >>= act
  where
    act = instanceOverview . cmdRegion
    opts = info (helper <*> listInstancesParser)
      (fullDesc <> progDesc "List EC2 instances" <> header "list-instances")

listInstancesParser :: Parser ListInstances
listInstancesParser =
  ListInstances <$>
    (mkNamedOpt 'r' "region" "REGION" (Just NorthVirginia) "Ec2 region")

instanceOverview :: Region -> IO ()
instanceOverview r = do
    lgr <- newLogger Info stdout
    env <- newEnv r Discover <&> envLogger .~ lgr

    let pp x = mconcat
          [ "[instance:" <> build (x ^. insInstanceId) <> "] {"
          , "\n  public-dns = " <> build (x ^. insPublicDNSName)
          , "\n  state      = " <> build (x ^. insState . isName . to toBS)
          , "\n}\n"
          ]

    runResourceT . runAWST env $
        paginate describeInstances
            =$= CL.concatMap (view dirsReservations)
            =$= CL.concatMap (view rInstances)
            $$  CL.mapM_ (liftIO . hPutBuilder stdout . pp)
