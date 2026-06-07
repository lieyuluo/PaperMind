package temporal

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"github.com/papermind/papermind-go/internal/config"
	"github.com/papermind/papermind-go/pkg/logger"
)

type Client struct {
	address    string
	namespace  string
	taskQueue  string
	httpClient *http.Client
}

func NewClient(cfg config.TemporalConfig) *Client {
	return &Client{
		address:    cfg.Address,
		namespace:  cfg.Namespace,
		taskQueue:  cfg.TaskQueue,
		httpClient: &http.Client{Timeout: 5 * time.Second},
	}
}

func (c *Client) HealthCheck(ctx context.Context) error {
	// Temporal health check via gRPC gateway HTTP endpoint
	url := fmt.Sprintf("http://%s/health", c.address)
	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return fmt.Errorf("failed to create temporal health check request: %w", err)
	}
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("temporal health check failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusOK {
		logger.Info("Temporal health check passed")
		return nil
	}
	return fmt.Errorf("temporal health check returned status: %d", resp.StatusCode)
}
