/*

(▀̿Ĺ̯▀̿ ̿)

Analytics.

*/

export function setupOnFissionCodes() {
  // Only use analytics on *.fission.codes domains
  if (!location.host.endsWith(".fission.codes")) return

  (function(f, a, t, h, o, m) {
      a[h] = a[h] || function() {
        (a[h].q = a[h].q || []).push(arguments)
      };
    o = f.createElement("script"),
    m = document.head;
    o.async = 1; o.src = t; o.id = "fathom-script";
    m.appendChild(o)
  })(document, window, "https://cdn.usefathom.com/tracker.js", "fathom")
  fathom("set", "siteId", "CBUIQVIJ")
  fathom("set", "spa", "pushstate")
  fathom("trackPageview")
}
