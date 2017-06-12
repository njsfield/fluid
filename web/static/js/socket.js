import {Socket} from "phoenix"

// Extract user ID & token
const user_token = window.user_token;
const user_id = window.user_id;

// Append to DOM
const output = () => {
  document.querySelector("#output")
    .innerHTML = JSON.stringify(model, null, 2)
}

// 1. Get name
const name = prompt('Enter your name');

// Hold state
const model = {
  name,
  user_id,
  remote_name: '',
  remote_id: '',
  state: 'IDLE'
}

// Create socket, provide name & user_id
const socket = new Socket("/socket", {
  params: {name: model.name, user_token},
  logger: ((kind, msg, data) => { console.log(`${kind}: ${msg}`, data) })
})

// Initial Connect
socket.connect();

// 1. Connect to unique token (from user id)
const channel = socket.channel(`user:${model.user_id}`, {})
channel.join()
  .receive("ok", resp => {
    // Set window url
    window.history.replaceState('', '', '/' + model.user_id)
    // Update state
    model.state = 'READY FOR REMOTE';
    // Display output
    output();
    // Handle error
    }).receive("error", resp => { console.log("Unable to join", resp) })

export default socket
