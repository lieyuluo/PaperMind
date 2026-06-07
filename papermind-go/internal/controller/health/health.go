package health

import (
	"net/http"

	"github.com/papermind/papermind-go/pkg/response"
)

// HealthCheck handles GET /api/v1/health
func HealthCheck(w http.ResponseWriter, r *http.Request) {
	response.Json(w, http.StatusOK, response.Success(map[string]string{
		"status": "ok",
	}))
}
