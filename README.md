# Fluid

![screenshot](./screenshot.png)

Fluid is a real-time, one-to-one, text-based chat application.
'Real-time' means you'll see what the other user is typing when they message you,
and visa-versa.

The enter application is presented as a single input box in the center of the browser,
and prompts from the application are literally typed into that box.

The user can initiate a chat with another remote user by sharing a unique URL. The application
will prompt the user if they're happy to chat with the remote user before allowing messages to
flow between the two users.

# Technologies Used

- Elm
- Elixir & Phoenix
- Web Sockets

# Install Locally

To start the Phoenix app:

  * Install dependencies with `mix deps.get`
  * Create and migrate with `mix ecto.create && mix ecto.migrate`
  * Install Node.js dependencies with `npm install`
  * Start Phoenix endpoint with `mix phoenix.server`

# Demo

Live demo is available [here](https://fluid-chat.herokuapp.com/), however if running
locally you can visit `localhost:4000` in your browser.

You will be prompted to enter your name (followed by '.'), and then given a new URL
to share with. After you share the url and the remote user enters their name, you'll
be able to chat to them in real time.
