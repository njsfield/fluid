import {Socket} from "phoenix"

// Get window location (includes remote id?)
const path = window.location.pathname.slice(1);
const _combine = Object.assign;

// Append to DOM
const output = (model) => {
  document.querySelector("#output")
    .innerHTML = JSON.stringify(model, null, 2)
}

// 1. Get name
const name = prompt('Enter your name');

// Hold state
const model = {
  name,
  user_id: "",
  remote_name: '',
  remote_id: path,
  state: 'IDLE'
}

// Create socket, provide name
const socket = new Socket("/socket", {
  params: {name: model.name},
  logger: ((kind, msg, data) => { console.log(`${kind}: ${msg}`, data) })
})

// Initial Connect
socket.connect();

// 1. Connect to initial lobby.
const lobby = socket.channel("user:lobby", {})
lobby.join()
  .receive("ok", resp => {
    // Receive unique id & store
    model.user_id = resp.user_id;
    // Call next join function
    joinUnique(model.user_id)
    // Handle error
    }).receive("error", resp => { console.log("Unable to join", resp) })

// 2. Connect to unique topic
const joinUnique = (user_id) => {
  // Set unique channel (with payload if remote)
  const unique = socket.channel(`user:${model.user_id}`, path ? {remote_id: path} : {})
  // Join unique
  unique.join()
    .receive("ok", resp => {
      if (!path) {
        // No pathname, waiting
        model.state = 'READY FOR SOMEONE TO JOIN'
        window.history.replaceState('', '', '/'+model.user_id)
      } else {
        // Pathname in browser, ttempting to join
        model.state = 'ATTEMPTING TO JOIN';
      }
      // Update view
      output(model);
    }).receive("error", resp => { console.log("Unable to join", resp) })

    // Handle accept message
    unique.on("handle:accept", msg => {
      console.log('accepted yeaahhh')
      model.remote_name = msg.name;
      model.state = "ACCEPTED";
      // Update view
      output(model);
    })

    // Handle denied message
    unique.on("handle:denied", msg => {
      model.state = "DENIED";
      // Update view
      output(model);
    })

    // Prompt for new chat?
    unique.on("connect", msg => {
      window.alert(msg.name + ' would like to chat. Click ok to chat with them')
      // Overide this for testing
      const decision = "yes";
      // If yes then push accept message
      if (/y(es)?/i.test(decision)) {
        // If yes, store their details
        model.remote_name = msg.name;
        model.remote_id = msg.remote_id;
        model.state = "ACCEPTED"
        // Notify them
        unique.push("request:accept", {remote_id: msg.remote_id, name: model.name})
        // Update view
        output(model);
      } else {
        unique.push("request:denied", "")
      }
    });
}

export default socket
