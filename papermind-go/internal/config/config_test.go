package config

import (
	"testing"
)

func TestConfigStruct(t *testing.T) {
	cfg := Config{
		Server: ServerConfig{Address: ":8080", Mode: "dev"},
		JWT: JWTConfig{Secret: "test", ExpireSeconds: 3600},
	}
	if cfg.Server.Address != ":8080" {
		t.Errorf("expected :8080, got %s", cfg.Server.Address)
	}
	if cfg.JWT.ExpireSeconds != 3600 {
		t.Errorf("expected 3600, got %d", cfg.JWT.ExpireSeconds)
	}
}
