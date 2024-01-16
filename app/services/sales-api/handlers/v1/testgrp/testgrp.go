package testgrp

import (
	"context"
	"encoding/json"
	"errors"
	"math/rand"
	"net/http"
)

// Test is our example route.
func Test(ctx context.Context, w http.ResponseWriter, r *http.Request) error {

	// Validate the data
	// Call into the business layer
	// Return errors

	if n := rand.Intn(100); n%2 == 0 {
		return errors.New("UNTRUSTED ERROR")
	}

	status := struct {
		Status string
	}{
		Status: "OK OK",
	}

	return json.NewEncoder(w).Encode(status)
}
