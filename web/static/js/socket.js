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
    // If remote trying to join user
    if (remote_path) {
      model.remote_id = remote_path;
      model.state = 'MESSAGING REMOTE';
      channel.push("request", {name: model.name, remote_id: model.remote_id})   
      output();
    } else {
      // Set URL 
      window.history.replaceState('', '', '/' + model.user_id)
      window.alert('Please share this url to chat')
      model.state = 'READY FOR REMOTE';
      output();
      }
    // On error
    }).receive("error", resp => {
      console.log("Unable to join", resp)})

// Handle connect (from remote) 
channel.on("request", msg => {
  window.alert(msg.name + ' would like to connect. Press ok to conect')
  model.remote_id = msg.user_id;
  model.remote_name = msg.name;
  channel.push("accept", {name: model.name, remote_id: model.remote_id})
  model.state = "IN CHAT";
  output();
})

// Handle accept (from user) 
channel.on("accept", msg => {
  window.alert(msg.name + ' has accepted')
  model.remote_name = msg.name;
  setTimeout(function(){
    channel.push("msg", {body: "hello"})
  },1000)
  model.state = "IN CHAT";
  output();
})

// Handle deny (from user)
channel.on("deny", msg => {
  resetHandler(msg)
})

// Receive message, reset state
const resetHandler = (msg) => {
  alert(msg.body)
  model.state = "IDLE";
  model.remote_id = "";
  output();
  window.history.replaceState('', '', '/' + model.user_id)
  window.alert('Please share this url to chat')
}

// Handle new messages 
channel.on("msg", msg => {
  window.alert(msg.body)
})

// Handle leave
channel.on("leave", msg => {
  resetHandler(msg) 
})

export default socket
