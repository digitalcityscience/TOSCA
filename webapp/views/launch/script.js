/* Incoming */

function handleResponse(json) {
  switch (json.modalType) {
    case 'error':
      $('#errorModal').modal({ backdrop: 'static' });
      $('#errorModal .modal-body-text').html(json.text);
      break;

    case 'question':
      $('#yesNoModal').modal({ backdrop: 'static' });
      $('#yesNoModal .modal-body-text').html(json.text);
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

    case 'upload':

    default:
  }
}

/* Outgoing */

function launch(module) {
  sendMessage('/launch', { module: module });
}

function display() {
  // Get the selected item
  const value = document.getElementById('Display_menu').value;
  if (value) {
    sendMessage('/display', { map: value });
  }
}

function query() {
  // Get the selected item
  const value = document.getElementById('Query_menu').value;
  if (value) {
    sendMessage('/query', { map: value });
  }
}

function exit() {
  sendMessage('/exit');
}

function reply(message) {
  sendMessage('/request', message);
}

function sendMessage(target, message) {
  $.ajax({
    type: 'POST',
    url: target,
    data: JSON.stringify(message || {}),
    dataType: 'json'
  }).done((data) => {
    handleResponse(data);
  }).fail(() => {
    const text = 'The server is not responding. Please check if it is running.';
    const alert = $(`<div class="alert alert-danger" role="alert">${text}&nbsp;&nbsp;<button class="close" data-dismiss="alert">×</button></div>`);
    $('#alert-anchor').append(alert);
  });
}
