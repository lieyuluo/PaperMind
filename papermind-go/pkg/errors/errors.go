package errors

// Error codes
const (
	CodeSuccess       = 0
	CodeInvalidParams = 10001
	CodeUnauthorized  = 10002
	CodeInternalError = 10003
	CodeNotFound      = 10004
	CodeUserNotFound  = 10005
	CodePasswordWrong = 10006
	CodeDatabaseError = 10007
)

// BizError is a business error
type BizError struct {
	Code    int
	Message string
}

func (e *BizError) Error() string {
	return e.Message
}

func NewBizError(code int, message string) *BizError {
	return &BizError{Code: code, Message: message}
}
