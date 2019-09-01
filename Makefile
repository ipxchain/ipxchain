PACKAGES_NOSIMULATION=$(shell go list ./... | grep -v '/simulation')
PACKAGES_SIMTEST=$(shell go list ./... | grep '/simulation')
#VERSION := $(shell echo $(shell git describe --tags) | sed 's/^v//')
VERSION := 0.1.0
COMMIT := $(shell git log -1 --format='%H')
CAT := $(if $(filter $(OS),Windows_NT),type,cat)
LEDGER_ENABLED ?= true
GOTOOLS = \
	github.com/golang/dep/cmd/dep \
	github.com/alecthomas/gometalinter \
	github.com/rakyll/statik
GOBIN ?= $(GOPATH)/bin

# process build tags

build_tags = netgo
ifeq ($(LEDGER_ENABLED),true)
  ifeq ($(OS),Windows_NT)
    GCCEXE = $(shell where gcc.exe 2> NUL)
    ifeq ($(GCCEXE),)
      $(error gcc.exe not installed for ledger support, please install or set LEDGER_ENABLED=false)
    else
      build_tags += ledger
    endif
  else
    UNAME_S = $(shell uname -s)
    ifeq ($(UNAME_S),OpenBSD)
      $(warning OpenBSD detected, disabling ledger support (https://github.com/ipxchain/ipxchain/issues/1988))
    else
      GCC = $(shell command -v gcc 2> /dev/null)
      ifeq ($(GCC),)
        $(error gcc not installed for ledger support, please install or set LEDGER_ENABLED=false)
      else
        build_tags += ledger
      endif
    endif
  endif
endif

ifeq ($(WITH_CLEVELDB),yes)
  build_tags += gcc
endif
build_tags += $(BUILD_TAGS)
build_tags := $(strip $(build_tags))

# process linker flags

ldflags = -X github.com/ipxchain/ipxchain/version.Version=$(VERSION) \
	-X github.com/ipxchain/ipxchain/version.Commit=$(COMMIT) \
  -X github.com/ipxchain/ipxchain/version.VendorDirHash=$(shell $(CAT) vendor-deps) \
  -X "github.com/ipxchain/ipxchain/version.BuildTags=$(build_tags)"

ifeq ($(WITH_CLEVELDB),yes)
  ldflags += -X github.com/ipxchain/ipxchain/types.DBBackend=cleveldb
endif
ldflags += $(LDFLAGS)
ldflags := $(strip $(ldflags))

BUILD_FLAGS := -tags "$(build_tags)" -ldflags '$(ldflags)'

all: devtools vendor-deps install test_lint test

# The below include contains the tools target.
include scripts/Makefile

########################################
### CI

ci: devtools vendor-deps install test_cover test_lint test

########################################
### Build/Install

build:
ifeq ($(OS),Windows_NT)
	go build $(BUILD_FLAGS) -o build/truth.exe ./cmd/truth/cmd/truth
	go build $(BUILD_FLAGS) -o build/truthcli.exe ./cmd/truth/cmd/truthcli
else
	go build $(BUILD_FLAGS) -o build/truth ./cmd/truth/cmd/truth
	go build $(BUILD_FLAGS) -o build/truthcli ./cmd/truth/cmd/truthcli

endif

build-linux: vendor-deps
	LEDGER_ENABLED=false GOOS=linux GOARCH=amd64 $(MAKE) build

update_gaia_lite_docs:
	@statik -src=client/lcd/swagger-ui -dest=client/lcd -f

install: vendor-deps check-ledger update_gaia_lite_docs
	go install $(BUILD_FLAGS) ./cmd/truth/cmd/truth
	go install $(BUILD_FLAGS) ./cmd/truth/cmd/truthcli
	
dist:
	@bash publish/dist.sh
	@bash publish/publish.sh

########################################
### Tools & dependencies

check_tools:
	@# https://stackoverflow.com/a/25668869
	@echo "Found tools: $(foreach tool,$(notdir $(GOTOOLS)),\
        $(if $(shell which $(tool)),$(tool),$(error "No $(tool) in PATH")))"

update_tools:
	@echo "--> Updating tools to correct version"
	$(MAKE) --always-make tools

update_dev_tools:
	@echo "--> Downloading linters (this may take awhile)"
	$(GOPATH)/src/github.com/alecthomas/gometalinter/scripts/install.sh -b $(GOBIN)
	go get -u github.com/tendermint/lint/golint

devtools: devtools-stamp
devtools-clean: tools-clean
devtools-stamp: tools
	@echo "--> Downloading linters (this may take awhile)"
	$(GOPATH)/src/github.com/alecthomas/gometalinter/scripts/install.sh -b $(GOBIN)
	go get github.com/tendermint/lint/golint
	touch $@

vendor-deps: tools
	@echo "--> Generating vendor directory via dep ensure"
	@rm -rf .vendor-new
	@dep ensure -v -vendor-only
	tar -c vendor/ | sha1sum | cut -d' ' -f1 > $@

update_vendor_deps: tools
	@echo "--> Running dep ensure"
	@rm -rf .vendor-new
	@dep ensure -v

draw_deps: tools
	@# requires brew install graphviz or apt-get install graphviz
	go get github.com/RobotsAndPencils/goviz
	@goviz -i github.com/ipxchain/ipxchain/cmd/truth/cmd/truth -d 2 | dot -Tpng -o dependency-graph.png

clean:
	rm -f devtools-stamp vendor-deps snapcraft-local.yaml

distclean: clean
	rm -rf vendor/

########################################
### Documentation

godocs:
	@echo "--> Wait a few seconds and visit http://localhost:6060/pkg/github.com/ipxchain/ipxchain/types"
	godoc -http=:6060


########################################
### Testing

test: test_unit

test_cli:
	@go test -p 4 `go list github.com/ipxchain/ipxchain/cmd/truth/cli_test` -tags=cli_test

test_ledger:
    # First test with mock
	@go test `go list github.com/ipxchain/ipxchain/crypto` -tags='cgo ledger test_ledger_mock'
    # Now test with a real device
	@go test -v `go list github.com/ipxchain/ipxchain/crypto` -tags='cgo ledger'

test_unit:
	@VERSION=$(VERSION) go test $(PACKAGES_NOSIMULATION) -tags='ledger test_ledger_mock'

test_race:
	@VERSION=$(VERSION) go test -race $(PACKAGES_NOSIMULATION)

test_sim_gaia_nondeterminism:
	@echo "Running nondeterminism test..."
	@go test ./cmd/truth/app -run TestAppStateDeterminism -SimulationEnabled=true -v -timeout 10m

test_sim_gaia_custom_genesis_fast:
	@echo "Running custom genesis simulation..."
	@echo "By default, ${HOME}/.truth/config/genesis.json will be used."
	@go test ./cmd/truth/app -run TestFullGaiaSimulation -SimulationGenesis=${HOME}/.truth/config/genesis.json \
		-SimulationEnabled=true -SimulationNumBlocks=100 -SimulationBlockSize=200 -SimulationCommit=true -SimulationSeed=99 -SimulationPeriod=5 -v -timeout 24h

test_sim_gaia_fast:
	@echo "Running quick Truth simulation. This may take several minutes..."
	@go test ./cmd/truth/app -run TestFullGaiaSimulation -SimulationEnabled=true -SimulationNumBlocks=100 -SimulationBlockSize=200 -SimulationCommit=true -SimulationSeed=99 -SimulationPeriod=5 -v -timeout 24h

test_sim_gaia_import_export:
	@echo "Running Truth import/export simulation. This may take several minutes..."
	@bash scripts/multisim.sh 50 5 TestGaiaImportExport

test_sim_gaia_simulation_after_import:
	@echo "Running Truth simulation-after-import. This may take several minutes..."
	@bash scripts/multisim.sh 50 5 TestGaiaSimulationAfterImport

test_sim_gaia_custom_genesis_multi_seed:
	@echo "Running multi-seed custom genesis simulation..."
	@echo "By default, ${HOME}/.truth/config/genesis.json will be used."
	@bash scripts/multisim.sh 400 5 TestFullGaiaSimulation ${HOME}/.truth/config/genesis.json

test_sim_gaia_multi_seed:
	@echo "Running multi-seed Truth simulation. This may take awhile!"
	@bash scripts/multisim.sh 400 5 TestFullTruthSimulation

SIM_NUM_BLOCKS ?= 500
SIM_BLOCK_SIZE ?= 200
SIM_COMMIT ?= true
test_sim_gaia_benchmark:
	@echo "Running Truth benchmark for numBlocks=$(SIM_NUM_BLOCKS), blockSize=$(SIM_BLOCK_SIZE). This may take awhile!"
	@go test -benchmem -run=^$$ github.com/ipxchain/ipxchain/cmd/truth/app -bench ^BenchmarkFullGaiaSimulation$$  \
		-SimulationEnabled=true -SimulationNumBlocks=$(SIM_NUM_BLOCKS) -SimulationBlockSize=$(SIM_BLOCK_SIZE) -SimulationCommit=$(SIM_COMMIT) -timeout 24h

test_sim_gaia_profile:
	@echo "Running Truth benchmark for numBlocks=$(SIM_NUM_BLOCKS), blockSize=$(SIM_BLOCK_SIZE). This may take awhile!"
	@go test -benchmem -run=^$$ github.com/ipxchain/ipxchain/cmd/truth/app -bench ^BenchmarkFullGaiaSimulation$$ \
		-SimulationEnabled=true -SimulationNumBlocks=$(SIM_NUM_BLOCKS) -SimulationBlockSize=$(SIM_BLOCK_SIZE) -SimulationCommit=$(SIM_COMMIT) -timeout 24h -cpuprofile cpu.out -memprofile mem.out

test_cover:
	@export VERSION=$(VERSION); bash -x tests/test_cover.sh

test_lint:
	gometalinter --config=tools/gometalinter.json ./...
	!(gometalinter --exclude /usr/lib/go/src/ --exclude client/lcd/statik/statik.go --exclude 'vendor/*' --disable-all --enable='errcheck' --vendor ./... | grep -v "client/")
	find . -name '*.go' -type f -not -path "./vendor*" -not -path "*.git*" | xargs gofmt -d -s
	dep status >> /dev/null
	!(grep -n branch Gopkg.toml)

format:
	find . -name '*.go' -type f -not -path "./vendor*" -not -path "*.git*" -not -path "./client/lcd/statik/statik.go" | xargs gofmt -w -s
	find . -name '*.go' -type f -not -path "./vendor*" -not -path "*.git*" -not -path "./client/lcd/statik/statik.go" | xargs misspell -w
	find . -name '*.go' -type f -not -path "./vendor*" -not -path "*.git*" -not -path "./client/lcd/statik/statik.go" | xargs goimports -w -local github.com/ipxchain/ipxchain

benchmark:
	@go test -bench=. $(PACKAGES_NOSIMULATION)


########################################
### Devdoc

DEVDOC_SAVE = docker commit `docker ps -a -n 1 -q` devdoc:local

devdoc_init:
	docker run -it -v "$(CURDIR):/go/src/github.com/ipxchain/ipxchain" -w "/go/src/github.com/ipxchain/ipxchain" tendermint/devdoc echo
	# TODO make this safer
	$(call DEVDOC_SAVE)

devdoc:
	docker run -it -v "$(CURDIR):/go/src/github.com/ipxchain/ipxchain" -w "/go/src/github.com/ipxchain/ipxchain" devdoc:local bash

devdoc_save:
	# TODO make this safer
	$(call DEVDOC_SAVE)

devdoc_clean:
	docker rmi -f $$(docker images -f "dangling=true" -q)

devdoc_update:
	docker pull tendermint/devdoc


########################################
### Local validator nodes using docker and docker-compose

build-docker-truthnode:
	$(MAKE) -C networks/local

# Run a 4-node testnet locally
localnet-start: localnet-stop
	@if ! [ -f build/node0/truth/config/genesis.json ]; then docker run --rm -v $(CURDIR)/build:/truth:Z tendermint/truthnode testnet --v 4 -o . --starting-ip-address 192.168.10.12 ; fi
	docker-compose up -d

# Stop testnet
localnet-stop:
	docker-compose down


########################################
### Packaging

snapcraft-local.yaml: snapcraft-local.yaml.in
	sed "s/@VERSION@/${VERSION}/g" < $< > $@

# To avoid unintended conflicts with file names, always add to .PHONY
# unless there is a reason not to.
# https://www.gnu.org/software/make/manual/html_node/Phony-Targets.html
.PHONY: build install install_debug dist clean distclean \
check_tools check_dev_tools get_vendor_deps draw_deps test test_cli test_unit \
test_cover test_lint benchmark devdoc_init devdoc devdoc_save devdoc_update \
build-linux build-docker-truthnode localnet-start localnet-stop \
format check-ledger test_sim_truth_nondeterminism test_sim_modules test_sim_truth_fast \
test_sim_truth_custom_genesis_fast test_sim_truth_custom_genesis_multi_seed \
test_sim_truth_multi_seed test_sim_truth_import_export update_tools update_dev_tools \
devtools-clean