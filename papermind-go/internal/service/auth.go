package service

import (
	"context"
	"database/sql"

	"github.com/papermind/papermind-go/internal/model/dto"
	"github.com/papermind/papermind-go/pkg/errors"
	"github.com/papermind/papermind-go/pkg/jwt"
	"golang.org/x/crypto/bcrypt"
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
	var (
		id           string
		tenantID     string
		username     string
		role         string
		passwordHash string
	)

	err := s.db.QueryRowContext(ctx,
		"SELECT id, tenant_id, username, password_hash, role FROM users WHERE username = $1",
		req.Username,
	).Scan(&id, &tenantID, &username, &passwordHash, &role)
	if err == sql.ErrNoRows {
		return nil, errors.NewBizError(errors.CodeUserNotFound, "user not found")
	}
	if err != nil {
		return nil, errors.NewBizError(errors.CodeInternalError, "database error")
	}

	if err := bcrypt.CompareHashAndPassword([]byte(passwordHash), []byte(req.Password)); err != nil {
		return nil, errors.NewBizError(errors.CodePasswordWrong, "wrong password")
	}

	token, err := s.generateToken(id, tenantID, username, role)
	if err != nil {
		return nil, errors.NewBizError(errors.CodeInternalError, "failed to generate token")
	}

	return &dto.LoginResponse{
		AccessToken: token,
		TokenType:   "Bearer",
		ExpiresIn:   s.expireSeconds,
	}, nil
}

// GetCurrentUser returns the current user's info
func (s *AuthService) GetCurrentUser(ctx context.Context, userID string) (*dto.UserInfoResponse, error) {
	var (
		tenantID string
		username string
		role     string
	)

	err := s.db.QueryRowContext(ctx,
		"SELECT tenant_id, username, role FROM users WHERE id = $1",
		userID,
	).Scan(&tenantID, &username, &role)
	if err == sql.ErrNoRows {
		return nil, errors.NewBizError(errors.CodeNotFound, "user not found")
	}
	if err != nil {
		return nil, errors.NewBizError(errors.CodeInternalError, "database error")
	}

	return &dto.UserInfoResponse{
		UserID:   userID,
		TenantID: tenantID,
		Username: username,
		Role:     role,
	}, nil
}

// generateToken is a helper to generate JWT tokens
func (s *AuthService) generateToken(userID, tenantID, username, role string) (string, error) {
	return jwt.GenerateToken(s.jwtSecret, s.expireSeconds, userID, tenantID, username, role)
}
