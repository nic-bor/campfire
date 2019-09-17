import moment from "moment"

var util = {
  updateTitle(newValue) {
    document.getElementsByTagName('title')[0].innerText = "📺🔥 | " + newValue;
  },
  sanitizeHTML(str) {
    var temp = document.createElement('div');
    temp.textContent = str;
    return temp.innerHTML;
  },
  logInfo(str) {
    logSend(console.log, str)
  },
  logWarn(str) {
    logSend(console.warn, str)
  }

}

var logSend = (sendFun, str) => sendFun(`[${moment().format('HH:mm:ss')}]  ${str}`)

export default util