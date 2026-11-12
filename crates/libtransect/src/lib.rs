//! The core of Transect's in-application client.
//!
//! The client is not implemented yet, so this crate holds one item: its version.

/// The version of this crate, as the workspace manifest states it.
///
/// ```
/// assert_eq!(libtransect::version(), env!("CARGO_PKG_VERSION"));
/// ```
#[must_use]
pub const fn version() -> &'static str {
    env!("CARGO_PKG_VERSION")
}

#[cfg(test)]
#[expect(
    clippy::disallowed_macros,
    reason = "a failing test assertion should panic"
)]
mod tests {
    use super::version;

    #[test]
    fn the_version_is_the_manifests() {
        assert_eq!(version(), env!("CARGO_PKG_VERSION"));
    }
}
