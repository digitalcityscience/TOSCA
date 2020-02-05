function launch() {
  // Get the data from each element on the form.
  const value = document.getElementById('Select_menu').value;
  const message = { module: value };
  sendMessage('/launch', message);
}

function display() {
  // Get the data from each element on the form.
  const value = document.getElementById('Display_menu').value;
  const message = { map: value };
  sendMessage('/display', message);
}

function query() {
  // Get the data from each element on the form.
  const value = document.getElementById('Query_menu').value;
  const message = { map: value };
  sendMessage('/query', message);
}

function sendMessage(target, message) {
  const req = new XMLHttpRequest();
  req.open('POST', target);
  req.setRequestHeader('Content-Type', 'application/json');
  req.send(JSON.stringify(message));
}
