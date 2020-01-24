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
@build: clean css-large html elm javascript-dependencies javascript (_report "Build success")


@build-production:
	just environment=production build css-small

	# TODO: Minify stuff
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
	pnpm install
	{{node_bin}}/snowpack --clean
	curl https://unpkg.com/ipfs@0.40.0/dist/index.js -o web_modules/ipfs.js



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


@javascript:
	echo "⚙️  Copying Javascript"
	cp {{src_dir}}/Javascript/* {{build_dir}}/


@javascript-dependencies:
	echo "⚙️  Copying Javascript Dependencies"
	cp -rf web_modules {{build_dir}}/web_modules/



# Watch
# -----

@watch:
	echo "👀  Watching for changes"
	just watch-css & \
	just watch-html & \
	just watch-js


@watch-css:
	watchexec -p -w {{src_dir}} -f "Css/**/*.css" -- just css & \
	watchexec -p -f "tailwind.config.js" -- just css


@watch-elm:
	watchexec -p -w {{src_dir}} -e "elm" -- just elm


@watch-html:
	watchexec -p -w {{src_dir}} -e "html" -- just html


@watch-js:
	watchexec -p -w {{src_dir}} -e "js" -- just javascript



# Private
# -------

_report msg:
	@echo "🧙‍  {{msg}}"
