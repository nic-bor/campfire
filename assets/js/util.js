var util = {
  updateTitle(newValue) {
    document.getElementsByTagName('title')[0].innerText = "📺🔥 | " + newValue;
  },
  sanitizeHTML(str) {
    var temp = document.createElement('div');
    temp.textContent = str;
    return temp.innerHTML;
  }
}

export default util