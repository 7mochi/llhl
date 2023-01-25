init-linux:
	npm install
	npm run install-linux

init-windows:
	npm install
	npm run install-windows

build-linux:
	npm run build-linux

build-windows:
	npm run build-windows

watch-linux:
	npm run watch-linux

watch-windows:
	npm run watch-windows

clean:
	rm -rf .compiler .thirdparty dist