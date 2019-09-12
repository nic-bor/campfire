let btnCreate = document.getElementById('btnCreateRoom'); // message input field
let btnJoin = document.getElementById('btnJoinRoom'); // message input field

btnJoin.addEventListener('click', () => {
  let roomId = document.getElementById('inputRoomId').value
  if (roomId !== "")
    document.location.href = "/rooms/" + roomId
})

btnCreate.addEventListener('click', (event) => {
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