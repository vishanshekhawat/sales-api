# Check to see if we can use ash, in Alpine images, or default to BASH.
SHELL_PATH = /bin/ash
SHELL = $(if $(wildcard $(SHELL_PATH)),/bin/ash,/bin/bash)


# ==============================================================================
# CLASS NOTES
#
# Kind
# 	For full Kind v0.18 release notes: https://github.com/kubernetes-sigs/kind/releases/tag/v0.18.0

# ==============================================================================
# Define dependencies

GOLANG          := golang:1.21
ALPINE          := alpine:3.18
KIND            := kindest/node:v1.27.1
POSTGRES        := postgres:15.3
VAULT           := hashicorp/vault:1.13
ZIPKIN          := openzipkin/zipkin:2.24
TELEPRESENCE    := datawire/tel2:2.13.1

KIND_CLUSTER    := vishn007-starter-cluster
NAMESPACE       := sales-system
APP             := sales
BASE_IMAGE_NAME := vishn007/service
SERVICE_NAME    := sales-api
VERSION         := 0.0.1
SERVICE_IMAGE   := $(BASE_IMAGE_NAME)/$(SERVICE_NAME):$(VERSION)

# VERSION       := "0.0.1-$(shell git rev-parse --short HEAD)"

# ==============================================================================
# Building containers

all: service

service:
	docker build \
		-f conf/docker/dockerfile.service \
		-t $(SERVICE_IMAGE) \
		--build-arg BUILD_REF=$(VERSION) \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		.

# ==============================================================================
# Running from within k8s/kind

dev-bill:
	kind load docker-image $(POSTGRES) --name $(KIND_CLUSTER)


dev-up-local:
	kind create cluster \
		--image $(KIND) \
		--name $(KIND_CLUSTER) \
		--config conf/k8s/dev/kind-config.yaml

	kubectl wait --timeout=120s --namespace=local-path-storage --for=condition=Available deployment/local-path-provisioner
	
	kind load docker-image $(TELEPRESENCE) --name $(KIND_CLUSTER)
	kind load docker-image $(POSTGRES) --name $(KIND_CLUSTER)

dev-up: dev-up-local
		telepresence --context=kind-$(KIND_CLUSTER) helm install
		telepresence --context=kind-$(KIND_CLUSTER) connect


dev-down:
	telepresence quit -s
	kind delete cluster --name $(KIND_CLUSTER)

dev-load:
	kind load docker-image $(SERVICE_IMAGE) --name $(KIND_CLUSTER)

dev-apply:
	kustomize build conf/k8s/dev/database | kubectl apply -f -
	kubectl rollout status --namespace=$(NAMESPACE) --watch --timeout=120s sts/database

	kustomize build conf/k8s/dev/sales | kubectl apply -f -
	kubectl wait pods --namespace=$(NAMESPACE) --selector app=$(APP) --for=condition=Ready

# ------------------------------------------------------------------------------

dev-status:
	kubectl get nodes -o wide
	kubectl get svc -o wide
	kubectl get pods -o wide --watch --all-namespaces

dev-restart:
	kubectl rollout restart deployment $(APP) --namespace=$(NAMESPACE)

dev-update: all dev-load dev-restart

dev-update-apply: all dev-load dev-apply

# ==============================================================================


# ------------------------------------------------------------------------------

dev-logs:
	kubectl logs --namespace=$(NAMESPACE) -l app=$(APP) --all-containers=true -f --tail=100 | go run app/tooling/logfmt/main.go -service=$(SERVICE_NAME)

dev-describe-deployment:
	kubectl describe deployment --namespace=$(NAMESPACE) $(APP)

dev-describe-sales:
	kubectl describe pod --namespace=$(NAMESPACE) -l app=$(APP)

# ==============================================================================


run-local:
	go run app/services/sales-api/main.go | go run app/tooling/logfmt/main.go -service=$(SERVICE_NAME)


run-local-1:
	go run app/services/sales-api/main.go 

run-local-help:
	go run app/services/sales-api/main.go --help

tidy:
	go mod tidy
	go mod vendor

metrics-view-local:
	expvarmon -ports="localhost:4000" -vars="build,requests,goroutines,errors,panics,mem:memstats.Alloc"

metrics-view:
	expvarmon -ports="$(SERVICE_NAME).$(NAMESPACE).svc.cluster.local:4000" -vars="build,requests,goroutines,errors,panics,mem:memstats.Alloc"

test-endpoint:
	curl -il $(SERVICE_NAME).$(NAMESPACE).svc.cluster.local:3000/test

test-endpoint-local:
	curl -il localhost:3000/test

test-endpoint-auth:
	curl -il -H "Authorization: Bearer ${TOKEN}" $(SERVICE_NAME).$(NAMESPACE).svc.cluster.local:3000/test/auth

test-endpoint-auth-local:
	curl -il -H "Authorization: Bearer ${TOKEN}" localhost:3000/test/auth


pgcli-local:
	pgcli postgresql://postgres:postgres@localhost

pgcli:
	pgcli postgresql://postgres:postgres@database-service.$(NAMESPACE).svc.cluster.local

migrate:
	go run app/tooling/admin/main.go

query-local:
	@curl -s http://localhost:3000/users?page=1&rows=2

query:
	@curl -s http://$(SERVICE_NAME).$(NAMESPACE).svc.cluster.local:3000/users?page=1&rows=2