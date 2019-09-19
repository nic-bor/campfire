import $ from "jquery"

$('#btnJoinRoom').on('click', () => {

  // Get the room id from the input field and send user there
  let roomId = $('#inputRoomId').val()
  if ((roomId || "") !== "")
    document.location.href = "/rooms/" + roomId
})

$('#btnCreateRoom').on('click', () => {

  // Post the create event. If operation was successful, redirect the user to the newly created room
  fetch(
    '/api/rooms', {
      method: 'POST',
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        name: "New Channel"
      })
    }
  ).then(response => {
    response.json()
      .then(json => window.location.href = "/rooms/" + json)
  })
});