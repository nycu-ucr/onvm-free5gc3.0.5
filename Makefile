GO_BIN_PATH = bin
GO_SRC_PATH = NFs
C_BUILD_PATH = build
ROOT_PATH = $(shell pwd)

NF = $(GO_NF) $(C_NF)
GO_NF = amf ausf nrf nssf pcf smf udm udr n3iwf
C_NF = upf

WEBCONSOLE = webconsole

NF_GO_FILES = $(shell find $(GO_SRC_PATH)/$(%) -name "*.go" ! -name "*_test.go")
WEBCONSOLE_GO_FILES = $(shell find $(WEBCONSOLE) -name "*.go" ! -name "*_test.go")

VERSION = $(shell git describe --tags)
BUILD_TIME = $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
COMMIT_HASH = $(shell git submodule status | grep $(GO_SRC_PATH)/$(@F) | awk '{print $$(1)}' | cut -c1-8)
COMMIT_TIME = $(shell cd $(GO_SRC_PATH)/$(@F) && git log --pretty="%ai" -1 | awk '{time=$$(1)"T"$$(2)"Z"; print time}')
LDFLAGS = -X github.com/free5gc/version.VERSION=$(VERSION) \
          -X github.com/free5gc/version.BUILD_TIME=$(BUILD_TIME) \
          -X github.com/free5gc/version.COMMIT_HASH=$(COMMIT_HASH) \
          -X github.com/free5gc/version.COMMIT_TIME=$(COMMIT_TIME)

WEBCONSOLE_COMMIT_HASH = $(shell git submodule status | grep $(WEBCONSOLE) | awk '{print $$(1)}' | cut -c1-8)
WEBCONSOLE_COMMIT_TIME = $(shell cd $(WEBCONSOLE) && git log --pretty="%ai" -1 | awk '{time=$$(1)"T"$$(2)"Z"; print time}')
WEBCONSOLE_LDFLAGS = -X github.com/free5gc/version.VERSION=$(VERSION) \
                     -X github.com/free5gc/version.BUILD_TIME=$(BUILD_TIME) \
                     -X github.com/free5gc/version.COMMIT_HASH=$(WEBCONSOLE_COMMIT_HASH) \
                     -X github.com/free5gc/version.COMMIT_TIME=$(WEBCONSOLE_COMMIT_TIME)

.PHONY: $(NF) $(WEBCONSOLE) clean

.DEFAULT_GOAL: nfs

nfs: $(NF)

all: $(NF) $(WEBCONSOLE)

$(GO_NF): % : $(GO_BIN_PATH)/%

$(GO_BIN_PATH)/%: %.go $(NF_GO_FILES)
# $(@F): The file-within-directory part of the file name of the target.
	@echo "Start building $(@F)...."
	cd $(GO_SRC_PATH)/$(@F) && \
	CGO_LDFLAGS_ALLOW="-Wl,(--whole-archive|--no-whole-archive)" go build -ldflags "$(LDFLAGS)" -o $(ROOT_PATH)/$@ $(@F).go

vpath %.go $(addprefix $(GO_SRC_PATH)/, $(GO_NF))

$(C_NF): % :
	@echo "Start building $@...."
	cd $(GO_SRC_PATH)/$@ && \
	rm -rf $(C_BUILD_PATH) && \
	mkdir -p $(C_BUILD_PATH) && \
	cd ./$(C_BUILD_PATH) && \
	cmake .. && \
	make -j$(nproc)

$(WEBCONSOLE): $(WEBCONSOLE)/$(GO_BIN_PATH)/$(WEBCONSOLE)

$(WEBCONSOLE)/$(GO_BIN_PATH)/$(WEBCONSOLE): $(WEBCONSOLE)/server.go  $(WEBCONSOLE_GO_FILES)
	@echo "Start building $(@F)...."
	cd $(WEBCONSOLE)/frontend && \
	yarn install && \
	yarn build && \
	rm -rf ../public && \
	cp -R build ../public
	cd $(WEBCONSOLE) && \
	go build -ldflags "$(WEBCONSOLE_LDFLAGS)" -o $(ROOT_PATH)/$@ ./server.go

clean:
	rm -rf $(addprefix $(GO_BIN_PATH)/, $(GO_NF))
	rm -rf $(addprefix $(GO_SRC_PATH)/, $(addsuffix /$(C_BUILD_PATH), $(C_NF)))
	rm -rf $(WEBCONSOLE)/$(GO_BIN_PATH)/$(WEBCONSOLE)

