# Change Log

## Unreleased

### Changes
 * Reduced the memory used by the name dictionary from ~25 MB to ~6.5 MB by storing names and their country frequencies in a few compact strings instead of one Hash and String per name

## 2.1.0 (2025-10-26)

### Changes
 * Updated dependencies based on newer Ruby features (h/t @jclusso via #22), require at least version 2.7
 * Updated code to fix formatting / style / linting issues
 * Add a CHANGELOG
 * Clarified license is GPL-3.0 in Gemspec (h/t @andrew via #18)
 * Fixed issue with country mapping for Brazil (h/t @jayelkaake via #19)
