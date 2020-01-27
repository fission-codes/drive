import defaultTheme from "tailwindcss/defaultTheme.js"
import gradients from "tailwindcss-gradients"
import plugin from "tailwindcss/plugin.js"
import * as kit from "fission-kit"


export default {

  /////////////////////////////////////////
  // THEME ////////////////////////////////
  /////////////////////////////////////////

  theme: {

    // Colors
    // ------

    colors: {
      ...kit.colors,

      "current-color": "currentColor",
      "near-white": "hsl(240, 33.3%, 96%)",
      "transparent": "transparent"
    },

    // Fonts
    // -----

    fontFamily: {
      ...defaultTheme.fontFamily,

      body: [ kit.fonts.body, ...defaultTheme.fontFamily.sans ],
      display: [ kit.fonts.display, ...defaultTheme.fontFamily.serif ],
      mono: [ kit.fonts.mono, ...defaultTheme.fontFamily.mono ],
    },

    // Gradients
    // ---------
    // https://github.com/benface/tailwindcss-gradients

    linearGradients: theme => {
      const colors = theme("colors")

      return { colors: {
        "gray-100-200": [ colors.gray_100, colors.gray_200 ],
      }}
    },

  },


  /////////////////////////////////////////
  // VARIANT //////////////////////////////
  /////////////////////////////////////////

  variants: {

    borderWidth: [ "first", "last" ],

  },


  /////////////////////////////////////////
  // PLUGINS //////////////////////////////
  /////////////////////////////////////////

  plugins: [

    gradients(),

    // Add text-decoration-color classes
    plugin(function ({ addUtilities, variants, theme }) {
      const colors = theme("colors", {})
      const utilities = Object.keys(colors).reduce((acc, k) => {
        return { ...acc, [`.tdc-${k}`]: { textDecorationColor: colors[k] }}
      }, {})

      addUtilities(utilities, [])
    })

  ]

}
