/* Incoming */

function handleResponse(json) {
  let buttons;

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
      $('#inputModal .modal-footer').empty();

      buttons = json.actions.map(action => {
        let btn = $(`<button type="button" class="btn btn-primary" data-dismiss="modal"></button`).text(action);

        if (action.toLowerCase() === 'yes') {
          btn.click(() => reply($('#inputModalInput').val()));
        }
        return btn;
      });

      $('#inputModal .modal-footer').append(buttons);
      break;

    case 'upload':
      $('#fileUploadModal').modal({ backdrop: 'static' });
      $('#fileUploadModal .modal-body-text').html(json.text);
      $('#fileUploadModal .modal-footer').empty();

      buttons = json.actions.map(action => {
        let btn = $(`<button type="button" class="btn btn-primary" data-dismiss="modal"></button`).text(action);

        if (action.toLowerCase() === 'yes') {
          btn.click(() => {
            const form = $('#fileUploadForm')[0];
            const fileInput = $('#fileUploadModalInput')[0];
            if (fileInput.files.length) {
              // console.log(fileInput.files[0]);
              console.log(form);
              upload(form);
            }
          });
        }
        return btn;
      });

      $('#fileUploadModal .modal-footer').append(buttons);
      break;
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

function upload(form) {
  $.ajax({
    type: 'POST',
    url: '/file_request',
    data: new FormData(form),
    dataType: 'json',
    cache: false,
    contentType: false,
    processData: false
  }).done((data) => {
    handleResponse(data);
  }).fail(() => {
    const text = 'The server is not responding. Please check if it is running.';
    const alert = $(`<div class="alert alert-danger" role="alert">${text}&nbsp;&nbsp;<button class="close" data-dismiss="alert">×</button></div>`);
    $('#alert-anchor').append(alert);
  });
}
