import uuid from "uuid"
import {
  Socket
} from "phoenix"


// Initialize the socket and generate a new UUID as the user token (used for example for rate-limiting on server side)
let socket = new Socket("/socket", {
  params: {
    usertoken: uuid.v1()
  }
})

socket.connect()

export default socket