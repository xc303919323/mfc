{-# LANGUAGE OverloadedStrings #-}

module Main where

import Macaf hiding (MacafParser)

import Data.String.Conversions
import qualified Data.Text as T
import qualified Data.Text.IO as T
import LLVM.Pretty
import Options.Applicative

import Prettyprinter
import Prettyprinter.Render.Text
import Text.Pretty.Simple

data Action
  = Ast
  | Sast
  | LLVM
  | Compile FilePath
  | Run

data Options =
  Options
    { action :: Action
    , infile :: FilePath
    }

actionP :: Parser Action
actionP =
  flag' Ast (long "ast" <> short 'a' <> help "Pretty print the ast") <|>
  flag' Sast (long "sast" <> short 's' <> help "Pretty print the sast") <|>
  flag'
    LLVM
    (long "llvm" <> short 'l' <> help "Pretty print the generated llvm") <|>
  flag' Compile (long "compile" <> short 'c' <> help "Compile to an executable") <*>
  strOption (short 'o' <> value "a.out" <> metavar "FILE") <|>
  pure Run

optionsP :: Parser Options
optionsP =
  Options <$> actionP <*> strArgument (help "Source file" <> metavar "FILE")

main :: IO ()
main = runOpts =<< execParser (optionsP `withInfo` infoString)
  where
    withInfo opts desc = info (helper <*> opts) $ progDesc desc
    infoString =
      "Run the mfc compiler on the given file. \
       \Passing no flags will compile the file, execute it, and print the output."

runOpts :: Options -> IO ()
runOpts (Options action infile) = do
  program <- T.readFile infile
  let parseTree = runParser programP infile program
  case parseTree of
    Left err -> putStrLn $ errorBundlePretty err
    -- Right ast -> pPrint ast
    Right ast ->
      let llvm = codegenProgram ast
       in pPrint $ show llvm
      -- in T.putStrLn . cs . ppllvm $ llvm
       -- in pPrint $ show llvm
    -- Right ast -> putDoc $ pretty ast <> "\n"
      -- case action of
        --aAst -> putDoc $ pretty ast <> "\n"
        -- _ ->
        --  case checkProgram ast of
        --    Left err -> putDoc $ pretty err <> "\n"
        --    Right sast ->
        --      let llvm = codegenProgram sast
        --       in case action of
        --            Sast -> pPrint sast
        --            LLVM -> T.putStrLn . cs . ppllvm $ llvm
       --             Compile outfile -> compile llvm outfile
       --             Run -> run llvm >>= T.putStr
       --             Ast -> error "unreachable"
