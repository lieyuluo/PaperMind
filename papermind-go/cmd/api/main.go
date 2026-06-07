package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"gopkg.in/yaml.v3"

	"github.com/papermind/papermind-go/internal/config"
	"github.com/papermind/papermind-go/internal/controller/auth"
	healthctrl "github.com/papermind/papermind-go/internal/controller/health"
	"github.com/papermind/papermind-go/internal/middleware"
	"github.com/papermind/papermind-go/internal/service"
	"github.com/papermind/papermind-go/internal/storage/postgres"
	"github.com/papermind/papermind-go/pkg/logger"
)

func main() {
	logger.Init()

	// Load config
	cfg, err := loadConfig("manifest/config/config.yaml")
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	// Connect to PostgreSQL
	if err := postgres.Connect(cfg.Postgres); err != nil {
		log.Fatalf("Failed to connect to PostgreSQL: %v", err)
	}
	defer postgres.Close()

	// Initialize services
	authService := service.NewAuthService(postgres.DB, cfg.JWT.Secret, cfg.JWT.ExpireSeconds)

	// Initialize controllers
	authCtrl := auth.NewController(authService)

	// Setup routes
	mux := http.NewServeMux()

	// Health check (no auth required)
	mux.HandleFunc("/api/v1/health", healthctrl.HealthCheck)

	// Auth routes
	mux.HandleFunc("/api/v1/auth/login", authCtrl.Login)

	// Protected routes
	authMiddleware := middleware.NewAuthMiddleware(cfg.JWT.Secret)
	mux.HandleFunc("/api/v1/me", authMiddleware.Handle(authCtrl.Me))

	// Start server
	server := &http.Server{
		Addr:    cfg.Server.Address,
		Handler: mux,
	}

	// Graceful shutdown
	go func() {
		logger.Info("API server starting on %s", cfg.Server.Address)
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Server failed: %v", err)
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	logger.Info("Shutting down server...")
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := server.Shutdown(ctx); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}
	logger.Info("Server exited")
}

func loadConfig(path string) (*config.Config, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("failed to read config file: %w", err)
	}

	var cfg config.Config
	if err := yaml.Unmarshal(data, &cfg); err != nil {
		return nil, fmt.Errorf("failed to parse config file: %w", err)
	}

	return &cfg, nil
}
