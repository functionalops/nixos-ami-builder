module Cloud.Types where

data Region = UsWest1
            | UsWest2
            | UsEast1 deriving (Show, Eq, Enum)

data Target = AWS Region

data Config a b = Config { configure :: b -> a }


