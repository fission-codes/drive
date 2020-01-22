
# Variables
# ---------

build_dir 	:= "./build"
node_bin 		:= "./node_modules/.bin"
src_dir 		:= "./src"

environment := "dev"



# Tasks
# -----

@default: dev
@build: clean css-large html elm javascript (_report "Build success")


@build-production:
	just environment=production build css-small
	# TODO: Minify stuff


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



# Parts
# -----

@css-large:
	echo "⚙️  Compiling CSS & Elm Tailwind Module"
	mkdir -p {{src_dir}}/Library
	{{node_bin}}/postcss {{src_dir}}/Css/Application.css \
		--output {{build_dir}}/application.css


@css-small:
	echo "⚙️  Compiling Minified CSS"
	NODE_ENV=production {{node_bin}}/postcss {{src_dir}}/Css/Application.css \
		--output {{build_dir}}/application.css


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



# Watch
# -----

@watch:
	echo "👀  Watching for changes"
	just watch-css & \
	just watch-html


@watch-css:
	watchexec -p -w {{src_dir}} -f "Css/**/*.css" -- just css & \
	watchexec -p -f "tailwind.config.js" -- just css


@watch-html:
	watchexec -p -w {{src_dir}} -e "html" -- just html


@watch-elm:
	watchexec -p -w {{src_dir}} -e "elm" -- just elm



# Private
# -------

_report msg:
	@echo "🧙‍  {{msg}}"
