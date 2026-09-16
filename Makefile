IMAGE ?= dhis2/postgresql-curl:17-legacy-r1
PLATFORMS ?= linux/amd64,linux/arm64
TEST_BUILD_FLAGS ?=

.PHONY: all build-all test push-all remove-all

all: test
	$(MAKE) push-all

# Load the host architecture for local use. CI tests each platform separately.
build-all:
	docker build --pull -t $(IMAGE) .

test:
	@set -eu; for platform in $$(echo $(PLATFORMS) | tr ',' ' '); do \
		image="$(IMAGE)-test-$${platform##*/}"; \
		docker buildx build $(TEST_BUILD_FLAGS) --platform "$$platform" --load -t "$$image" .; \
		./tests/restore.sh "$$image" "$$platform"; \
	done

push-all:
	docker buildx build --platform $(PLATFORMS) --push -t $(IMAGE) .

remove-all:
	docker rmi $(IMAGE)
