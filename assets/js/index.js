let btn = document.getElementById('btnCreateRoom'); // message input field
btn.addEventListener('click', function (event) {
  fetch(
    'http://localhost:4000/api/rooms', {
      method: 'POST'
    }
  ).then(response => {
    response.json()
      .then(json => window.location.href = "/rooms/" + json)
  })
});