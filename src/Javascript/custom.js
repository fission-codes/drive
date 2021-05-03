/*

(~˘▾˘)~

Custom Elements.

*/



// FILE UPLOADING
//
// Instead of working with `File`s in Elm,
// we make Blob URLS and pass those around.


function reducePromises(fn, list) {
  return Promise
    .all(list.map(fn))
    .then(a => a.flat())
}


function handleEntry(entry) {
  return new Promise(resolve => {
    if (!entry) {
      console.error("Dropzone issue, got `null` entry")
      resolve([])

    } else if (entry.isDirectory) {
      entry.createReader().readEntries(entries => {
        // Handle directories recursively
        reducePromises(handleEntry, entries).then(resolve)
      })

    } else {
      entry.file(file => {
        resolve([ handleFile(file, entry.fullPath) ])
      })

    }
  })
}


function handleFile(file, path) {
  return {
    path: (typeof path === "string" && path.replace(/^\//, ""))
      || file.webkitRelativePath
      || file.name,
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
      if (!event.dataTransfer.items || !event.dataTransfer.files) {
        console.error("Browser doesn't support this method of uploading files.")
        return
      }

      event.preventDefault()

      const useItems = !!event.dataTransfer.items.length
      const useFiles = !!event.dataTransfer.files.length

      reducePromises(
        item => handleEntry(item.webkitGetAsEntry()),
        Array.from(
          useItems
          ? event.dataTransfer.items
          : event.dataTransfer.files
        )

      ).then(blobs => {
        const blobsEvent = new CustomEvent("dropBlobs", { detail: { blobs } })
        this.dispatchEvent(blobsEvent)

      })
    })
  }

}


customElements.define("fs-content-uploader", ContentUploader)
customElements.define("fs-drop-zone", DropZone)
