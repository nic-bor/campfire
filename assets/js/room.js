import util from "./util"
import socket from "./socket"
import videojs from "video.js"
import moment from "moment"
import "videojs-youtube"
import uuid from "uuid"
import toastr from "toastr"
import $ from "jquery"
import "bootstrap"

let channel = socket.channel('room:' + window.roomId, {}); // connect to chat "room"

let me = uuid.v1();
let currentVideoUrl = window.initVideo.url;
var enableForwarding = true;

function updateVideo(video) {

  // A new video was initiated, disable auto-forwarding until the new one is loaded
  util.logInfo("updating video to " + video.url + " and disabling forwarding")
  enableForwarding = false;
  let urlPart = video.url
  if (urlPart === "") return

  util.logInfo("Now playing ID " + urlPart)

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
      enableForwarding = true;
    });
  } else {
    player.src(source)
    player.load()
    player.ready(() => {
      player.pause();
      setTimeout(() => {
        player.pause();
        player.currentTime(0);
        player.play();
        // Enable auto-forwarding after 2 seconds of playback
        setTimeout(() => {
          util.logInfo("Re-enabling forwarding")
          enableForwarding = true;
        }, 3500);
      }, 2000)
    })
  }

  updateVideoInfo(video)
  util.updateTitle(video.cachedTitle);
}

function showHistory(entries) {
  let text = "No history."
  if (entries.length) {
    entries.sort((o1, o2) => o1.id - o2.id)
    entries = entries.map((x, i) => `${i + 1}. ${x.title} (${x.url}) - [Added on ${moment(x.inserted_at).format('DD.MM HH:mm')}]`)
    text = entries.join("\n")
  }

  $('#history-entries').val(text)
  $('#historyModal').modal()
}

function updateVideoInfo(video) {
  let title = $('#curVidTitle')
  let description = $('#curVidDescription')
  let details = $('#curVidDetails')

  title.addClass('tracking-out-contract')
  description.addClass('tracking-out-contract')
  details.addClass('tracking-out-contract')

  setTimeout(() => {
    title.text(video.cachedTitle)
    description.text(video.cachedDescription)
    $('#curVidInsertedAt').text(moment(video.inserted_at).format('DD.MM.YYYY HH:mm'))
    $('#curVidID').text(video.url)

    title.removeClass('tracking-out-contract')
    description.removeClass('tracking-out-contract')
    details.removeClass('tracking-out-contract')

    title.addClass('text-focus-in')
    description.addClass('text-focus-in')
    details.addClass('text-focus-in')
  }, 2500)
}

function updateVidCount(count) {
  vidcount.text(Math.max(0, count));
}

var player = null
updateVideo(window.initVideo)

channel.on('shout', function (payload) {
  let li = document.createElement("li");
  let name = payload.username || 'guest';
  let nameSan = util.sanitizeHTML(name);
  let messageSan = util.sanitizeHTML(payload.message);

  let time = new Date().toLocaleTimeString('de-DE', {
    hour12: false,
    hour: "numeric",
    minute: "numeric"
  });

  li.innerHTML = '<span class="text-focus-in msg"><span class="msg-time chat-msg-time"> ' + time + ' </span>' + '<b class="text-primary">' + nameSan + ':</b> <span class="text-secondary">' + messageSan + '</span></span>'; // set li contents
  ul.appendChild(li); // append to list
  ul.scrollTop = ul.scrollHeight - ul.clientHeight;
});

channel.on('addvideo', function (payload) { // listen to the 'shout' event
  let li = document.createElement("li"); // create new list item DOM element
  let name = payload.username || 'guest'; // get name from payload or set default
  let nameSan = util.sanitizeHTML(name);

  let time = new Date().toLocaleTimeString('de-DE', {
    hour12: false,
    hour: "numeric",
    minute: "numeric"
  });

  li.innerHTML = '<span class="text-focus-in msg text-success"><span class="msg-time video-msg-time"> ' + time + ' </span>' + '<b>"' + nameSan + '" added a video!' + '</b></span>'; // set li contents
  ul.appendChild(li); // append to list
  ul.scrollTop = ul.scrollHeight - ul.clientHeight;

  updateVidCount(payload.vidcount)
});

channel.on('video-play', function (payload) {
  util.logInfo("received video-play with payload " + JSON.stringify(payload))
  updateVidCount(payload.remainingCount)
  updateVideo(payload.newVid);

  if (payload.manual) {
    let time = new Date().toLocaleTimeString('de-DE', {
      hour12: false,
      hour: "numeric",
      minute: "numeric"
    });

    let li = document.createElement("li");
    li.innerHTML = '<span class="text-focus-in msg text-warning"><span class="msg-time skip-msg-time"> ' + time + ' </span>' + '<b> Video "' + payload.oldVid.cachedTitle + '" skipped manually by "' + payload.name + '". ' + '</b></span>'; // set li contents
    ul.appendChild(li); // append to list
    ul.scrollTop = ul.scrollHeight - ul.clientHeight;
  }

});


channel.join(); // join the channel.


let ul = document.getElementById('msg-list'); // list of messages.
let name = document.getElementById('name'); // name of message sender
let msg = $('#msg'); // message input field

let btnAddVideo = $('#btnAddVideo'); // message input field
let inputAddVideo = $('#inputAddVideo'); // message input field
let vidcount = $('#vidcount'); // message input field

btnAddVideo.on('click', function (event) {

  let addName = name.value.trim();
  if (addName === "") {
    toastr.error('Please enter a name to add videos!')
    return;
  }

  if (inputAddVideo.val().trim().length !== 0) {
    let payload = { // send the message to the server on "shout" channel
      url: inputAddVideo.val().trim(),
      host: window.location.hostname + ":" + (window.location.port ? window.location.port : "443"),
      username: addName
    }

    if (window.location.hostname.startsWith("localhost"))
      payload.host = "http://localhost:4000"
    else
      payload.host = "https://campfire-sync.herokuapp.com"

    util.logInfo("Add Video Payload: " + JSON.stringify(payload))
    channel
      .push('addvideo', payload)
      .receive("error", (msg) => toastr.error(msg.message))
  }
});

// "listen" for the [Enter] keypress event to send a message:
msg.on('keypress', function (event) {
  if (event.keyCode == 13 && msg.val().length > 0) { // don't sent empty msg.

    let addName = name.value.trim();
    if (addName === "") {
      toastr.error('Please enter a name to chat!')
      return;
    }

    channel.push('shout', { // send the message to the server on "shout" channel
      username: addName || "Guest", // get value of "name" of person sending the message
      message: msg.val() || "I got nothing to say!" // get message text (value) from msg input field.
    });
    msg.val(""); // reset the message input field for next message.
  }
});

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
    util.logInfo("endedCallback called, checking if forwarding enabled..")
    if (enableForwarding) {
      util.logInfo("forwarding enabled, pushing video-ended for video url " + currentVideoUrl)
      channel.push('video-ended', {
        oldUrl: currentVideoUrl,
        manual: false
      })
    } else
      util.logWarn("forwarding not enabled, not pushing video-ended - this means a potential skip was prevented")
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
    util.logInfo("received vid-play with payload " + JSON.stringify(payload))
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
                id: x.id,
                inserted_at: x.inserted_at
              })));
          });
      });
  });

  $('#btnSkipCurrent')
    .on("click", (e) => {
      channel.push('video-ended', {
        oldUrl: currentVideoUrl,
        manual: true,
        name: name.value || "Guest"
      })
    })
})