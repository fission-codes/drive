import autoprefixer from "autoprefixer"
import csso from "postcss-csso"
import fs from "fs"
import elmTailwind from "postcss-elm-tailwind"
import process from "process"
import postcss from "postcss"
import purgecss from "@fullhuman/postcss-purgecss"
import tailwind from "tailwindcss"


// 🏔


import tailwindConfig from "./tailwind.js"

const inputPath = "src/Css/Application.css"
const outputPath = "build/Css/Application.css"

const isProduction = process.env.NODE_ENV === "production"



// FLOW


const flow = [

  tailwind(tailwindConfig),

  // Generate Elm module based on our Tailwind configuration
  // OR: make CSS as small as possible by removing style rules we don't need
  isProduction

  ? purgecss({
    content: [ "./build/**/*.html", "./build/application.js" ],
    defaultExtractor: content => content.match(/[A-Za-z0-9-_:/]+/g) || []
  })

  : elmTailwind({
    elmFile: "src/Library/Tailwind.elm",
    elmModuleName: "Tailwind"
  }),

  // Add vendor prefixes where necessary
  autoprefixer,

  // Minify CSS if needed
  ...(isProduction ? [ csso({ comments: false }) ] : [])

]



// BUILD


fs.readFile(inputPath, (_err, css) => {
  postcss(flow)
    .process(css, { from: inputPath, to: outputPath })
    .then(result => fs.writeFile(outputPath, result.css, () => true))
})
