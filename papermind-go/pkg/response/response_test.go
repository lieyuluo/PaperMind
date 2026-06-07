package response

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestSuccess(t *testing.T) {
	data := map[string]string{"key": "value"}
	resp := Success(data)
	if resp.Code != 0 {
		t.Errorf("expected code 0, got %d", resp.Code)
	}
	if resp.Message != "ok" {
		t.Errorf("expected message 'ok', got '%s'", resp.Message)
	}
}

func TestError(t *testing.T) {
	resp := Error(10001, "test error")
	if resp.Code != 10001 {
		t.Errorf("expected code 10001, got %d", resp.Code)
	}
	if resp.Message != "test error" {
		t.Errorf("expected message 'test error', got '%s'", resp.Message)
	}
	if resp.Data != nil {
		t.Error("expected data to be nil")
	}
}

func TestJson(t *testing.T) {
	w := httptest.NewRecorder()
	resp := Success(map[string]string{"status": "ok"})
	Json(w, http.StatusOK, resp)

	if w.Code != http.StatusOK {
		t.Errorf("expected status 200, got %d", w.Code)
	}
	ct := w.Header().Get("Content-Type")
	if ct != "application/json" {
		t.Errorf("expected Content-Type application/json, got %s", ct)
	}

	var decoded Response
	if err := json.NewDecoder(w.Body).Decode(&decoded); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}
	if decoded.Code != 0 {
		t.Errorf("expected code 0, got %d", decoded.Code)
	}
}
