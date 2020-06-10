export NODE_OPTIONS := "--no-warnings"


# Variables
# ---------

build_dir 	:= "./build"
node_bin 		:= "./node_modules/.bin"
src_dir 		:= "./src"
sys_dir			:= "./system"

environment := "dev"



# Tasks
# -----

@default: dev


@build: clean css-large html elm javascript-dependencies javascript meta images (_report "Build success")


@build-production:
	just environment=production build css-small

	echo "⚙️  Minifying Javascript Files"
	{{node_bin}}/terser-dir \
		{{build_dir}} \
		--each --extension .js \
		--patterns "**/*.js, !**/*.min.js" \
		--pseparator ", " \
		--output {{build_dir}} \
		-- --compress --mangle

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

	echo "⚙️  Creating a nomodule build"
	{{node_bin}}/snowpack \
		--dest {{build_dir}}/web_modules \
		--optimize \
		--nomodule {{src_dir}}/Javascript/index.js \
		--nomodule-output nomodule.min.js

	rm {{build_dir}}/web_modules/*.map


@clean:
	rm -rf {{build_dir}}
	mkdir -p {{build_dir}}


@dev: clean build
	just elm-dev & \
	just watch


@elm-dev:
	# Uses https://github.com/wking-io/elm-live
	# NOTE: Uses hot-module reloading
	pnpm run elm-dev -- {{src_dir}}/Application/Main.elm \
		--dir={{build_dir}} \
		--path-to-elm=`which elm` \
		--pushstate \
		--hot \
		--start-page=index.html \
		-- --output={{build_dir}}/application.js \
		--debug


@elm-housekeeping:
	echo "> Running elm-impfix"
	{{node_bin}}/elm-impfix "{{src_dir}}/**/*.elm" --replace
	echo "> Running elm-format"
	elm-format {{src_dir}} --yes


@install-deps: (_report "Installing required dependencies")
	pnpm install
	pnpm run snowpack -- --clean

	# Download non-minified dependencies
	# (note, alternative to wzrd.in → https://bundle.run)
	curl https://unpkg.com/ipfs@0.43.2/dist/index.js -o web_modules/ipfs.js
	curl https://unpkg.com/is-ipfs@1.0.3/dist/index.js -o web_modules/is-ipfs.js
	curl https://unpkg.com/tocca@2.0.9/Tocca.js -o web_modules/tocca.js
	curl https://wzrd.in/debug-standalone/it-to-stream@0.1.1 -o web_modules/it-to-stream.js
	curl https://wzrd.in/debug-standalone/render-media@3.4.0 -o web_modules/render-media.js

	# Elm git dependencies
	{{node_bin}}/elm-git-install

	# For `src/Static/Html/Reception.html`
	cp node_modules/fission-sdk/index.umd.js web_modules/fission-sdk.umd.js



# Parts
# -----

@css-large:
	echo "⚙️  Compiling CSS & Elm Tailwind Module"
	mkdir -p {{src_dir}}/Library
	node {{sys_dir}}/Css/build.js


@css-small:
	echo "⚙️  Compiling Minified CSS"
	NODE_ENV=production node {{sys_dir}}/Css/build.js


@elm:
	echo "⚙️  Compiling Elm"
	if [ "{{environment}}" == "production" ]; then \
		elm make {{src_dir}}/Application/Main.elm --output={{build_dir}}/application.js --optimize ; \
	else \
		elm make {{src_dir}}/Application/Main.elm --output={{build_dir}}/application.js ; \
	fi


@html:
	echo "⚙️  Copying HTML"
	cp {{src_dir}}/Static/Html/Application.html {{build_dir}}/index.html
	cp {{build_dir}}/index.html {{build_dir}}/200.html

	mkdir -p {{build_dir}}/reception
	cp {{src_dir}}/Static/Html/Reception.html {{build_dir}}/reception/index.html



@images:
	echo "⚙️  Copying Images"
	cp -r node_modules/fission-kit/images/ {{build_dir}}/images/
	cp -r {{src_dir}}/Static/Images/ {{build_dir}}/images/


@javascript:
	echo "⚙️  Copying Javascript"
	cp {{src_dir}}/Javascript/* {{build_dir}}/
	touch {{build_dir}}/nomodule.min.js


@javascript-dependencies:
	echo "⚙️  Copying Javascript Dependencies"
	cp -r web_modules {{build_dir}}/web_modules/


@meta:
	echo "⚙️  Copying Meta files"
	cp -p {{src_dir}}/Static/Meta/* {{build_dir}}/



# Watch
# -----

@watch:
	echo "👀  Watching for changes"
	just watch-css-src & \
	just watch-css-sys & \
	just watch-html & \
	just watch-images & \
	just watch-js


@watch-css-src:
	watchexec -p -w {{src_dir}}/Css -e "css" -- just css-large


@watch-css-sys:
	watchexec -p -w {{sys_dir}}/Css -e "js" -- just css-large


@watch-elm:
	watchexec -p -w {{src_dir}} -e "elm" -- just elm


@watch-html:
	watchexec -p -w {{src_dir}} -e "html" -- just html


@watch-images:
	watchexec -p -w {{src_dir}}/Static/Images -- just images


@watch-js:
	watchexec -p -w {{src_dir}} -e "js" -- just javascript



# Private
# -------

_report msg:
	@echo "🧙‍  {{msg}}"
