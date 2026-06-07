package jwt

import (
	"testing"
	"time"
)

func TestGenerateAndParseToken(t *testing.T) {
	secret := "test-secret"
	expireSec := 3600
	userID := "user-123"
	tenantID := "tenant-456"
	username := "testuser"
	role := "Admin"

	token, err := GenerateToken(secret, expireSec, userID, tenantID, username, role)
	if err != nil {
		t.Fatalf("GenerateToken failed: %v", err)
	}
	if token == "" {
		t.Fatal("GenerateToken returned empty token")
	}

	claims, err := ParseToken(secret, token)
	if err != nil {
		t.Fatalf("ParseToken failed: %v", err)
	}
	if claims.UserID != userID {
		t.Errorf("expected user_id %s, got %s", userID, claims.UserID)
	}
	if claims.TenantID != tenantID {
		t.Errorf("expected tenant_id %s, got %s", tenantID, claims.TenantID)
	}
	if claims.Username != username {
		t.Errorf("expected username %s, got %s", username, claims.Username)
	}
	if claims.Role != role {
		t.Errorf("expected role %s, got %s", role, claims.Role)
	}
}

func TestParseTokenInvalidSecret(t *testing.T) {
	token, _ := GenerateToken("secret1", 3600, "u1", "t1", "user", "Admin")
	_, err := ParseToken("secret2", token)
	if err == nil {
		t.Fatal("expected error for wrong secret")
	}
}

func TestParseTokenExpired(t *testing.T) {
	secret := "test-secret"
	// Token with 1 second expiry
	token, _ := GenerateToken(secret, 1, "u1", "t1", "user", "Admin")
	time.Sleep(2 * time.Second)
	_, err := ParseToken(secret, token)
	if err == nil {
		t.Fatal("expected error for expired token")
	}
}
