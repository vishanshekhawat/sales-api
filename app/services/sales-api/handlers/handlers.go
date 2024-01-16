package handlers

import (
	"net/http"
	"os"

	"github.com/dimfeld/httptreemux/v5"
	"github.com/vishn007/sales-api/app/services/sales-api/handlers/v1/testgrp"
	"go.uber.org/zap"
)

// APIMuxConfig contains all the mandatory systems required by handlers.
type APIMuxConfig struct {
	Shutdown chan os.Signal
	Log      *zap.SugaredLogger
}

func APIMux(cfg APIMuxConfig) http.Handler {
	mux := httptreemux.NewContextMux()

	mux.Handle(http.MethodGet, "/test", testgrp.Test)

	return mux
}
