# Positive control for just py-typecheck: incompatible assignment must keep failing.
x: int = "a"


def needs_integer(value: int) -> int:
    return value


# Positive control for just py-typecheck: wrong argument type must keep failing.
needs_integer("a")
