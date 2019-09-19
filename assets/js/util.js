import $ from "jquery"
import moment from "moment"

var _logSend = (sendFun, str) => sendFun(`[${moment().format('HH:mm:ss')}]  ${str}`)

var util = {
  // Updates the title element
  updateTitle: (newValue) => $('title').text("📺🔥 | " + newValue),

  // Logs an info event in a preformatted way
  logInfo: (str) => _logSend(console.log, str),

  // Logs a warning event in a preformatted way
  logWarn: (str) => _logSend(console.warn, str),

  // Sanitizes a string (e.g. user input) to make it safe for DOM insertion.
  sanitizeHTML: (str) => {

    // Let the browser handle it: Create a div, insert the string as text and then retreive it.
    var temp = document.createElement('div')
    temp.textContent = str
    return temp.innerHTML
  },
}

export default util