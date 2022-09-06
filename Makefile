SWIFT_BUILD_FLAGS=--configuration release
PROJECTNAME := $(shell basename `pwd`)

.PHONY: all build clean xcode

all: build

.PHONY: build
build:
	swift build --triple arm64-apple-macosx $(SWIFT_BUILD_FLAGS) 
	swift build --triple x86_64-apple-macosx $(SWIFT_BUILD_FLAGS)
	-rm .build/TransomTool
	lipo -create -output .build/TransomTool .build/arm64-apple-macosx/release/TransomTool .build/x86_64-apple-macosx/release/TransomTool
	cp .build/TransomTool ./dist/TransomTool

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
	-rm ./dist/TransomTool
	cp .build/TransomTool ./dist/TransomTool
	
	-rm /opt/homebrew/dist/TransomTool
	-cp .build/TransomTool /opt/homebrew/dist/TransomTool
	
	-rm /usr/local/dist/TransomTool
	-cp .build/TransomTool /usr/local/dist/TransomTool

.PHONY: release
release: install docker
	docker pull kittymac/transom:latest
	docker run --platform linux/arm64 --rm -v /tmp/:/outTemp kittymac/transom /bin/bash -lc 'cp /root/Transom/.build/aarch64-unknown-linux-gnu/release/TransomTool /outTemp/TransomTool'
	cp /tmp/TransomTool ./dist/TransomTool.artifactbundle/TransomTool-arm64/bin/TransomTool
	docker run --platform linux/amd64 --rm -v /tmp/:/outTemp kittymac/transom /bin/bash -lc 'cp /root/Transom/.build/x86_64-unknown-linux-gnu/release/TransomTool /outTemp/TransomTool'
	cp /tmp/TransomTool ./dist/TransomTool.artifactbundle/TransomTool-amd64/bin/TransomTool
	
	cp ./dist/TransomTool ./dist/TransomTool.artifactbundle/TransomTool-macos/bin/TransomTool
	rm -f ./dist/TransomTool.zip
	cd ./dist && zip -r ./TransomTool.zip ./TransomTool.artifactbundle

docker:
	-docker buildx create --name local_builder
	-DOCKER_HOST=tcp://192.168.1.198:2376 docker buildx create --name local_builder --platform linux/amd64 --append
	-docker buildx use local_builder
	-docker buildx inspect --bootstrap
	-docker login
	docker buildx build --platform linux/amd64,linux/arm64 --push -t kittymac/transom .

docker-shell:
	docker pull kittymac/transom
	docker run --platform linux/arm64 --rm -it --entrypoint bash kittymac/transom
