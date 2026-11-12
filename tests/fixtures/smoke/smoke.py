# Copyright 2026 Steven Cutting
"""Import the installed wheel in isolation and check its version and surface."""

import importlib.metadata

import transectpy

assert transectpy.__version__ == importlib.metadata.version("transectpy")
assert transectpy.__all__ == ["__version__"]
print(f"transectpy {transectpy.__version__} imported from {transectpy.__file__}")
