DIST:=$(shell cd dist && pwd)
SWIFT_BUILD_FLAGS=--configuration release
PROJECTNAME := $(shell basename `pwd`)

.PHONY: all build clean xcode

all: build

.PHONY: build
build:
	swift build --triple arm64-apple-macosx $(SWIFT_BUILD_FLAGS) 
	swift build --triple x86_64-apple-macosx $(SWIFT_BUILD_FLAGS)
	-rm .build/TransomTool
	lipo -create -output .build/TransomTool-focal .build/arm64-apple-macosx/release/TransomTool-focal .build/x86_64-apple-macosx/release/TransomTool-focal
	cp .build/TransomTool-focal ./dist/TransomTool

.PHONY: clean
clean:
	rm -rf .build

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
	cp .build/TransomTool-focal ./dist/Transom
	
	-rm /opt/homebrew/dist/Transom
	-cp .build/TransomTool-focal /opt/homebrew/dist/Transom
	
	-rm /usr/local/dist/Transom
	-cp .build/TransomTool-focal /usr/local/dist/Transom

.PHONY: release
release: install docker

	# Getting plugin for focal
	docker pull kittymac/transom-focal:latest
	docker run --platform linux/arm64 --rm -v $(DIST):/outTemp kittymac/transom-focal /bin/bash -lc 'cp TransomTool-focal /outTemp/TransomTool-focal.artifactbundle/TransomTool-arm64/bin/TransomTool'
	docker run --platform linux/amd64 --rm -v $(DIST):/outTemp kittymac/transom-focal /bin/bash -lc 'cp TransomTool-focal /outTemp/TransomTool-focal.artifactbundle/TransomTool-amd64/bin/TransomTool'
	cp ./dist/TransomTool ./dist/TransomTool-focal.artifactbundle/TransomTool-macos/bin/TransomTool
	
	rm -f ./dist/TransomTool-focal.zip
	cd ./dist && zip -r ./TransomTool-focal.zip ./TransomTool-focal.artifactbundle
	
	# Getting plugin for amazonlinux2
	docker pull kittymac/transom-amazonlinux2:latest
	docker run --platform linux/arm64 --rm -v $(DIST):/outTemp kittymac/transom-amazonlinux2 /bin/bash -lc 'cp TransomTool-focal /outTemp/TransomTool-amazonlinux2.artifactbundle/TransomTool-arm64/bin/TransomTool'
	docker run --platform linux/amd64 --rm -v $(DIST):/outTemp kittymac/transom-amazonlinux2 /bin/bash -lc 'cp TransomTool-focal /outTemp/TransomTool-amazonlinux2.artifactbundle/TransomTool-amd64/bin/TransomTool'
	cp ./dist/TransomTool ./dist/TransomTool-amazonlinux2.artifactbundle/TransomTool-macos/bin/TransomTool
	
	rm -f ./dist/TransomTool-amazonlinux2.zip
	cd ./dist && zip -r ./TransomTool-amazonlinux2.zip ./TransomTool-amazonlinux2.artifactbundle
	
	# Getting plugin for fedora
	docker pull kittymac/transom-fedora:latest
	docker run --platform linux/arm64 --rm -v $(DIST):/outTemp kittymac/transom-fedora /bin/bash -lc 'cp TransomTool-focal /outTemp/TransomTool-fedora.artifactbundle/TransomTool-arm64/bin/TransomTool'
	docker run --platform linux/amd64 --rm -v $(DIST):/outTemp kittymac/transom-fedora /bin/bash -lc 'cp TransomTool-focal /outTemp/TransomTool-fedora.artifactbundle/TransomTool-amd64/bin/TransomTool'
	cp ./dist/TransomTool ./dist/TransomTool-fedora.artifactbundle/TransomTool-macos/bin/TransomTool
	
	rm -f ./dist/TransomTool-fedora.zip
	cd ./dist && zip -r ./TransomTool-fedora.zip ./TransomTool-fedora.artifactbundle

docker:
	-docker buildx create --name cluster_builder203
	-DOCKER_HOST=ssh://rjbowli@192.168.1.203 docker buildx create --name cluster_builder203 --platform linux/amd64 --append
	-docker buildx use cluster_builder203
	-docker buildx inspect --bootstrap
	-docker login
	docker buildx build --file Dockerfile-focal --platform linux/amd64,linux/arm64 --push -t kittymac/transom-focal .
	docker buildx build --file Dockerfile-amazonlinux2 --platform linux/amd64,linux/arm64 --push -t kittymac/transom-amazonlinux2 .
	docker buildx build --file Dockerfile-fedora --platform linux/amd64,linux/arm64 --push -t kittymac/transom-fedora .

docker-shell:
	docker buildx build --file Dockerfile-fedora --platform linux/amd64,linux/arm64 --push -t kittymac/transom-fedora .
	docker pull kittymac/transom-fedora
	docker run --platform linux/amd64 --rm -it --entrypoint bash kittymac/transom-fedora
