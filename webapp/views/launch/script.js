const socket = io('http://localhost:3001');

/* Incoming */

socket.on('launch_response', (message) => {
  alert(message);
});

socket.on('display_response', (message) => {
  alert(message);
});

socket.on('query_response', (message) => {
  alert(message);
});

/* Outgoing */

function launch() {
  // Get the data from each element on the form.
  const value = document.getElementById('Select_menu').value;
  if (value) {
    const message = { module: value };
    sendMessage('/launch', message);
  }
}

function display() {
  // Get the data from each element on the form.
  const value = document.getElementById('Display_menu').value;
  if (value) {
    const message = { map: value };
    sendMessage('/display', message);
  }
}

function query() {
  // Get the data from each element on the form.
  const value = document.getElementById('Query_menu').value;
  if (value) {
    const message = { map: value };
    sendMessage('/query', message);
  }
}

function exit() {
  sendMessage('/exit');
}

function reply(yesOrNo) {
  sendMessage('/request', yesOrNo);
}


function sendMessage(target, message) {
  const req = new XMLHttpRequest();
  req.open('POST', target);
  req.setRequestHeader('Content-Type', 'application/json');
  req.send(JSON.stringify(message || {}));
}
