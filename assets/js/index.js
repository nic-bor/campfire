let btn = document.getElementById('btnCreateRoom'); // message input field

btn.addEventListener('click', function (event) {
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