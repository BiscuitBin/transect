# Positive control for just py-lint: unused import F401 must keep failing.
import os

# Positive control for just py-lint: line over 100 characters E501 must keep failing.
LONG = "This positive control deliberately exceeds one hundred characters so E501 must report it on every lint gate run."
