const socket = io('http://localhost:3001');

/* Incoming */

socket.on('response', (message) => {
  json = JSON.parse(message)
  console.log(json)

  switch (json.modalType) {
    case 'input':
      $('#inputModal').modal({ backdrop: 'static' });
      $('#inputModal .modal-body-text').html(json.text);
      $('#inputModal .modal-footer').empty()

      const buttons = json.actions.map(action => {
        let btn = $(`<button type="button" class="btn btn-primary" data-dismiss="modal"></button`).text(action);
        btn.click(() => reply($('#inputModalInput').val()));
        return btn;
      });

      $('#inputModal .modal-footer').append(buttons)
      break;

    default:
      $('#yesNoModal').modal({ backdrop: 'static' });
      $('#yesNoModal .modal-body-text').html(json.text);
  }
});

/* Outgoing */

function setResolution() {
  sendMessage('/launch', { module: 'resolution_setting' });
}

function launch() {
  // Get the selected item
  const value = document.getElementById('Select_menu').value;
  if (value) {
    const message = { module: value };
    sendMessage('/launch', message);
  }
}

function display() {
  // Get the selected item
  const value = document.getElementById('Display_menu').value;
  if (value) {
    const message = { map: value };
    sendMessage('/display', message);
  }
}

function query() {
  // Get the selected item
  const value = document.getElementById('Query_menu').value;
  if (value) {
    const message = { map: value };
    sendMessage('/query', message);
  }
}

function exit() {
  sendMessage('/exit');
}

function reply(message) {
  sendMessage('/request', message);
}

function sendMessage(target, message) {
  const req = new XMLHttpRequest();
  req.open('POST', target);
  req.setRequestHeader('Content-Type', 'application/json');
  req.send(JSON.stringify(message || {}));
}
