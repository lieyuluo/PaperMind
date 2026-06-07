package auth

import (
	"encoding/json"
	"net/http"

	customerrors "github.com/papermind/papermind-go/pkg/errors"
	"github.com/papermind/papermind-go/pkg/response"

	"github.com/papermind/papermind-go/internal/model/dto"
	"github.com/papermind/papermind-go/internal/service"
)

type Controller struct {
	authService *service.AuthService
}

func NewController(authService *service.AuthService) *Controller {
	return &Controller{authService: authService}
}

// Login handles POST /api/v1/auth/login
func (c *Controller) Login(w http.ResponseWriter, r *http.Request) {
	var req dto.LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		response.Json(w, http.StatusBadRequest, response.Error(customerrors.CodeInvalidParams, "invalid request body"))
		return
	}

	resp, err := c.authService.Login(r.Context(), &req)
	if err != nil {
		bizErr, ok := err.(*customerrors.BizError)
		if ok {
			if bizErr.Code == customerrors.CodeUserNotFound || bizErr.Code == customerrors.CodePasswordWrong {
				response.Json(w, http.StatusUnauthorized, response.Error(bizErr.Code, bizErr.Message))
				return
			}
			response.Json(w, http.StatusInternalServerError, response.Error(bizErr.Code, bizErr.Message))
			return
		}
		response.Json(w, http.StatusInternalServerError, response.Error(customerrors.CodeInternalError, "internal error"))
		return
	}

	response.Json(w, http.StatusOK, response.Success(resp))
}

// Me handles GET /api/v1/me
func (c *Controller) Me(w http.ResponseWriter, r *http.Request) {
	userID := r.Context().Value("user_id").(string)

	resp, err := c.authService.GetCurrentUser(r.Context(), userID)
	if err != nil {
		bizErr, ok := err.(*customerrors.BizError)
		if ok {
			response.Json(w, http.StatusInternalServerError, response.Error(bizErr.Code, bizErr.Message))
			return
		}
		response.Json(w, http.StatusInternalServerError, response.Error(customerrors.CodeInternalError, "internal error"))
		return
	}

	response.Json(w, http.StatusOK, response.Success(resp))
}
