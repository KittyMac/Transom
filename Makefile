define DOCKER_BUILD_TOOL
	docker buildx build --file Dockerfile-$(1) --platform linux/amd64,linux/arm64 --push -t kittymac/transom-$(1) .

	docker pull kittymac/transom-$(1):latest
	mkdir -p ./dist/TransomTool-$(1).artifactbundle/TransomTool-arm64/bin/
	mkdir -p ./dist/TransomTool-$(1).artifactbundle/TransomTool-amd64/bin/
	mkdir -p ./dist/TransomTool-$(1).artifactbundle/TransomTool-macos/bin/
	docker run --platform linux/arm64 --rm -v $(DIST):/outTemp kittymac/transom-$(1) /bin/bash -lc 'cp TransomTool /outTemp/TransomTool-$(1).artifactbundle/TransomTool-arm64/bin/TransomTool'
	docker run --platform linux/amd64 --rm -v $(DIST):/outTemp kittymac/transom-$(1) /bin/bash -lc 'cp TransomTool /outTemp/TransomTool-$(1).artifactbundle/TransomTool-amd64/bin/TransomTool'
	cp ./dist/TransomTool ./dist/TransomTool-$(1).artifactbundle/TransomTool-macos/bin/TransomTool
	
	rm -f ./dist/TransomTool-$(1).zip
	cd ./dist && zip -r ./TransomTool-$(1).zip ./TransomTool-$(1).artifactbundle
endef

DIST:=$(shell cd dist && pwd)
SWIFT_BUILD_FLAGS=--configuration release
PROJECTNAME := $(shell basename `pwd`)

.PHONY: all build clean xcode

all: build

.PHONY: build
build: pamphlet
	swift build --triple arm64-apple-macosx $(SWIFT_BUILD_FLAGS)
	swift build --triple x86_64-apple-macosx $(SWIFT_BUILD_FLAGS)
	-rm .build/TransomTool
	lipo -create -output .build/TransomTool .build/arm64-apple-macosx/release/TransomTool .build/x86_64-apple-macosx/release/TransomTool
	cp .build/TransomTool ./dist/TransomTool

.PHONY: clean
clean:
	rm -rf .build

.PHONY: clean-repo
clean-repo:
	rm -rf /tmp/clean-repo/
	mkdir -p /tmp/clean-repo/
	cd /tmp/clean-repo/ && git clone https://github.com/KittyMac/Transom.git/
	cd /tmp/clean-repo/Transom && cp -r dist ../dist.tmp && cp .git/config ../config
	cd /tmp/clean-repo/Transom && git filter-repo --invert-paths --path dist
	cd /tmp/clean-repo/Transom && mv ../dist.tmp dist && mv ../config .git/config
	cd /tmp/clean-repo/Transom && git add dist
	cd /tmp/clean-repo/Transom && git commit -a -m "clean-repo"
	open /tmp/clean-repo/Transom
	# clean complete; manual push required
	# git push origin --force --all
	# git push origin --force --tags
	
.PHONY: pamphlet
pamphlet:
	pamphlet generate --prefix TransomFramework Sources/TransomFramework/Pamphlet Sources/TransomFramework

.PHONY: update
update:
	swift package update

.PHONY: run
run:
	swift run $(SWIFT_BUILD_FLAGS)
	
.PHONY: test
test:
	swift test --configuration debug

.PHONY: install
install: clean build
	-rm ./dist/Transom
	cp .build/TransomTool ./dist/Transom
	
	-rm /opt/homebrew/dist/Transom
	-cp .build/TransomTool /opt/homebrew/dist/Transom
	
	-rm /usr/local/dist/Transom
	-cp .build/TransomTool /usr/local/dist/Transom

.PHONY: release
release: install focal-571 focal-592 fedora38-573

focal-571: pamphlet
	@$(call DOCKER_BUILD_TOOL,focal-571)
	
focal-592: pamphlet
	@$(call DOCKER_BUILD_TOOL,focal-592)

fedora38-573: pamphlet
	@$(call DOCKER_BUILD_TOOL,fedora38-573)

docker:
	-DOCKER_HOST=ssh://rjbowli@192.168.111.203 docker buildx create --name cluster_builder203 --platform linux/amd64
	-docker buildx create --name cluster_builder203 --platform linux/arm64 --append
	-docker buildx use cluster_builder203
	-docker buildx inspect --bootstrap
	-docker login

docker-shell:
	docker buildx build --file Dockerfile-fedora --platform linux/amd64,linux/arm64 --push -t kittymac/transom-fedora .
	docker pull kittymac/transom-fedora
	docker run --platform linux/amd64 --rm -it --entrypoint bash kittymac/transom-fedora
