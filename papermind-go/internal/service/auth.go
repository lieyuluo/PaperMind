package service

import (
	"context"
	"database/sql"

	"github.com/papermind/papermind-go/internal/model/dto"
	"github.com/papermind/papermind-go/pkg/errors"
	"github.com/papermind/papermind-go/pkg/jwt"
)

// AuthService handles authentication logic
type AuthService struct {
	db            *sql.DB
	jwtSecret     string
	expireSeconds int
}

// NewAuthService creates a new AuthService
func NewAuthService(db *sql.DB, jwtSecret string, expireSeconds int) *AuthService {
	return &AuthService{
		db:            db,
		jwtSecret:     jwtSecret,
		expireSeconds: expireSeconds,
	}
}

// Login authenticates a user and returns a token
func (s *AuthService) Login(ctx context.Context, req *dto.LoginRequest) (*dto.LoginResponse, error) {
	// TODO: implement actual authentication with database lookup
	// For now, return a placeholder error
	return nil, errors.NewBizError(errors.CodeUserNotFound, "user not found")
}

// GetCurrentUser returns the current user's info
func (s *AuthService) GetCurrentUser(ctx context.Context, userID string) (*dto.UserInfoResponse, error) {
	// TODO: implement actual user lookup
	return nil, errors.NewBizError(errors.CodeNotFound, "user not found")
}

// generateToken is a helper to generate JWT tokens
func (s *AuthService) generateToken(userID, tenantID, username, role string) (string, error) {
	return jwt.GenerateToken(s.jwtSecret, s.expireSeconds, userID, tenantID, username, role)
}
