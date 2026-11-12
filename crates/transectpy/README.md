# transectpy

`transectpy` is the Python client of Transect. Transect is an observability tool that
captures information about an application, its runtime and its state, and publishes it
so it can be queried. The package is built from the Rust core with PyO3.

The client is not implemented yet. The package exposes one thing, its version:

```python
import transectpy

print(transectpy.__version__)
```

It captures nothing yet and starts no threads.

Requires CPython 3.11 or newer on Linux or macOS. The wheel uses the stable ABI
(`abi3-py311`) and ships fully typed, with a stub and `py.typed`.

Repository: <https://github.com/BiscuitBin/transect>. Licensed under Apache-2.0; the
licence text ships in the wheel's `.dist-info/licenses/` directory.
