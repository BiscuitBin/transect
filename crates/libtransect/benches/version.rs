//! Smoke benchmark for the foundation, run by `just bench`.

fn main() {
    divan::main();
}

/// Time the core's entry point, including an opaque indirect call's overhead.
#[divan::bench]
fn version() {
    let entry: fn() -> &'static str = divan::black_box(libtransect::version);
    divan::black_box(entry());
}
