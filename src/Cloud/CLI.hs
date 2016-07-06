module Cloud.CLI where

import Options.Applicative

import Prelude (Char, String, Maybe (..), Read, ($))

-- Types for command-line options
type OptShortCode = Char
type OptLongName = String
type OptMetaVar = String
type OptDefault a = Maybe a
type OptHelpText = String

-- | Create well-formed named command-line option with default value of type a.
mkNamedOpt :: Read a
  => OptShortCode
  -> OptLongName
  -> OptMetaVar
  -> OptDefault a
  -> OptHelpText
  -> Parser a
mkNamedOpt s l m (Just d) h =
  option auto
    $ short s
    <> long l
    <> metavar m
    <> value d
    <> help h
mkNamedOpt s l m Nothing h =
  option auto
    $ short s
    <> long l
    <> metavar m
    <> help h
