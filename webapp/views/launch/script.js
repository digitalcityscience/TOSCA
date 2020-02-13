const socket = io('http://localhost:3001');

/* Incoming */

socket.on('response', (message) => {
  json = JSON.parse(message)
  console.log(json)

  switch (json.modalType) {
    case 'error':
      $('#errorModal').modal({ backdrop: 'static' });
      $('#errorModal .modal-body-text').html(json.text);
      break;

    case 'question':
      $('#questionModal').modal({ backdrop: 'static' });
      $('#questionModal .modal-body-text').html(json.text);
      break;

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

    case 'fileupload':

    default:
  }
});

/* Outgoing */

function launch(module) {
  sendMessage('/launch', { module: module });
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
