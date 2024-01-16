package usersummary

import "github.com/vishn007/sales-api/buisness/data/order"

// DefaultOrderBy represents the default way we sort.
var DefaultOrderBy = order.NewBy(OrderByUserID, order.ASC)

// Set of fields that the results can be ordered by. These are the names
// that should be used by the application layer.
const (
	OrderByUserID   = "userid"
	OrderByUserName = "userName"
)
