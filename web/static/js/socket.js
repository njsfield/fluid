import {Socket} from "phoenix"

// Extract user ID & token
const user_token = window.user_token;
const user_id = window.user_id;

// Store pathname if remote 
const remote_path = window.location.pathname.slice(1) || false;

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
    // If remote
    if (remote_path) {
      // Set remote id
      model.remote_id = remote_path;
      // Update state
      model.state = 'MESSAGING REMOTE';
      // Push msg
      channel.push("msg", {name: model.name, remote_id: model.remote_id})   
      // Display output
      output();
    } else {
      // Update url
      window.history.replaceState('', '', '/' + model.user_id)
      // Update state
      model.state = 'READY FOR REMOTE';
      // Display output
      output();
      }
    // On error
    }).receive("error", resp => { console.log("Unable to join", resp) })

// Handle connect (from remote) 
channel.on("msg:connect", msg => {
  // Alert User
  window.alert(msg.name + ' would like to connect. Press ok to conect')
  // Set remote_id
  model.remote_id = msg.remote_id;
  // Set remote name
  model.remote_name = msg.name;
  // Send accept
  channel.push("msg", {name: model.name, remote_id: model.remote_id})
  // Set state
  model.state = "IN CHAT";
  // Output
  output();
})

// Handle accept (from user) 
channel.on("msg:accept", msg => {
  // Alert Remote 
  window.alert(msg.name + ' has accepted')
  // Set remote name
  model.remote_name = msg.name;
  // Send new msg
  channel.push("msg", {body: "hello"})
  // Set state
  model.state = "IN CHAT";
  // Output
  output();
})

// Handle denied (from user)
channel.on("msg:denied", msg => {
  // Alert Remote
  window.alert(msg.name + ' has denied')
  // Reset window url
  window.history.replaceState('', '', '/')
  // Reset remote id
  model.remote_id = "";
  // Reset state
  model.state = "IDLE";
  // Output
  output();
})

// Handle new messages 
channel.on("msg:new", msg => {
  // Simply alert user of message
  window.alert(msg.body)
})

export default socket
