function addLoaders(node) {
  const a = document.createElement("img")
  a.setAttribute("src", "images/loader-dark.svg")
  a.className = "absolute animation-spin left-1/2 top-1/2 -translate-1/2 dark:hidden"
  node.appendChild(a)

  const b = document.createElement("img")
  b.setAttribute("src", "images/loader-light.svg")
  b.className = "absolute animation-spin hidden left-1/2 top-1/2 -translate-1/2 dark:block"
  node.appendChild(b)
}
