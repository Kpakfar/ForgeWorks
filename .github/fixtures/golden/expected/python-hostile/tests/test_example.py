from example import greet


def test_greet_includes_the_name():
    assert greet("world") == "Hello, world!"
