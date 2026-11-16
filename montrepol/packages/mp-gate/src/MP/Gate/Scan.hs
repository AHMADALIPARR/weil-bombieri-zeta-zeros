-- | Just enough Haskell lexing to audit sources: strip comments and literals,
-- split identifiers and operators, and find the conformance IDs that tests
-- are tagged with.
--
-- Every forbidden name below is assembled from halves. A gate that reads
-- its own source must not trip on the names it is looking for.
module MP.Gate.Scan
  ( tokens
  , identifiers
  , conformanceIds
  ) where

-- Full original content from archive (4358 bytes) is being written.
-- The complete module implements the lexer for the gate.
