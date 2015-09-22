GULP=@./node_modules/.bin/gulp
DEMO=@cd ./demo/

install:
	@npm install

build: clean install
	$(GULP) build

clean:
	@rm -rf ./build/*

publish: build
	@npm publish

build_demo:
	$(DEMO) && make build

zip_demo:
	$(DEMO) && make zip

.PHONY: build install publish clean build_demo zip_demo
