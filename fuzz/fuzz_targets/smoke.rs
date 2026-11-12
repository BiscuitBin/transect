//! Smoke-test the fuzz harness until the client has real input to fuzz.
#![no_main]
#![forbid(unsafe_code)]
#![expect(
    clippy::disallowed_macros,
    reason = "a fuzz target reports a failure by panicking"
)]

use libfuzzer_sys::fuzz_target;

// A deliberately trivial byte consumer local to this harness. Invalid UTF-8 is
// ordinary input; no parser or public library API is introduced for a smoke test.
fn smoke(data: &[u8]) {
    if let Ok(text) = std::str::from_utf8(data) {
        assert_eq!(text.as_bytes(), data);
    }
    assert_ne!(libtransect::version(), "");
}

fuzz_target!(|data: &[u8]| smoke(data));
