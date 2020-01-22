const process = require("process")
const csso = require("postcss-csso")
const elmTailwind = require("postcss-elm-tailwind")
const purgecss = require("@fullhuman/postcss-purgecss")({

  // Specify the paths to all of the template files in your project
  content: [ "./build/**/*.html", "./build/application.js" ],

  // Include any special characters you're using in this regular expression
  defaultExtractor: content => content.match(/[A-Za-z0-9-_:/]+/g) || []

})


const isProduction = (process.env.NODE_ENV === "production")


module.exports = {
  plugins: [

    require("tailwindcss"),

    // Generate Elm module based on our Tailwind configuration
    // OR: make CSS as small as possible by removing style rules we don't need
    isProduction

    ? purgecss

    : elmTailwind({
      elmFile: "src/Library/Tailwind.elm",
      elmModuleName: "Tailwind"
    }),

    // Add vendor prefixes where necessary
    require("autoprefixer"),

    // Minify CSS if needed
    ...(isProduction ? [ csso({ comments: false }) ] : [])

  ]
}
