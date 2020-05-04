/*

(~˘▾˘)~

Custom Elements.

*/



// FILE UPLOADING
//
// Instead of working with `File`s in Elm,
// we make Blob URLS and pass those around.


function reducePromises(fn, list) {
  return list.reduce(
    (p, x) => p.then(a => fn(x).then(b => [ ...a, ...b ])),
    Promise.resolve([])
  )
}


function handleEntry(entry) {
  return new Promise(resolve => {
    if (entry.isDirectory) {
      entry.createReader().readEntries(entries => {
        // Handle directories recursively
        reducePromises(handleEntry, entries).then(resolve)
      })

    } else {
      entry.file(file => {
        resolve([ handleFile(file) ])
      })

    }
  })
}


function handleFile(file) {
  return {
    path: file.webkitRelativePath || file.name,
    url: URL.createObjectURL(file)
  }
}


class ContentUploader extends HTMLElement {

  connectedCallback() {
    const shadowRoot = this.attachShadow({ mode: "open" })

    // The actual input element
    const inputElement = document.createElement("input")
    inputElement.multiple = true
    inputElement.type = "file"
    inputElement.webkitdirectory = true

    inputElement.style.position = "absolute"
    inputElement.style.top = "-1000px"

    inputElement.addEventListener("change", event => {
      const blobs = [ ...event.target.files ].map(handleFile)
      const blobsEvent = new CustomEvent("changeBlobs", { detail: { blobs } })

      this.dispatchEvent(blobsEvent)
    })

    // Add input element
    shadowRoot.appendChild(inputElement)

    // Pass on click event
    this.addEventListener("click", event => {
      inputElement.click()
    })
  }

}


class DropZone extends HTMLElement {

  constructor() {
    super()

    this.addEventListener("drop", event => {
      if (!event.dataTransfer.items) {
        console.error("Browser doesn't support this method of uploading files.")
        return
      }

      reducePromises(
        item => handleEntry(item.webkitGetAsEntry()),
        Array.from(event.dataTransfer.items)

      ).then(blobs => {
        const blobsEvent = new CustomEvent("dropBlobs", { detail: { blobs } })
        this.dispatchEvent(blobsEvent)

      })
    })
  }

}


customElements.define("fs-content-uploader", ContentUploader)
customElements.define("fs-drop-zone", DropZone)
