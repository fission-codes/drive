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
	{{node_bin}}/terser-folder \
		{{build_dir}} \
		--each --extension .js \
		--pattern "**/*.js, !**/*.min.js" \
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
		--remove-redundant-attributes --remove-script-type-attributes \
		--remove-tag-whitespace --use-short-doctype \
		--minify-css true --minify-js true

	# {{node_bin}}/snowpack --optimize --nomodule


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
		--start-page=index.html \
		-- --output={{build_dir}}/application.js \


@install-deps: (_report "Installing required dependencies")
	yarn install
	# yarn run snowpack
	cp ../get-ipfs/dist/get-ipfs.es5.js web_modules/get-ipfs.js
	mkdir -p web_modules
	curl https://unpkg.com/ipfs@0.41.1/dist/index.js -o web_modules/ipfs.js
	curl https://unpkg.com/multiaddr@7.3.1/dist/index.js -o web_modules/multiaddr.js
	curl https://wzrd.in/debug-standalone/it-to-stream@0.1.1 -o web_modules/it-to-stream.js
	curl https://wzrd.in/debug-standalone/render-media@3.4.0 -o web_modules/render-media.js



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
	elm make {{src_dir}}/Application/Main.elm \
		--output={{build_dir}}/application.js


@html:
	echo "⚙️  Copying HTML"
	cp {{src_dir}}/Static/Html/Application.html {{build_dir}}/index.html
	cp {{build_dir}}/index.html {{build_dir}}/200.html


@images:
	echo "⚙️  Copying Images"
	cp -r node_modules/fission-kit/images/ {{build_dir}}/images/
	cp -r {{src_dir}}/Static/Images/ {{build_dir}}/images/


@javascript:
	echo "⚙️  Copying Javascript"
	cp {{src_dir}}/Javascript/* {{build_dir}}/


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
	just watch-css & \
	just watch-html & \
	just watch-images & \
	just watch-js


@watch-css:
	watchexec -p -w {{src_dir}}/Css -e "css" -- just css-large & \
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
