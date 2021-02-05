{pkgs}:
  let
    dist_dir         = "./build";
    node_modules_bin = "./node_modules/.bin";
    src_dir				 	 = "./src";

    ###

    config					= "default";
    fission_cmd     = "fission";
    workbox_config 	= "workbox.config.cjs";

    ###

    devd            = "#{pkgs.devd}/bin/devd";
    elm             = "${pkgs.elmPackages.elm}/bin/elm";
    elm-format      = "${pkgs.elmPackages.elm-format}/bin/elm-format";
    elm-live        = "${pkgs.elmPackages.elm-live}/bin/elm-live";
    node            = "${pkgs.nodejs-14_x}/bin/node";
    pnpm            = "${pkgs.nodePackages.pnpm}/bin/pnpm";
    pnpx            = "${pkgs.nodePackages.pnpm}/bin/pnpx";
    watchexec       = "${pkgs.watchexec}/bin/watchexec";

    ###

    task = name: body:
      let
        package =
          pkgs.writeScriptBin name ''
            #!${pkgs.stdenv.shell}
            echo "⚙️  Running ${name}..."
            ${body}
          '';

        bin = "${package}/bin/${name}";
      in
        { package = package;
          bin     = bin;
        };

    ##

    run = task "run" "${dev-server.bin} & ${watch.bin}";

    hot = task "hot" "${hot-server.bin} & ${watch-hot.bin}";

    apply-config = task "apply-config" ''
      echo "🎛  Applying config \`config/${config}.json\`"
      ${node_modules_bin}/mustache config/${config}.json ${dist_dir}/index.html > ${dist_dir}/index.applied.html
      rm ${dist_dir}/index.html
      mv ${dist_dir}/index.applied.html ${dist_dir}/index.html

      ${node_modules_bin}/mustache config/${config}.json ${dist_dir}/reception/index.html > ${dist_dir}/reception/index.applied.html
      rm ${dist_dir}/reception/index.html
      mv ${dist_dir}/reception/index.applied.html ${dist_dir}/reception/index.html
    '';

    clean = task "clean" ''
      rm -rf ${dist_dir}
      mkdir -p ${dist_dir}
    '';

    dev-build = task "dev-build" ''
      ${clean.bin} \
      ${css-large.bin} \
      ${html.bin} \
      ${apply-config.bin} \
      ${elm-dev.bin} \
      ${javascript-dependencies.bin} \
      ${javascript.bin} \
      ${images.bin} \
      ${static.bin} \
      ${service-worker.bin} && \
      echo "Build success"
    '';

    dev-server = task "dev-server" ''
      echo "🤵  Start a web server at http://localhost:8000"
      ${devd} --quiet build --port=8000 --all
    '';

    download-web-module = task "download-web-module" ''
      # $1: filename, $2: url
      echo $2 "↘️ " $1
      curl --silent --show-error --fail -o web_modules/$1 $2
    '';

    elm-housekeeping = task "elm-housekeeping" ''
      echo "🧹  Running elm-impfix"
      ${node_modules_bin}/elm-impfix "${src_dir}/**/*.elm" --replace
      echo "🧹  Running elm-format"
      ${elm-format} ${src_dir} --yes
    '';

    hot-server = task "hot-server" ''
      echo "🔥  Start a hot-reloading elm-live server at http://localhost:8000"
      ${elm-live} ${src_dir}/Application/Main.elm --hot --port=8000 --pushstate --dir=build -- --output=${dist_dir}/application.js --debug
    '';

    install-deps = task "install-deps" ''
      echo "Installing required dependencies"

      ${pnpm} install

      rm -rf web_modules
      mkdir -p web_modules

      # Download other dependencies
      ${download-web-module.bin} is-ipfs.js https://unpkg.com/is-ipfs@1.0.3/dist/index.js
      ${download-web-module.bin} tocca.js https://unpkg.com/tocca@2.0.9/Tocca.js
      ${download-web-module.bin} it-to-stream.min.js https://bundle.run/it-to-stream@0.1.2
      ${download-web-module.bin} render-media.min.js https://bundle.run/render-media@3.4.3

      # Elm git dependencies
      ${node_modules_bin}/elm-git-install

      # SDK
      cp node_modules/webnative/index.es5.js web_modules/webnative.js
      cp node_modules/webnative/index.umd.js web_modules/webnative.umd.js
    '';


    builders = ''
        ${clean.bin} \
        ${css-large.bin} \
        ${html.bin} \
        ${apply-config.bin} \
        ${elm-production.bin} \
        ${javascript-dependencies.bin} \
        ${javascript.bin} \
        ${images.bin} \
        ${static.bin} \
        ${css-small.bin} \
        ${javascript-minify.bin} \
        ${javascript-nomodule.bin} \
        ${html-minify.bin} \
        ${production-service-worker.bin}
    '';

    production-build = task "production-build" "config=production ${builders}";
    staging-build    = task "staging-build"    builders;

    # Parts
    # -----

    css-large = task "css-large" ''
      echo "⚙️  Compiling CSS & Elm Tailwind Module"
      ${pnpx} etc ${src_dir}/Css/Application.css \
        --config tailwind.js \
        --elm-path ${src_dir}/Library/Tailwind.elm \
        --output ${dist_dir}/application.css \
        --post-plugin-before postcss-import
    '';

    css-small = task "css-small" ''
      echo "⚙️  Compiling Minified CSS"
      NODE_ENV=production ${pnpx} etc ${src_dir}/Css/Application.css \
        --config tailwind.js \
        --output ${dist_dir}/application.css \
        --post-plugin-before postcss-import \
        \
        --purge-content ${dist_dir}/**/*.html \
        --purge-content ${dist_dir}/application.js \
        --purge-content ${src_dir}/Javascript/loaders.js
    '';

    elm-dev = task "elm-dev" ''
      echo "⚙️  Compiling Elm"
      ${elm} make ${src_dir}/Application/Main.elm --output=${dist_dir}/application.js --debug
    '';

    elm-production = task "elm-production" ''
      echo "⚙️  Compiling Elm (optimised)"
      ${elm} make ${src_dir}/Application/Main.elm --output=${dist_dir}/application.js --optimize
    '';

    html = task "html" ''
      echo "⚙️  Copying HTML"
      cp ${src_dir}/Static/Html/Application.html ${dist_dir}/index.html
      cp ${dist_dir}/index.html ${dist_dir}/200.html

      mkdir -p ${dist_dir}/reception
      cp ${src_dir}/Static/Html/Reception.html ${dist_dir}/reception/index.html
    '';

    html-minify = task "html-mionify" ''
      echo "⚙️  Minifying HTML Files"
      ${node_modules_bin}/html-minifier-terser \
        --input-dir ${dist_dir} \
        --output-dir ${dist_dir} \
        --file-ext html \
        \
        --collapse-whitespace --remove-comments --remove-optional-tags \
        --remove-redundant-attributes \
        --remove-tag-whitespace --use-short-doctype \
        --minify-css true --minify-js true
    '';

    images = task "images" ''
      echo "⚙️  Copying Images"
      cp -RT node_modules/fission-kit/images/ ${dist_dir}/images/
      cp -RT ${src_dir}/Static/Images/ ${dist_dir}/images/
    '';

    javascript = task "javascript" ''
      echo "⚙️  Copying Javascript"
      cp ${src_dir}/Javascript/* ${dist_dir}/
      touch ${dist_dir}/nomodule.min.js
    '';

    javascript-dependencies = task "javascript-dependencies" ''
      echo "⚙️  Copying Javascript Dependencies"
      cp -RT web_modules ${dist_dir}/web_modules/
    '';

    javascript-minify = task "javascript-minify" ''
      echo "⚙️  Minifying Javascript Files"
      ${node}/terser-dir \
        ${dist_dir} \
        --each --extension .js \
        --patterns "**/*.js, !**/*.min.js" \
        --pseparator ", " \
        --output ${dist_dir} \
        -- --compress --mangle
    '';

    javascript-nomodule = task "javascript-nomodule" ''
      echo "⚙️  Creating a nomodule build"
      ${node}/esbuild \
        --bundle \
        --minify \
        --outfile=${dist_dir}/nomodule.min.js \
        ${dist_dir}/index.js
    '';

    static = task "static" ''
      echo "⚙️  Copying more static files"
      cp -RT ${src_dir}/Static/Meta/ ${dist_dir}/

      mkdir -p ${dist_dir}/fonts/
      cp node_modules/fission-kit/fonts/**/*.woff2 ${dist_dir}/fonts/
      cp ${src_dir}/Static/Fonts/Nunito/*.woff2 ${dist_dir}/fonts/
    '';

    # Deploy
    # ------
    # This assumes .fission.yaml.production
    #              .fission.yaml.staging

    deploy-production = task "deploy-staging" ''
        echo "🛳  Deploying to production"
        production-build
        cp fission.yaml.production fission.yaml
        ${fission_cmd} up
        rm fission.yaml
    '';

    deploy-staging = task "deploy-staging" ''
      echo "🛳  Deploying to staging"
      ${staging-build.bin}
      cp fission.yaml.staging fission.yaml
      ${fission_cmd} up
      rm fission.yaml
    '';

   # Service worker
   # --------------

   service-worker = task "service-worker" ''
     echo "⚙️  Generating service worker"
     NODE_ENV=development ${pnpx} workbox generateSW ${workbox_config}
   '';

   production-service-worker = task "production-service-worker" ''
     echo "⚙️  Generating service worker"
     NODE_ENV=production ${pnpx} workbox generateSW ${workbox_config}
   '';

   # Watch
   # -----
   #
   watch = task "watch" ''
    echo "👀  Watching for changes"
    ${watch-css-src.bin} & \
    ${watch-css-sys.bin} & \
    ${watch-elm.bin} & \
    ${watch-html.bin} & \
    ${watch-images.bin} & \
    ${watch-js.bin}
   '';

   watch-hot = task "watch-hot" ''
     echo "👀  Watching for changes"
     ${watch-css-src.bin} & \
     ${watch-css-sys.bin} & \
     ${watch-html.bin} & \
     ${watch-images.bin} & \
     ${watch-js.bin}
   '';

   watch-css-src = task "watch-css-src" ''
     ${watchexec} -p -w ${src_dir}/Css -e "css" -- ${css-large.bin}
   '';

   watch-css-sys = task "watch-css-sys" ''
     ${watchexec} -p -w "./tailwind.js" -- ${css-large.bin}
   '';

   watch-elm = task "watch-elm" ''
     ${watchexec} -p -w ${src_dir} -e "elm" -- ${elm-dev.bin}
   '';

   watch-html = task "watch-html" ''
    ${watchexec} -p -w ${src_dir} -e "html" -- html apply-config
   '';

   watch-images = task "watch-images" ''
     ${watchexec} -p -w ${src_dir}/Static/Images -- images
   '';

   watch-js = task "watch-js" ''
     ${watchexec} -p -w ${src_dir} -e "js" -- javascript
   '';

  in
    map (e: e.package) [
      run

      hot
      hot-server

      install-deps
      apply-config
      clean

      dev-build
      dev-server

      download-web-module

      elm-housekeeping

      production-build
      staging-build

      deploy-production
      deploy-staging

      service-worker
      production-service-worker

      watch
      watch-hot
      watch-css-src
      watch-css-sys
      watch-elm
      watch-html
      watch-images
      watch-js
    ]
