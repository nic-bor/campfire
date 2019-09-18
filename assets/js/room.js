import util from "./util"
import socket from "./socket"
import videojs from "video.js"
import moment from "moment"
import "videojs-youtube"
import uuid from "uuid"
import toastr from "toastr"
import $ from "jquery"
import "bootstrap"

// The channel used to connect to the server via websocket. The topic is the current room ID which was injected into the view by Phoneix
var channel = socket.channel('room:' + window.roomId, {})

// The video.js element containing the video
var player = null

// Generate a personal identifier used for identifying the originator of certain channel broadcasts
var me = uuid.v1()

// The YouTube ID of the currently playing video - is sent across the channel at several events
var currentVideoUrl = window.initVideo.url

// Controls whether pushing "vid-ended" events is currently enabled.
// Acts as a cooldown to prevent the client from continuously auto-forwarding videos
var enableForwarding = true

// Good-enough workaround for the video player's event architecture.
// When we receive play/pause events from other clients, we want to forward these to our local player accordingly.
// However, when triggering for example video.play(), this will itself trigger the "play"-event of the video element, which causes a push of video-continue over the channel..etc.
// This bool is used as a marker to ignore the next video.on('play') event for such cases to prevent such event flooding.
var ignoreNext = false

// Resets the video player with the given video and updates visual elements such as the video title and description
function updateVideo(video) {

  // A new video was initiated, disable auto-forwarding until the new one is loaded
  util.logInfo("updating video to " + video.url + " and disabling forwarding")
  enableForwarding = false

  // Break if no url was provided
  let urlPart = video.url
  if (urlPart === "") return

  util.logInfo("Now playing ID " + urlPart)

  // Set the video.js properties
  let source = {
    "type": "video/youtube",
    "src": "https://www.youtube.com/watch?v=" + urlPart
  }

  var vidParams = {
    "fill": true,
    "poster": "/", // Poster is set via CSS background-image
    "techOrder": ["youtube"],
    "sources": [source],
    "youtube": {
      "iv_load_policy": 3, // Prevent annotations
      "modestbranding": 1, // Tone down YT branding a bit
      "origin": "*"
    }
  }

  // Update the current video marker
  currentVideoUrl = urlPart

  // If this is the first video, initialize the player for the first time
  if (player == null) {
    player = videojs('video', vidParams)
    player.ready(() => {
      player.play()
      enableForwarding = true
    })
    //.. otherwise, update the source..
  } else {
    player.src(source)
    player.load()
    //.. once the player is ready, pause it to stop autoplay..
    player.ready(() => {
      player.pause()
      // .. start playback after 2 seconds to give other (potentially slower) clients some time to load the video ..
      setTimeout(() => {
        player.pause()
        player.currentTime(0)
        player.play()
        // .. and re-enable auto-forwarding via the video.ended event after another 3.5 seconds.
        setTimeout(() => {
          util.logInfo("Re-enabling forwarding")
          enableForwarding = true
        }, 3500)
      }, 2000)
    })
  }

  // Update video info and tab title
  updateVideoInfo(video)
  util.updateTitle(video.cachedTitle)
}

// Shows a modal containing the list of played videos for the current room.
function showHistory(entries) {
  let text = "No history."

  // If this room has history, format each line and add it to a textarea element inside the modal
  if (entries.length) {
    entries.sort((o1, o2) => o1.id - o2.id)
    entries = entries.map((x, i) => `${i + 1}. ${x.title} (${x.url}) - [Added ${moment(x.inserted_at).format('DD.MM HH:mm')}]`)
    text = entries.join("\n")
  }

  $('#history-entries').val(text)
  $('#historyModal').modal()
}

// Updates elements containing video info (title, description..) from a given video.
function updateVideoInfo(video) {

  // Identify the target elements
  let title = $('#curVidTitle')
  let description = $('#curVidDescription')
  let details = $('#curVidDetails')

  // fade-out the old text
  title.addClass('tracking-out-contract')
  description.addClass('tracking-out-contract')
  details.addClass('tracking-out-contract')

  // after 2.5 seconds, when the fade-out ended..
  setTimeout(() => {

    //.. update the element texts as desired to the new values..
    title.text(video.cachedTitle)
    description.text(video.cachedDescription)
    $('#curVidInsertedAt').text(moment(video.inserted_at).fromNow())
    $('#curVidID').text(video.url)

    //.. remove the fade-out classes..
    title.removeClass('tracking-out-contract')
    description.removeClass('tracking-out-contract')
    details.removeClass('tracking-out-contract')

    //.. and add classes to fade them back in
    title.addClass('text-focus-in')
    description.addClass('text-focus-in')
    details.addClass('text-focus-in')
  }, 2500)
}

