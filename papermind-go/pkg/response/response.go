package response

import (
	"encoding/json"
	"net/http"
)

// Response is the unified API response format
type Response struct {
	Code    int         `json:"code"`
	Message string      `json:"message"`
	Data    interface{} `json:"data"`
}

// Success returns a success response with code 0
func Success(data interface{}) Response {
	return Response{
		Code:    0,
		Message: "ok",
		Data:    data,
	}
}

// Error returns an error response
func Error(code int, message string) Response {
	return Response{
		Code:    code,
		Message: message,
		Data:    nil,
	}
}

// Json writes a JSON response
func Json(w http.ResponseWriter, statusCode int, resp Response) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	json.NewEncoder(w).Encode(resp)
}
