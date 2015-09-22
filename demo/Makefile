GULP=@./node_modules/.bin/gulp

install:
	@npm install

build: clean install
	$(GULP) build

clean:
	@rm -rf ./build/*

zip: build
	$(GULP) pack

.PHONY: build install clean zip
