import defaultTheme from "tailwindcss/defaultTheme.js"
import plugin from "tailwindcss/plugin.js"
import * as kit from "@fission-suite/kit"


export default {

  /////////////////////////////////////////
  // THEME ////////////////////////////////
  /////////////////////////////////////////

  theme: {

    // Colors
    // ------

    colors: {
      ...kit.dasherizeObjectKeys(kit.colors),

      "white-05": "rgba(255, 255, 255, 0.05)",

      "inherit": "inherit",
      "transparent": "transparent"
    },

    // Fonts
    // -----

    fontFamily: {
      ...defaultTheme.fontFamily,

      body: [ kit.fonts.body, ...defaultTheme.fontFamily.sans ],
      display: [ "Nunito", kit.fonts.display, ...defaultTheme.fontFamily.serif ],
      mono: [ kit.fonts.mono, ...defaultTheme.fontFamily.mono ],
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
      "025": ".025",
      "05": ".05",
      "075": ".075",
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
    },

    // Extensions
    // ==========

    extend: {

      fontSize: {
        "tiny": "0.8125rem" // between `xs` and `sm`
      },

      screens: {
        dark: { raw: '(prefers-color-scheme: dark)' }
      },

      boxShadow: {
        "inner-outline": "inset 0 0 0 2px rgba(100, 70, 250, .2)", // purple 20%
        "outline": "0 0 0 2px rgba(100, 70, 250, 0.4)", // purple 40%
      },

    },

  },


  /////////////////////////////////////////
  // VARIANTS /////////////////////////////
  /////////////////////////////////////////

  variants: {

    backgroundColor: [ "focus", "group-hover", "hover", "disabled", "responsive", "active" ],
    backgroundOpacity: [ "disabled" ],
    borderColor: [ "first", "focus", "group-hover", "hover", "last", "responsive" ],
    borderWidth: [ "first", "last" ],
    margin: [ "first", "last", "responsive" ],
    opacity: [ "disabled", "group-hover", "responsive" ],
    pointerEvents: [ "group-hover" ],
    textColor: [ "disabled", "responsive", "focus", "hover", "active" ],

  },


  /////////////////////////////////////////
  // PLUGINS //////////////////////////////
  /////////////////////////////////////////

  plugins: [

    // Add text-decoration-color classes
    plugin(function ({ addUtilities, variants, theme }) {
      const colors = theme("colors", {})
      const classes = Object.keys(colors).map(k => {
        return [ `tdc-${k}`, { textDecorationColor: colors[k] } ]
      })

      const utilities = classes.reduce(
        (acc, [k, v]) => ({ ...acc, [`.${k}`]: v }),
        {}
      )

      const utilitiesDark = {
        [`@media (prefers-color-scheme: dark)`]: classes.reduce(
          (acc, [k, v]) => ({ ...acc, [`.dark__${k}`]: v }),
          {}
        )
      }

      addUtilities([
        utilities,
        utilitiesDark
      ], [])
    })

  ]

}
