import animations from "tailwindcss-animations"
import defaultTheme from "tailwindcss/defaultTheme.js"
import gradients from "tailwindcss-gradients"
import plugin from "tailwindcss/plugin.js"
import * as kit from "fission-kit"


export default {

  /////////////////////////////////////////
  // THEME ////////////////////////////////
  /////////////////////////////////////////

  theme: {

    // Animations
    // ----------

    animations: {
      "spin": {
        from: { transform: "rotate(0deg)" },
        to: { transform: "rotate(360deg)" },
      },
    },

    // Colors
    // ------

    colors: {
      ...kit.colors,

      "current-color": "currentColor",
      "inherit": "inherit",
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
        "gray-200-300": [ colors.gray_200, colors.gray_300 ],
      }}
    },

    // Inset
    // -----

    inset: {
      "auto": "auto",
      "0": 0,
      "1/2": "50%",
      "full": "100%"
    },

    // Opacity
    // -------

    opacity: {
      "0": "0",
      "10": ".1",
      "20": ".2",
      "25": ".25",
      "30": ".3",
      "40": ".4",
      "50": ".5",
      "60": ".6",
      "70": ".7",
      "75": ".75",
      "80": ".8",
      "90": ".9",
      "100": "1",
    }

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

    animations(),
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
