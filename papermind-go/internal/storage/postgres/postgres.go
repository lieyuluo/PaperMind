package postgres

import (
	"context"
	"database/sql"
	"fmt"

	_ "github.com/lib/pq"

	"github.com/papermind/papermind-go/internal/config"
	"github.com/papermind/papermind-go/pkg/logger"
)

var DB *sql.DB

// Connect establishes a connection to PostgreSQL
func Connect(cfg config.PostgresConfig) error {
	var err error
	DB, err = sql.Open("postgres", cfg.DSN)
	if err != nil {
		return fmt.Errorf("failed to open postgres connection: %w", err)
	}

	ctx := context.Background()
	if err := DB.PingContext(ctx); err != nil {
		return fmt.Errorf("failed to ping postgres: %w", err)
	}

	DB.SetMaxOpenConns(25)
	DB.SetMaxIdleConns(5)

	logger.Info("Connected to PostgreSQL successfully")
	return nil
}

// Close closes the PostgreSQL connection
func Close() error {
	if DB != nil {
		return DB.Close()
	}
	return nil
}

// HealthCheck checks if PostgreSQL is accessible
func HealthCheck(ctx context.Context) error {
	if DB == nil {
		return fmt.Errorf("postgres connection is nil")
	}
	return DB.PingContext(ctx)
}
