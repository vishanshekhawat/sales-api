package testgrp

import (
	"context"
	"errors"
	"math/rand"
	"net/http"

	v1 "github.com/vishn007/sales-api/buisness/web/v1"
	"github.com/vishn007/sales-api/foundation/web"
)

// Test is our example route.
func Test(ctx context.Context, w http.ResponseWriter, r *http.Request) error {

	// Validate the data
	// Call into the business layer

	if n := rand.Intn(100); n%2 == 0 {
		return v1.NewRequestError(errors.New("TRUSTED ERROR"), http.StatusBadRequest)
	}

	status := struct {
		Status string
	}{
		Status: "OK OK",
	}

	return web.Respond(ctx, w, status, http.StatusOK)
}