// Updates the element containing the current number of remaining videos from a given value.
function updateVidCount(count) {

  // Update the counter but floor at 0
  $("#vidcount").text(Math.max(0, count))
}

// Helper for adding messages to the chat list (user-provided or system-provided).
function insertChatMessage(message, name, timestamp, messageClass) {

  // Sanity check
  if ((message || "") === "") return

  // If a name was provided, assemble the name markup.
  let namePart = ""
  if ((name || "") !== "") {
    namePart = `
    <b class="text-primary">${util.sanitizeHTML(name)}: </b>
    `
  }

  // The timestamp markup
  // Use provided timestamp or generate one from the current time (all messages must contain an equally formatted timestamp).
  let timePart = `
    <span class="msg-time">${util.sanitizeHTML(moment(timestamp || new Date()).format('HH:mm'))}</span>
  `

  // The message markup
  let messagePart = `
    <span class="${util.sanitizeHTML(messageClass)}">${util.sanitizeHTML(message)}</span>
  `

  // Assemble the full message markup
  let fullMessage = `
    <span class="msg text-focus-in">${timePart}${namePart}${messagePart}</span>
  `

  // Create a new li element and put into the corresponsing ul in the DOM.
  let li = document.createElement("li")
  li.innerHTML = fullMessage

  let ul = document.getElementById('msg-list')
  ul.appendChild(li)

  // Enable auto-scrolling to bottom
  ul.scrollTop = ul.scrollHeight - ul.clientHeight
}

// #Channel events#
// -----------------

// First, join the websocket channel to start pushing/receiving events
channel.join()

// Shout: A new chat message arrived. Add it to the chat.
channel.on('shout', function (payload) {

  // Insert chat message
  insertChatMessage(payload.message, payload.username || "Guest", payload.timestamp, "text-secondary")
})

// AddVideo: Someone (possibly the user itself) added a video. Post a message to the chat.
channel.on('vid-add', function (payload) {

  // get name from payload or set default, then insert a system message into the chat list
  let name = payload.username || 'guest'
  insertChatMessage(`"${name}" added a video!`, null, null, "font-weight-bold text-success")
  updateVidCount(payload.vidcount)
})

// VideoNew: Server send a new video to be played (e.g. the old one ended, either automatically or manually)
channel.on('vid-new', function (payload) {
  util.logInfo("received vid-new with payload " + JSON.stringify(payload))

  // Update video and video info accordingly
  updateVidCount(payload.remainingCount)
  updateVideo(payload.newVid)

  // If the skip was manual (via skip button), insert a system message into the chat.
  if (payload.manual)
    insertChatMessage(`"${payload.name}" manually skipped the video "${payload.oldVid.cachedTitle}"`, null, null, "font-weight-bold text-warning")
})

// VidPause: Someone press pause - reflect this on the local player instance, unless the local user was the one who sent it
channel.on('vid-pause', function (payload) {
  if (payload.originator !== me) {
    ignoreNext = true
    player.pause()
  }
})

// VidPlay: Someone pressed play or used the seeker (same video.js event) - reflect this on the local player instance, unless the local user was the one who sent it
channel.on('vid-play', function (payload) {
  util.logInfo("received vid-play with payload " + JSON.stringify(payload))
  if (payload.originator !== me) {
    ignoreNext = true
    player.currentTime(payload.timestamp)
    player.play()
  }
})

// SyncRequest: When a new client joins, he sends a sync request to get the current video state from the other clients (the server doesn't know about it.)
// When such a request is received, push a response containing the requested info to the server who then broadcasts it to sync-response.
channel.on('sync-request', function (payload) {
  if (payload.requestor !== me) {
    channel.push('sync-response', {
      isPlaying: !player.paused(),
      timestamp: player.currentTime(),
      requestor: payload.requestor
    })
  }
})

