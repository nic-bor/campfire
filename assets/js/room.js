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
let currentVideoUrl = window.initVideo.url;

function updateVideo(video) {

  let urlPart = video.url
  if (urlPart === "") return

  console.log("Now playing ID " + urlPart)

  let source = {
    "type": "video/youtube",
    "src": "https://www.youtube.com/watch?v=" + urlPart
  };

  var vidParams = {
    // "fluid": true,
    "fill": true,
    "poster": "/",
    "techOrder": ["youtube"],
    "sources": [source],
    "youtube": {
      "iv_load_policy": 3,
      "modestbranding": 1,
      "origin": "*"
    }
  };

  currentVideoUrl = urlPart
  if (player == null) {
    player = videojs('video', vidParams)
    player.ready(() => {
      player.play()
    });
  } else {
    // player.reset()
    player.src(source)
    player.load()
    player.ready(() => {
      player.pause();
      setTimeout(() => {
        player.pause();
        player.currentTime(0);
        player.play();
      }, 2000)
    })
  }

  updateVideoInfo(video)
  util.updateTitle(video.cachedTitle);
}

function showHistory(entries) {
  let text = "No history."
  if (entries.length) {
    entries.sort((o1, o2) => new Date(o1.date) - new Date(o2.date))
    entries = entries.map((x, i) => (i + 1) + ". " + x.title + " (ID: " + x.url + ")")
    text = entries.join("\n")
  }

  $('#history-entries').val(text)
  $('#historyModal').modal()
}

function updateVideoInfo(video) {
  $('#curVidTitle').text(video.cachedTitle)
  $('#curVidDescription').text(video.cachedDescription)
}

function updateVidCount(count) {
  vidcount.text(Math.max(0, count));
}

var player = null
updateVideo(window.initVideo)

channel.on('shout', function (payload) { // listen to the 'shout' event
  let li = document.createElement("li"); // create new list item DOM element
  let name = payload.username || 'guest'; // get name from payload or set default
  let nameSan = util.sanitizeHTML(name);
  let messageSan = util.sanitizeHTML(payload.message);
  li.innerHTML = '<span class="text-focus-in"><b class="text-primary">' + nameSan + '</b> <span class="text-secondary">' + messageSan + '</span></span>'; // set li contents
  ul.appendChild(li); // append to list
  ul.scrollTop = ul.scrollHeight - ul.clientHeight;
});

channel.on('addvideo', function (payload) { // listen to the 'shout' event
  let li = document.createElement("li"); // create new list item DOM element
  let name = payload.username || 'guest'; // get name from payload or set default

  let time = new Date().toLocaleTimeString('de-DE', {
    hour12: false,
    hour: "numeric",
    minute: "numeric"
  });

  li.innerHTML = '<span class="text-focus-in text-success">(' + time + ') <b>' + name + ' added a video!' + '</b>'; // set li contents
  ul.appendChild(li); // append to list
  ul.scrollTop = ul.scrollHeight - ul.clientHeight;

  updateVidCount(payload.vidcount)
});

channel.on('video-play', function (payload) {
  console.log("received video-play with payload " + JSON.stringify(payload))
  updateVidCount(payload.remainingCount)
  updateVideo(payload.newVid);
});


channel.join(); // join the channel.


let ul = document.getElementById('msg-list'); // list of messages.
let name = document.getElementById('name'); // name of message sender
let msg = $('#msg'); // message input field

let btnAddVideo = $('#btnAddVideo'); // message input field
let inputAddVideo = $('#inputAddVideo'); // message input field
let vidcount = $('#vidcount'); // message input field

btnAddVideo.on('click', function (event) {
  if (inputAddVideo.val().length !== 0) {
    let payload = { // send the message to the server on "shout" channel
      url: inputAddVideo.val(),
      host: window.location.hostname + ":" + (window.location.port ? window.location.port : "443"),
      username: $('#name').val()
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
msg.on('keypress', function (event) {
  if (event.keyCode == 13 && msg.val().length > 0) { // don't sent empty msg.
    channel.push('shout', { // send the message to the server on "shout" channel
      username: name.value || "Guest", // get value of "name" of person sending the message
      message: msg.val() || "I got nothing to say!" // get message text (value) from msg input field.
    });
    msg.val(""); // reset the message input field for next message.
  }
});

// If username is empty, generate one
if (name.value === "") {
  name.value = "Guest";
}

// Video logic
player.ready(() => {
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
    console.log("received vid-play with payload " + JSON.stringify(payload))
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

  $('#btnHistory').on("click", (e) => {
    fetch('/api/rooms/' + window.roomUuid + '/videos/history')
      .then(resp => {
        resp.json()
          .then(json => {
            showHistory(
              json.map(x => ({
                title: x.cachedTitle,
                url: x.url,
                date: new Date(x.inserted_at)
              })));
          });
      });
  });
})