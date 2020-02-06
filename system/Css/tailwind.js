import animations from "tailwindcss-animations"
import defaultTheme from "tailwindcss/defaultTheme.js"
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

      "darkness-below": "hsl(232.7, 20.3%, 11%)",
      "darkness": "hsl(232.7, 20.3%, 12%)",
      "darkness-above": "hsl(232.7, 20.3%, 18%)",

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
    },

    // Extensions
    // ==========

    extend: {

      screens: {
        dark: { raw: '(prefers-color-scheme: dark)' }
      },

    },

  },


  /////////////////////////////////////////
  // VARIANTS /////////////////////////////
  /////////////////////////////////////////

  variants: {

    borderWidth: [ "first", "last" ],
    opacity: [ "group-hover" ],

  },


  /////////////////////////////////////////
  // PLUGINS //////////////////////////////
  /////////////////////////////////////////

  plugins: [

    animations(),

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
