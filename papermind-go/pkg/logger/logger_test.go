package logger

import "testing"

func TestInit(t *testing.T) {
	Init()
	if InfoLogger == nil {
		t.Error("InfoLogger should not be nil after Init()")
	}
	if ErrorLogger == nil {
		t.Error("ErrorLogger should not be nil after Init()")
	}
}
