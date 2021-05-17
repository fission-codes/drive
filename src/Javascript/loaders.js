/*

♪~ ᕕ(ᐛ)ᕗ

*/

function addLoader(node, contents) {
  const a = document.createElement("img")
  a.setAttribute("src", "images/loader-gray.svg")
  a.className = "animate-spin"

  const c = document.createElement("div")
  c.className = "italic mt-3"
  c.innerHTML = contents

  const w = document.createElement("div")
  w.className = "absolute flex flex-col items-center left-1/2 top-1/2 transform -translate-x-1/2 -translate-y-1/2"
  w.appendChild(a)
  w.appendChild(c)

  node.appendChild(w)
}
