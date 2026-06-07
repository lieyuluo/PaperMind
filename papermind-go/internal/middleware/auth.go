package middleware

import (
	"context"
	"net/http"
	"strings"

	customerrors "github.com/papermind/papermind-go/pkg/errors"
	"github.com/papermind/papermind-go/pkg/jwt"
	"github.com/papermind/papermind-go/pkg/response"
)

type AuthMiddleware struct {
	jwtSecret string
}

func NewAuthMiddleware(jwtSecret string) *AuthMiddleware {
	return &AuthMiddleware{jwtSecret: jwtSecret}
}

func (m *AuthMiddleware) Handle(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" {
			response.Json(w, http.StatusUnauthorized, response.Error(customerrors.CodeUnauthorized, "missing authorization header"))
			return
		}

		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) != 2 || parts[0] != "Bearer" {
			response.Json(w, http.StatusUnauthorized, response.Error(customerrors.CodeUnauthorized, "invalid authorization format"))
			return
		}

		claims, err := jwt.ParseToken(m.jwtSecret, parts[1])
		if err != nil {
			response.Json(w, http.StatusUnauthorized, response.Error(customerrors.CodeUnauthorized, "invalid or expired token"))
			return
		}

		// Store claims in context
		ctx := r.Context()
		ctx = context.WithValue(ctx, "user_id", claims.UserID)
		ctx = context.WithValue(ctx, "tenant_id", claims.TenantID)
		ctx = context.WithValue(ctx, "username", claims.Username)
		ctx = context.WithValue(ctx, "role", claims.Role)

		next(w, r.WithContext(ctx))
	}
}
