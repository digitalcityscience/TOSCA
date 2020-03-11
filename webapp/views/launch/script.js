/* Incoming */

function handleResponse(json) {
  console.log(json.message)

  const modal = generateModal(json.message.modalType, json.message.text, json.filename)
  modal.modal({ backdrop: 'static' })

  const buttons = json.message.actions.map(action => {
    const btn = $(`<button type="button" class="btn btn-primary" data-dismiss="modal"></button>`).text(action);
    action = action.toLowerCase();

    switch (json.message.modalType) {
      case 'error':
      case 'question':
        btn.click(() => reply({ msg: action }));
        break;
      case 'input':
        if (action === 'yes' || action === 'ok') {
          const input = modal.find('input')[0];
          btn.click(() => reply({ msg: input.val() }));
        }
        break;
      case 'upload':
        if (action === 'yes' || action === 'ok') {
          btn.click(() => {
            const form = modal.find('form')[0];
            const input = modal.find('input')[0];
            if (input.files.length) {
              upload(form);
            }
          });
        }
    }
    return btn;
  });
  modal.find('.modal-footer').append(buttons);
  return;

  switch (json.message.modalType) {

    case 'input':
      $('#inputModal').modal({ backdrop: 'static' });
      $('#inputModal .modal-body-text').html(json.text);
      $('#inputModal .modal-footer').empty();

      buttons = json.actions.map(action => {
        let btn = $(`<button type="button" class="btn btn-primary" data-dismiss="modal"></button`).text(action);

        if (action.toLowerCase() === 'yes') {
          btn.click(() => reply({ msg: $('#inputModalInput').val() }));
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

function generateModal(modalType, text, id) {
  const modal = $(`<div class="modal fade show" id="${id}" tabindex="-1" role="dialog">
  <div class="modal-dialog" role="document">
    <div class="modal-content">
      <form id="${id}-form" enctype="${modalType === 'upload' ? 'multipart/form-data' : ''}">
        <div class="modal-body">
          <p class="modal-body-text">${text}</p>
        </div>
        <div class="modal-footer"></div>
      </form>
    </div>
  </div>
</div>`)
  if (modalType === 'input') {
    modal.find('.modal-body').append($(`<p class="modal-body-input"><input id="${id}-input" type="text" /></p>`))
  } else if (modalType === 'upload') {
    modal.find('.modal-body').append($(`<p class="modal-body-input"><input id="${id}-input" type="file" name="file" /></p>`))
  }
  return modal
}

/* Outgoing */

function launch(module) {
  sendMessage('/launch', { msg: module });
}

function display() {
  // Get the selected item
  const value = document.getElementById('Display_menu').value;
  if (value) {
    sendMessage('/display', { msg: value });
  }
}

function query() {
  // Get the selected item
  const value = document.getElementById('Query_menu').value;
  if (value) {
    sendMessage('/query', { msg: value });
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
    data: message,
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
