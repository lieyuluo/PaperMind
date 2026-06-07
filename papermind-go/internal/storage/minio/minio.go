package minio

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"github.com/papermind/papermind-go/internal/config"
	"github.com/papermind/papermind-go/pkg/logger"
)

type Client struct {
	endpoint   string
	accessKey  string
	secretKey  string
	bucket     string
	useSSL     bool
	httpClient *http.Client
}

func NewClient(cfg config.MinioConfig) *Client {
	return &Client{
		endpoint:   cfg.Endpoint,
		accessKey:  cfg.AccessKey,
		secretKey:  cfg.SecretKey,
		bucket:     cfg.Bucket,
		useSSL:     cfg.UseSSL,
		httpClient: &http.Client{Timeout: 5 * time.Second},
	}
}

func (c *Client) HealthCheck(ctx context.Context) error {
	// MinIO health check via HTTP
	scheme := "http"
	if c.useSSL {
		scheme = "https"
	}
	url := fmt.Sprintf("%s://%s/minio/health/live", scheme, c.endpoint)
	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return fmt.Errorf("failed to create minio health check request: %w", err)
	}
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("minio health check failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusOK {
		logger.Info("MinIO health check passed")
		return nil
	}
	return fmt.Errorf("minio health check returned status: %d", resp.StatusCode)
}
