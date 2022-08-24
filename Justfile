export NODE_OPTIONS := "--no-warnings"


# Variables
# ---------

dist_dir				:= "./build"
node_bin				:= "./node_modules/.bin"
src_dir					:= "./src"

config					:= "default"
fission_cmd     := "fission"
workbox_config 	:= "workbox.config.cjs"



# Tasks
# -----

@default: dev-build
	just dev-server & just watch


@hot:
	just hot-server & just watch-hot


@apply-config: insert-version
	echo "🎛  Applying config \`config/{{config}}.json\`"
	{{node_bin}}/mustache config/{{config}}.json {{dist_dir}}/index.html > {{dist_dir}}/index.applied.html
	rm {{dist_dir}}/index.html
	mv {{dist_dir}}/index.applied.html {{dist_dir}}/index.html

	{{node_bin}}/mustache config/{{config}}.json {{dist_dir}}/reception/index.html > {{dist_dir}}/reception/index.applied.html
	rm {{dist_dir}}/reception/index.html
	mv {{dist_dir}}/reception/index.applied.html {{dist_dir}}/reception/index.html


@clean:
	rm -rf {{dist_dir}}
	mkdir -p {{dist_dir}}


@dev-build: clean css-large html apply-config elm-dev javascript-dependencies javascript images static service-worker (_report "Build success")


@dev-server:
	echo "🤵  Start a web server at http://localhost:8000"
	simple-http-server --port 8000 --try-file {{dist_dir}}/index.html --cors --index --nocache --silent -- build


@download-web-module filename url:
	curl --silent --show-error --fail -o web_modules/{{filename}} {{url}}


@elm-housekeeping:
	echo "🧹  Running elm-impfix"
	{{node_bin}}/elm-impfix "{{src_dir}}/**/*.elm" --replace
	echo "🧹  Running elm-format"
	elm-format {{src_dir}} --yes


@hot-server:
	echo "🔥  Start a hot-reloading elm-live server at http://localhost:8000"
	{{node_bin}}/elm-live {{src_dir}}/Application/Main.elm --hot --port=8000 --pushstate --dir=build -- --output={{dist_dir}}/application.js --debug


@install-deps: (_report "Installing required dependencies")
	pnpm install

	rm -rf web_modules
	mkdir -p web_modules
	mkdir -p web_modules/webnative

	# Download other dependencies
	just download-web-module is-ipfs.js https://unpkg.com/is-ipfs@1.0.3/dist/index.js
	just download-web-module tocca.js https://unpkg.com/tocca@2.0.9/Tocca.js
	just download-web-module it-to-stream.min.js https://bundle.run/it-to-stream@0.1.2
	just download-web-module render-media.min.js https://bundle.run/render-media@4.1.0

	# Elm git dependencies
	{{node_bin}}/elm-git-install

	# SDK
	rsync -r node_modules/webnative/dist/ web_modules/webnative/
	cp node_modules/webnative-elm/src/funnel.js web_modules/webnative-elm.js


@production-build:
	just config=production build


@staging-build:
	just config=default build


@build:
	just config={{config}} clean css-large html apply-config elm-production javascript-dependencies javascript images static css-small javascript-nomodule html-minify production-service-worker



# Parts
# -----

@css-large:
	echo "⚙️  Compiling CSS & Elm Tailwind Module"
	npx etc {{src_dir}}/Css/Application.css \
	  --config tailwind.js \
	  --elm-path {{src_dir}}/Library/Tailwind.elm \
	  --output {{dist_dir}}/application.css \
		--post-plugin-before postcss-import


@css-small:
	echo "⚙️  Compiling Minified CSS"
	NODE_ENV=production npx etc {{src_dir}}/Css/Application.css \
	  --config tailwind.js \
	  --output {{dist_dir}}/application.css \
		--post-plugin-before postcss-import \
		\
	  --purge-content {{dist_dir}}/**/*.html \
	  --purge-content {{dist_dir}}/application.js \
		--purge-content {{src_dir}}/Javascript/loaders.js


@elm-dev:
	echo "⚙️  Compiling Elm"
	elm make {{src_dir}}/Application/Main.elm --output={{dist_dir}}/application.js --debug


