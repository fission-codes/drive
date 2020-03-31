/*

(~˘▾˘)~

Custom Elements.

*/



// FILE UPLOADING
//
// Instead of working with `File`s in Elm,
// we make Blob URLS and pass those around.


function handleFile(file) {
  return { name: file.name, url: URL.createObjectURL(file) }
}


customElements.define("fs-content-uploader", class extends HTMLInputElement {

  constructor() {
    super()

    this.addEventListener("change", event => {
      const blobs = [ ...event.files ].map(handleFile)
      const blobsEvent = new CustomEvent("changeBlobs", { detail: { blobs } })

      this.dispatchEvent(blobsEvent)
    })
  }

})


customElements.define("fs-drop-zone", class extends HTMLElement {

  constructor() {
    super()

    this.addEventListener("drop", event => {
      const blobs = [ ...event.dataTransfer.files ].map(handleFile)
      const blobsEvent = new CustomEvent("dropBlobs", { detail: { blobs } })

      this.dispatchEvent(blobsEvent)
    })
  }

})
