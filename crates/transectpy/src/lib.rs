//! The native module of the `transectpy` Python package.
//!
//! The client is not implemented yet, so the module exposes one attribute: the
//! version of the Rust client it is built on.

use pyo3::prelude::*;

/// The native module, loaded by Python as `transectpy._transectpy`.
#[pymodule]
fn _transectpy(module: &Bound<'_, PyModule>) -> PyResult<()> {
    module.add("__version__", transect::version())
}
