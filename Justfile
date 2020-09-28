export NODE_OPTIONS := "--no-warnings"


# Variables
# ---------

build_dir				:= "./build"
node_bin				:= "./node_modules/.bin"
src_dir					:= "./src"

config					:= "default"



# Tasks
# -----

@default: dev-build
	just dev-server & just watch


@apply-config:
	echo "🎛  Applying config \`config/{{config}}.json\`"
	{{node_bin}}/mustache config/{{config}}.json {{build_dir}}/index.html > {{build_dir}}/index.applied.html
	rm {{build_dir}}/index.html
	mv {{build_dir}}/index.applied.html {{build_dir}}/index.html

	{{node_bin}}/mustache config/{{config}}.json {{build_dir}}/reception/index.html > {{build_dir}}/reception/index.applied.html
	rm {{build_dir}}/reception/index.html
	mv {{build_dir}}/reception/index.applied.html {{build_dir}}/reception/index.html


@clean:
	rm -rf {{build_dir}}
	mkdir -p {{build_dir}}


@dev-build: clean css-large html apply-config elm-dev javascript-dependencies javascript meta images (_report "Build success")


@dev-server:
	echo "🤵  Start a web server at http://localhost:8000"
	devd --quiet build --port=8000 --all


@download-web-module filename url:
	curl --silent --show-error --fail -o web_modules/{{filename}} {{url}}


@elm-housekeeping:
	echo "🧹  Running elm-impfix"
	{{node_bin}}/elm-impfix "{{src_dir}}/**/*.elm" --replace
	echo "🧹  Running elm-format"
	elm-format {{src_dir}} --yes


@install-deps: (_report "Installing required dependencies")
	pnpm install
	mkdir -p web_modules

	# Download other dependencies
	# (note, alternative to wzrd.in → https://bundle.run)
	just download-web-module is-ipfs.js https://unpkg.com/is-ipfs@1.0.3/dist/index.js
	just download-web-module tocca.js https://unpkg.com/tocca@2.0.9/Tocca.js
	just download-web-module it-to-stream.js https://wzrd.in/debug-standalone/it-to-stream@0.1.2
	just download-web-module render-media.js https://wzrd.in/debug-standalone/render-media@3.4.3

	# Elm git dependencies
	{{node_bin}}/elm-git-install

	# SDK
	cp node_modules/webnative/index.es5.js web_modules/webnative.js
	cp node_modules/webnative/index.umd.js web_modules/webnative.umd.js


@production-build:
	just config=production clean css-large html apply-config elm-production javascript-dependencies javascript meta images css-small javascript-minify javascript-nomodule html-minify


@staging-build:
	just clean css-large html apply-config elm-production javascript-dependencies javascript meta images css-small javascript-minify javascript-nomodule html-minify



# Parts
# -----

@css-large:
	echo "⚙️  Compiling CSS & Elm Tailwind Module"
	pnpx etc {{src_dir}}/Css/Application.css \
	  --config tailwind.js \
	  --elm-path {{src_dir}}/Library/Tailwind.elm \
	  --output {{build_dir}}/application.css


@css-small:
	echo "⚙️  Compiling Minified CSS"
	NODE_ENV=production pnpx etc {{src_dir}}/Css/Application.css \
	  --config tailwind.js \
	  --output {{build_dir}}/application.css \
		\
	  --purge-content {{build_dir}}/**/*.html \
	  --purge-content {{build_dir}}/application.js \
		--purge-content {{src_dir}}/Javascript/loaders.js


@elm-dev:
	echo "⚙️  Compiling Elm"
	elm make {{src_dir}}/Application/Main.elm --output={{build_dir}}/application.js --debug


@elm-production:
	echo "⚙️  Compiling Elm (optimised)"
	elm make {{src_dir}}/Application/Main.elm --output={{build_dir}}/application.js --optimize


@html:
	echo "⚙️  Copying HTML"
	cp {{src_dir}}/Static/Html/Application.html {{build_dir}}/index.html
	cp {{build_dir}}/index.html {{build_dir}}/200.html

	mkdir -p {{build_dir}}/reception
	cp {{src_dir}}/Static/Html/Reception.html {{build_dir}}/reception/index.html


@html-minify:
	echo "⚙️  Minifying HTML Files"
	{{node_bin}}/html-minifier-terser \
		--input-dir {{build_dir}} \
		--output-dir {{build_dir}} \
		--file-ext html \
		\
		--collapse-whitespace --remove-comments --remove-optional-tags \
		--remove-redundant-attributes \
		--remove-tag-whitespace --use-short-doctype \
		--minify-css true --minify-js true


@images:
	echo "⚙️  Copying Images"
	cp -RT node_modules/fission-kit/images/ {{build_dir}}/images/
	cp -RT {{src_dir}}/Static/Images/ {{build_dir}}/images/


@javascript:
	echo "⚙️  Copying Javascript"
	cp {{src_dir}}/Javascript/* {{build_dir}}/
	touch {{build_dir}}/nomodule.min.js


@javascript-dependencies:
	echo "⚙️  Copying Javascript Dependencies"
	cp -RT web_modules {{build_dir}}/web_modules/


@javascript-minify:
	echo "⚙️  Minifying Javascript Files"
	{{node_bin}}/terser-dir \
		{{build_dir}} \
		--each --extension .js \
		--patterns "**/*.js, !**/*.min.js" \
		--pseparator ", " \
		--output {{build_dir}} \
		-- --compress --mangle


@javascript-nomodule:
	echo "⚙️  Creating a nomodule build"
	{{node_bin}}/esbuild \
		--bundle \
		--minify \
		--outfile={{build_dir}}/nomodule.min.js \
		{{build_dir}}/index.js


@meta:
	echo "⚙️  Copying Meta files"
	cp -RT {{src_dir}}/Static/Meta/ {{build_dir}}/



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


@watch-css-src:
	watchexec -p -w {{src_dir}}/Css -e "css" -- just css-large


@watch-css-sys:
	watchexec -p --filter "tailwind" -e "js" -- just css-large


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
