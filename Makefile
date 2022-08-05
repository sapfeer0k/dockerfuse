Version := $(shell git describe --tags --dirty)
GitCommit := $(shell git rev-parse HEAD)
SATELLITE_LDFLAGS := "-extldflags '-static' -s -w -X main.Version=$(Version) -X main.GitCommit=$(GitCommit)"
DOCKERFUSE_LDFLAGS := "-s -w -X main.Version=$(Version) -X main.GitCommit=$(GitCommit)"

.PHONY: test all dockerfuse_satellite clean interactive_test

all: dockerfuse_satellite dockerfuse

dockerfuse_satellite_amd64: cmd/satellite/main.go cmd/satellite/server/server.go pkg/rpc_common/rpc_types.go pkg/rpc_common/utils.go
	env CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a \
		--ldflags $(SATELLITE_LDFLAGS) \
		-o dockerfuse_satellite_amd64 ./cmd/satellite/main.go

dockerfuse_satellite_arm64: cmd/satellite/main.go cmd/satellite/server/server.go pkg/rpc_common/rpc_types.go pkg/rpc_common/utils.go
	env CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -a \
		--ldflags $(SATELLITE_LDFLAGS) \
		-o dockerfuse_satellite_arm64 ./cmd/satellite/main.go

dockerfuse_satellite: dockerfuse_satellite_amd64 dockerfuse_satellite_arm64

dockerfuse: cmd/dockerfuse/main.go cmd/dockerfuse/client/client.go cmd/dockerfuse/client/dockerfuse_fs.go pkg/rpc_common/rpc_types.go pkg/rpc_common/utils.go
	env CGO_ENABLED=0 go build -a \
		--ldflags $(DOCKERFUSE_LDFLAGS) \
		-o dockerfuse ./cmd/dockerfuse/main.go

clean:
	rm -f dockerfuse_satellite_amd64 dockerfuse_satellite_arm64 dockerfuse

test: 
	go test ./...

interactive_test: all
	docker kill dockerfuse-test || true
	docker run -dit --rm --name dockerfuse-test alpine:latest sh
	umount tmp || true
	./dockerfuse -i dockerfuse-test -m ./tmp
	umount tmp || true
	docker kill dockerfuse-test || true
