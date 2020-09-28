/*

♪~ ᕕ(ᐛ)ᕗ

*/

function addLoader(node) {
  const a = document.createElement("img")
  a.setAttribute("src", "images/loader-gray.svg")
  a.className = "animate-spin"

  const w = document.createElement("div")
  w.className = "absolute left-1/2 top-1/2 transform -translate-x-1/2 -translate-y-1/2"
  w.appendChild(a)

  node.appendChild(w)
}
