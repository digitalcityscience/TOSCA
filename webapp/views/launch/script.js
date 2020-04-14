const status = {
  processing: {}
};

/* Handle incoming messages from backend */

function handleResponse(res) {
  console.log(res)

  if (res.processing) {
    status.processing[res.filename] = res.processing > -1;
    poll(res.filename);
    return;
  }

  if (!res.message) {
    return;
  }

  const messageId = res.filename.replace(/\./g, '_');

  const textarea = $('#textarea');
  const buttonarea = $('#buttonarea');

  const close = () => {
    textarea.empty();
    buttonarea.empty();
  }

  close();

  if (res.message.success !== undefined) {
    if (res.message.success) {
      textarea.append(textElement('Success!'));
    } else {
      textarea.append(textElement('Failed!'));
    }
  }

  if (res.message.lat && res.message.lon) {
    map.panTo(new L.LatLng(res.message.lat, res.message.lon));

    // check status ?
    poll();
    return;
  }

  $('#loading').hide();

  if (res.message.text) {
    let text = textElement(res.message.text), form, buttons;

    switch (res.filename) {
      // add_map
      case 'add_map.1.message':
        buttons = [
          buttonElement('OK').click(() => {
            reply('ok', true);
            close();
          })
        ];
        break;
      case 'add_map.2.message':
        form = formElement(messageId);
        form.append($(`<input id="${messageId}-input" type="file" name="file" />`));
        buttons = [
          buttonElement('Submit').click(() => {
            const input = $(`#${messageId}-input`);
            if (input[0].files.length) {
              upload(form[0], handleResponse);
            }
            close();
          })
        ];
        break;
      case 'add_map.3.message':
        form = formElement(messageId);
        form.append($(`<input id="${messageId}-input" type="text" />`));
        buttons = [
          buttonElement('Submit').click(() => {
            const input = $(`#${messageId}-input`);
            reply(input.val(), true);
            close();
          })
        ];
        break;
      case 'add_map.4.message':
        buttons = [
          buttonElement('OK').click(() => {
            reply('ok', false);
            close();
          })
        ];
        break;

      // location_selector
      case 'location_selector.1.message':
        buttons = [
          buttonElement('Yes').click(() => {
            reply('yes', true);
            close();
          }),
          buttonElement('No').click(() => {
            reply('no', true);
            close();
          })
        ];
        break;
      case 'location_selector.2.message':
        form = formElement(messageId);
        form.append($(`<input id="${messageId}-input" type="file" name="file" />`));
        buttons = [
          buttonElement('Submit').click(() => {
            const input = $(`#${messageId}-input`);
            if (input[0].files.length) {
              upload(form[0], handleResponse);
            }
            close();
          })
        ];
        break;
      case 'location_selector.3.message':
        buttons = [
          buttonElement('Yes').click(() => {
            reply('yes', true);
            close();
          }),
          buttonElement('No').click(() => {
            reply('no', true);
            close();
          })
        ];
        break;
      case 'location_selector.10.message':
        buttons = [
          buttonElement('OK').click(() => {
            reply('ok', false);
            close();
          })
        ];
        break;

      // resolution_setting
      case 'resolution_setting.1.message':
      case 'resolution_setting.2.message':
        form = formElement(messageId);
        form.append($(`<input id="${messageId}-input" type="number" />`));
        buttons = [
          buttonElement('Submit').click(() => {
            const input = $(`#${messageId}-input`);
            reply(input.val(), true);
            close();
          })
        ];
        break;

        // module_1
        case 'module_1.1.message':
          buttons = [
            buttonElement('Yes').click(() => {
              reply('yes', true);
              close();
            }),
            buttonElement('No').click(() => {
              reply('no', true);
              close();
            })
          ];
          break;
    }

    textarea.append(text);

    if (form) {
      textarea.append(form);
    }

    if (buttons) {
      buttons.forEach((button) => {
        buttonarea.append(button);
      });
    }
  }
}

function textElement(text) {
  return $(`<div class="textarea-text">${text}</div>`);
}

function formElement(id, isMultipart) {
  return $(`<form id="${id}-form" enctype="${isMultipart ? 'multipart/form-data' : ''}"></form>`);
}

function buttonElement(action) {
  return $(`<button type="button" class="button button-green">${action}</button>`);
}

/* Send messages to the backend */

function launch() {
  // Get the selected item
  const value = $('#launch-menu')[0].value;
  if (value) {
    sendMessage('/launch', { launch: value }, handleResponse);
  }
}

function display() {
  // Get the selected item
  const value = $('#maps-menu')[0].value;
  if (value) {
    sendMessage('/display', { display: value }, handleResponse);
  }
}

function query() {
  // Get the selected item
  const value = $('#query-menu')[0].value;
  if (value) {
    sendMessage('/query', { query: value }, handleResponse);
  }
}

function reply(message, expectResponse) {
  sendMessage('/request', { msg: message }, expectResponse ? handleResponse : null);
}

function poll(process) {
  $('#loading').show();
  sendMessage('/poll', { process }, handleResponse);
}

function sendMessage(target, message, callback) {
  if (!callback) {
    message.noCallback = true;
  }

  $.ajax({
    type: 'POST',
    url: target,
    data: JSON.stringify(message),
    dataType: 'json',
    contentType: 'application/json; encoding=utf-8'
  }).done((data) => {
    if (callback) {
      callback(data);
    }
  }).fail(() => {
    const text = 'The server is not responding. Please check if it is running.';
    const alert = $(`<div class="alert alert-danger" role="alert">${text}&nbsp;&nbsp;<button class="close" data-dismiss="alert">×</button></div>`);
    $('#alert-anchor').append(alert);
  });
}

function upload(form, callback) {
  $.ajax({
    type: 'POST',
    url: '/file_request',
    data: new FormData(form),
    dataType: 'json',
    cache: false,
    contentType: false,
    processData: false
  }).done((data) => {
    if (callback) {
      callback(data);
    }
  }).fail(() => {
    const text = 'The server is not responding. Please check if it is running.';
    const alert = $(`<div class="alert alert-danger" role="alert">${text}&nbsp;&nbsp;<button class="close" data-dismiss="alert">×</button></div>`);
    $('#alert-anchor').append(alert);
  });
}
