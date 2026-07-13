package app

import "testing"

func TestGreet(t *testing.T) {
	got := Greet("world")
	want := "Hello, world!"
	if got != want {
		t.Errorf("Greet(%q) = %q, want %q", "world", got, want)
	}
}
