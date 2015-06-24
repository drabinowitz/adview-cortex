GULP=@./node_modules/.bin/gulp

install:
	@npm install

build: clean install
	$(GULP) build

clean:
	@rm -rf ./build/*

publish: build
	@npm publish

.PHONY: build install publish clean publish
