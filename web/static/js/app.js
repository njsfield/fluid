// import socket from "./socket"

// Embed main elm app
if (window.Elm && window.user_id) {
  Elm.Main.embed(document.getElementById('main'), {
    user_id: window.user_id,
    socket_url: window.socket_url
  })
}
