import defaultTheme from "tailwindcss/defaultTheme.js"
import plugin from "tailwindcss/plugin.js"
import * as kit from "fission-kit"


export default {

  theme: {

    // Colors
    // ------

    colors: kit.colors,

    // Fonts
    // -----

    fontFamily: {
      ...defaultTheme.fontFamily,

      body: [ kit.fonts.body, ...defaultTheme.fontFamily.sans ],
      display: [ kit.fonts.display, ...defaultTheme.fontFamily.serif ],
      mono: [ kit.fonts.mono, ...defaultTheme.fontFamily.mono ],
    }
  },

  variants: {},

  plugins: [

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