// SyncResponse: See SyncRequest above - this is the answer sent by the various clients.
// Reflect the info contained on the local video player, but only if the local client is the one who sent the sync-request.
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
})

$(() => {
  let name = document.getElementById('name') // name of message sender
  let msg = $('#msg') // message input field

  // #UI event handlers#
  // -----------------

  // Add a new video
  $('#btnAddVideo').on('click', function (event) {

    // Sanity check
    let addName = name.value.trim()
    if (addName === "") {
      toastr.error('Please enter a name to add videos!')
      return
    }

    // Set up the payload
    let inputAddVideo = $('#inputAddVideo')
    if (inputAddVideo.val().trim().length !== 0) {
      let payload = { // send the message to the server on "shout" channel
        url: inputAddVideo.val().trim(),
        host: window.location.hostname + ":" + (window.location.port ? window.location.port : "443"),
        username: addName
      }

      // This is only here for stupid technical reasons im too lazy to fix right now :-)
      if (window.location.hostname.startsWith("localhost"))
        payload.host = "http://localhost:4000"
      else
        payload.host = "https://campfire-sync.herokuapp.com"

      util.logInfo("Add Video Payload: " + JSON.stringify(payload))

      // Push the new video - the server will validate the given ID and reply with an error if the Youtube API says no, which we show in a toast.
      channel
        .push('vid-add', payload)
        .receive("ok", (msg) => {

          // On success, Clear Video ID input field
          inputAddVideo.val("")
          toastr.success(msg.message)
        })
        .receive("error", (msg) => toastr.error(msg.message))
    }
  })

  // Show history
  $('#btnHistory').on("click", (e) => {
    // Fetch the video history from the server API and call the showHistory() helper with the received info.
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
              })))
          })
      })
  })

  // Skip the current video
  $('#btnSkipCurrent')
    .on("click", (e) => {
      // Push the vid-ended video across the channel, signifying that it was done manually.
      channel.push('vid-ended', {
        oldUrl: currentVideoUrl,
        manual: true,
        name: name.value || "Guest"
      })
    })

  // "listen" for the [Enter] keypress event to send a message:
  msg.on('keypress', function (event) {
    if (event.keyCode == 13 && msg.val().length > 0) { // don't sent empty msg.

      let addName = name.value.trim()
      if (addName === "") {
        toastr.error('Please enter a name to chat!')
        return
      }

      channel
        .push('shout', { // send the message to the server on "shout" channel
          username: addName || "Guest",
          message: msg.val() || "I got nothing to say!" // get message text (value) from msg input field.
        })
        .receive("error", (msg) => toastr.error(msg.message))
        .receive("ok", () => {
          // reset the message input field for next message.
          msg.val("")
        })

    }
  })

  // #video.js setup#
  // -----------------
  // Load the current (startup) video as injected into the view by Phoenix
  updateVideo(window.initVideo)

  player.ready(() => {
    // #video.js event handlers#
    // -----------------

    // Pause: User pressed pause. Push vid-pause of the channel unless we are ignoring this one event (see above)
    player.on("pause", () => {
      if (!ignoreNext)
        channel.push('vid-pause', {
          originator: me
        })

      ignoreNext = false
    })

    // Ended: Video reached the final frame. To prevent timing issues, this uses the enableForwarding "cooldown-flag" set above.
    player.on("ended",
      () => {
        util.logInfo("endedCallback called, checking if forwarding enabled..")

        // Only push across the channel if forwarding is enabled.
        if (enableForwarding) {
          util.logInfo("forwarding enabled, pushing vid-ended for video url " + currentVideoUrl)
          channel.push('vid-ended', {
            oldUrl: currentVideoUrl,
            manual: false
          })
        } else
          util.logWarn("forwarding not enabled, not pushing vid-ended - this means a potential skip was prevented")
      }
    )

    // On the first play event directly after page load, push a sync-request (see above) to get the current video player state.
    // Register a follow-up event handler for 'play' immediately after.
    player.one("play", () => {
      channel.push('sync-request', {
        requestor: me
      })

      // Play: User pressed play after video was paused. Push vid-play of the channel unless we are ignoring this one event (see above)
      player.on("play", () => {
        if (!ignoreNext)
          channel.push('vid-play', {
            originator: me,
            timestamp: player.currentTime()
          })

        ignoreNext = false
      })
    })
  })
})