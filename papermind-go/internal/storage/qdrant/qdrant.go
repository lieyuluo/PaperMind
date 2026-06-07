package qdrant

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"github.com/papermind/papermind-go/internal/config"
	"github.com/papermind/papermind-go/pkg/logger"
)

type Client struct {
	httpAddress string
	httpClient  *http.Client
}

func NewClient(cfg config.QdrantConfig) *Client {
	return &Client{
		httpAddress: cfg.HTTPAddress,
		httpClient:  &http.Client{Timeout: 5 * time.Second},
	}
}

func (c *Client) HealthCheck(ctx context.Context) error {
	url := c.httpAddress + "/healthz"
	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return fmt.Errorf("failed to create qdrant health check request: %w", err)
	}
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("qdrant health check failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusOK {
		logger.Info("Qdrant health check passed")
		return nil
	}
	return fmt.Errorf("qdrant health check returned status: %d", resp.StatusCode)
}