@elm-production:
	echo "⚙️  Compiling Elm (optimised)"
	elm make {{src_dir}}/Application/Main.elm --output={{dist_dir}}/application.js --optimize


@html:
	echo "⚙️  Copying HTML"
	cp {{src_dir}}/Static/Html/Application.html {{dist_dir}}/index.html
	cp {{dist_dir}}/index.html {{dist_dir}}/200.html

	mkdir -p {{dist_dir}}/reception
	cp {{src_dir}}/Static/Html/Reception.html {{dist_dir}}/reception/index.html


@html-minify:
	echo "⚙️  Minifying HTML Files"
	{{node_bin}}/html-minifier-terser \
		--input-dir {{dist_dir}} \
		--output-dir {{dist_dir}} \
		--file-ext html \
		\
		--collapse-whitespace --remove-comments --remove-optional-tags \
		--remove-redundant-attributes \
		--remove-tag-whitespace --use-short-doctype \
		--minify-css true --minify-js true


@images:
	echo "⚙️  Copying Images"
	rsync -r node_modules/@fission-suite/kit/images/ {{dist_dir}}/images/
	rsync -r {{src_dir}}/Static/Images/ {{dist_dir}}/images/


insert-version:
	#!/usr/bin/env node
	const fs = require("fs")
	const work = fs.readFileSync("{{workbox_config}}", { encoding: "utf8" })
	const timestamp = Math.floor(Date.now() / 1000).toString()

	fs.writeFileSync(
		"{{dist_dir}}/{{workbox_config}}",
		work.replace("UNIX_TIMESTAMP", timestamp)
	)


@javascript:
	echo "⚙️  Copying Javascript"
	cp {{src_dir}}/Javascript/* {{dist_dir}}/
	touch {{dist_dir}}/nomodule.min.js


@javascript-dependencies:
	echo "⚙️  Copying Javascript Dependencies"
	rsync -r web_modules/ {{dist_dir}}/web_modules/


@javascript-nomodule:
	echo "⚙️  Creating a nomodule build"
	{{node_bin}}/esbuild \
		--bundle \
		--minify \
		--outfile={{dist_dir}}/nomodule.min.js \
		{{dist_dir}}/index.js


@static:
	echo "⚙️  Copying more static files"
	rsync -r {{src_dir}}/Static/Meta/ {{dist_dir}}/

	mkdir -p {{dist_dir}}/fonts/
	cp node_modules/@fission-suite/kit/fonts/**/*.woff2 {{dist_dir}}/fonts/
	cp {{src_dir}}/Static/Fonts/Nunito/*.woff2 {{dist_dir}}/fonts/



# Service worker
# --------------

@service-worker:
	echo "⚙️  Generating service worker"
	NODE_ENV=development npx workbox generateSW {{dist_dir}}/{{workbox_config}}


@production-service-worker:
	echo "⚙️  Generating service worker"
	NODE_ENV=production npx workbox generateSW {{dist_dir}}/{{workbox_config}}



# Watch
# -----

@watch:
	echo "👀  Watching for changes"
	just watch-css-src & \
	just watch-css-sys & \
	just watch-elm & \
	just watch-html & \
	just watch-images & \
	just watch-js


@watch-hot:
	echo "👀  Watching for changes"
	just watch-css-src & \
	just watch-css-sys & \
	just watch-html & \
	just watch-images & \
	just watch-js


@watch-css-src:
	watchexec -p -w {{src_dir}}/Css -e "css" -- just css-large


@watch-css-sys:
	watchexec -p -w "./tailwind.js" -- just css-large


@watch-elm:
	watchexec -p -w {{src_dir}} -e "elm" -- just elm-dev


@watch-html:
	watchexec -p -w {{src_dir}} -e "html" -- just html apply-config


@watch-images:
	watchexec -p -w {{src_dir}}/Static/Images -- just images


@watch-js:
	watchexec -p -w {{src_dir}} -e "js" -- just javascript



# Private
# -------

_report msg:
	@echo "🧙‍  {{msg}}"
