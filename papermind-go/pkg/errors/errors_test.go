package errors

import "testing"

func TestBizError(t *testing.T) {
	err := NewBizError(CodeInvalidParams, "invalid params")
	if err.Code != CodeInvalidParams {
		t.Errorf("expected code %d, got %d", CodeInvalidParams, err.Code)
	}
	if err.Message != "invalid params" {
		t.Errorf("expected message 'invalid params', got '%s'", err.Message)
	}
	if err.Error() != "invalid params" {
		t.Errorf("expected Error() to return 'invalid params', got '%s'", err.Error())
	}
}
