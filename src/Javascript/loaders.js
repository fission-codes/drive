/*

♪~ ᕕ(ᐛ)ᕗ

*/

function addLoader(node) {
  const a = document.createElement("img")
  a.setAttribute("src", "images/loader-gray.svg")
  a.className = "absolute animation-spin left-1/2 top-1/2 -translate-1/2"
  node.appendChild(a)
}
