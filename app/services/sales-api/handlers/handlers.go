package handlers

import (
	"net/http"
	"os"

	"github.com/vishn007/sales-api/app/services/sales-api/handlers/v1/testgrp"
	"github.com/vishn007/sales-api/buisness/web/auth"
	"github.com/vishn007/sales-api/buisness/web/v1/mid"
	"github.com/vishn007/sales-api/foundation/web"
	"go.uber.org/zap"
)

// APIMuxConfig contains all the mandatory systems required by handlers.
type APIMuxConfig struct {
	Shutdown chan os.Signal
	Log      *zap.SugaredLogger
	Auth     *auth.Auth
}

func APIMux(cfg APIMuxConfig) *web.App {

	app := web.NewApp(cfg.Shutdown, mid.Logger(cfg.Log), mid.Errors(cfg.Log), mid.Metrics(), mid.Panics())

	app.Handle(http.MethodGet, "/test", testgrp.Test)
	app.Handle(http.MethodGet, "/test/auth", testgrp.Test, mid.Authenticate(cfg.Auth), mid.Authorize(cfg.Auth, auth.RuleAdminOnly))
	return app
}
