import util from "./util"
import socket from "./socket"
import videojs from "video.js"
import "videojs-youtube"
import uuid from "uuid"
import toastr from "toastr"
import $ from "jquery"
import "bootstrap"

let channel = socket.channel('room:' + window.roomId, {}); // connect to chat "room"

let me = uuid.v1();
let currentVideoUrl = window.initVideo;

function updateVideo(urlPart) {

  if (urlPart === "") return

  console.log("Now playing ID " + urlPart)

  let source = {
    "type": "video/youtube",
    "src": "https://www.youtube.com/watch?v=" + urlPart
  };

  var vidParams = {
    // "fluid": true,
    "fill": true,
    "techOrder": ["youtube"],
    "sources": [source],
    "youtube": {
      "iv_load_policy": 3,
      "modestbranding": 1,
      "origin": "*"
    }
  };

  if (player == null)
    player = videojs('video', vidParams)
  else
    player.src(source)

  currentVideoUrl = urlPart
  player.play()

  updateVideoInfo(currentVideoUrl)
}

function showHistory(entries) {
  let text = "No history."
  if (entries.length) {
    entries = entries.map(x => "<li class='history-entry'>" + x + "</li>")
    text = entries.join("\n")
  }

  $('#history-entries').html(text)
  $('#historyModal').modal()
}

function updateVideoInfo(urlPart) {
  fetch('/api/youtube/info/' + urlPart)
    .then(resp => {
      resp.json()
        .then(json => {
          document.getElementById('curVidTitle').innerText = json.title
          document.getElementById('curVidDescription').innerText = json.description

          util.updateTitle(json.title);
        })
    })
}

function updateVidCount(count) {
  vidcount.innerText = Math.max(0, count);
}

var player = null
updateVideo(window.initVideo)

channel.on('shout', function (payload) { // listen to the 'shout' event
  let li = document.createElement("li"); // create new list item DOM element
  let name = payload.username || 'guest'; // get name from payload or set default
  li.innerHTML = '<span class="text-focus-in"><b class="text-primary">' + name + '</b> <span class="text-secondary">' + payload.message + '</span></span>'; // set li contents
  ul.appendChild(li); // append to list
  ul.scrollTop = ul.scrollHeight - ul.clientHeight;
});

channel.on('addvideo', function (payload) { // listen to the 'shout' event
  let li = document.createElement("li"); // create new list item DOM element
  let name = payload.username || 'guest'; // get name from payload or set default
  li.innerHTML = '<span class="text-focus-in text-success"><b>' + 'A new video was added!' + '</b>'; // set li contents
  ul.appendChild(li); // append to list
  ul.scrollTop = ul.scrollHeight - ul.clientHeight;

  updateVidCount(payload.vidcount)
});

channel.on('video-play', function (payload) {
  updateVidCount(payload.remainingCount)
  updateVideo(payload.newVid.url);
});


channel.join(); // join the channel.


let ul = document.getElementById('msg-list'); // list of messages.
let name = document.getElementById('name'); // name of message sender
let msg = document.getElementById('msg'); // message input field

let btnAddVideo = document.getElementById('btnAddVideo'); // message input field
let inputAddVideo = document.getElementById('inputAddVideo'); // message input field
let vidcount = document.getElementById('vidcount'); // message input field

btnAddVideo.addEventListener('click', function (event) {
  if (inputAddVideo.value.length !== 0) {
    let payload = { // send the message to the server on "shout" channel
      url: inputAddVideo.value,
      host: window.location.hostname + ":" + (window.location.port ? window.location.port : "443")
    }

    if (window.location.hostname.startsWith("localhost"))
      payload.host = "http://localhost:4000"
    else
      payload.host = "https://campfire-sync.herokuapp.com"

    console.log("Add Video Payload: " + JSON.stringify(payload))
    channel
      .push('addvideo', payload)
      .receive("error", (msg) => toastr.error(msg.message))
  }
});

// "listen" for the [Enter] keypress event to send a message:
msg.addEventListener('keypress', function (event) {
  if (event.keyCode == 13 && msg.value.length > 0) { // don't sent empty msg.
    channel.push('shout', { // send the message to the server on "shout" channel
      username: name.value || "Guest", // get value of "name" of person sending the message
      message: msg.value || "I got nothing to say!" // get message text (value) from msg input field.
    });
    msg.value = ''; // reset the message input field for next message.
  }
});

// If username is empty, generate one
if (name.value === "") {
  name.value = "Guest";
}

// Update title to room name
util.updateTitle(document.getElementById('room-name').innerText);

// Video logic
player.ready(() => {
  var playerElem = document.getElementById('video')
  var ignoreNext = false

  var pauseCallback = () => {
    if (!ignoreNext)
      channel.push('vid-pause', {
        originator: me
      });

    ignoreNext = false
  }

  var playCallback = () => {
    if (!ignoreNext)
      channel.push('vid-play', {
        originator: me,
        timestamp: player.currentTime()
      });

    ignoreNext = false
  }

  var endedCallback = () => {
    channel.push('video-ended', {
      oldUrl: currentVideoUrl
    })
  }

  player.on("pause", pauseCallback);
  player.on("ended", endedCallback);

  channel.on('vid-pause', function (payload) {
    if (payload.originator !== me) {
      ignoreNext = true;
      player.pause();
    }
  });

  channel.on('vid-play', function (payload) {
    if (payload.originator !== me) {
      ignoreNext = true;
      player.currentTime(payload.timestamp);
      player.play();
    }
  });

  channel.on('sync-request', function (payload) {
    if (payload.requestor !== me) {
      channel.push('sync-response', {
        isPlaying: !player.paused(),
        timestamp: player.currentTime(),
        requestor: payload.requestor
      })
    }
  });

  channel.on('sync-response', function (payload) {
    if (payload.requestor === me) {
      player.currentTime(payload.timestamp)
      if (player.paused() && payload.isPlaying) {
        ignoreNext = true
        player.play()
      } else if (!player.paused() && !payload.isPlaying) {
        ignoreNext = true
        player.pause()
      }
    }
  });

  player.one("play", () => {
    channel.push('sync-request', {
      requestor: me
    })
    player.on("play", playCallback);
  })

  document.getElementById('btnHistory').addEventListener("click", (e) => {
    fetch('/api/rooms/' + window.roomUuid + '/videos/history')
      .then(resp => {
        resp.json()
          .then(json => {
            showHistory(json.map(x => x.cachedTitle));
          })
      })
  });
})