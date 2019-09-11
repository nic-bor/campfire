let btn = document.getElementById('btnCreateRoom'); // message input field
btn.addEventListener('click', function (event) {
  fetch(
    '/api/rooms', {
      method: 'POST'
    }
  ).then(response => {
    response.json()
      .then(json => window.location.href = "/rooms/" + json)
  })
});