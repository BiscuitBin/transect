//! NOT YET IMPLEMENTED: the data writer.
//!
//! Its role is settled: a background thread that drains the ingest queue into
//! local databases. It waits on three undecided areas, each recorded in
//! `docs/project/open-decisions.md`: the ingest queue it drains, the local
//! database it writes to, and schema evolution, which governs how it writes a
//! table whose columns have changed. This module holds nothing until they are
//! decided.
