/* Handle incoming messages from backend */

function handleResponse({ filename, message }) {
  const messageId = filename.replace(/\./g, '_');

  if (message.lat && message.lon) {
    map.panTo(new L.LatLng(message.lat, message.lon));
    return;
  }

  if (!message.text) {
    console.error('Error: Empty message');
    return;
  }

  const textarea = $('#textarea');
  const buttonarea = $('#buttonarea');

  const close = () => {
    textarea.empty();
    buttonarea.empty();
  }

  close();

  let text = textElement(message.text), form, buttons;

  switch (filename) {
    // add_map
    case 'message.add_map.1':
      buttons = [
        buttonElement('OK').click(() => {
          reply('ok', true);
          close();
        })
      ];
      break;
    case 'message.add_map.2':
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
    case 'message.add_map.3':
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
    case 'message.add_map.4':
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
    case 'message.add_map.5':
      buttons = [
        buttonElement('OK').click(() => {
          reply('ok', false);
          close();
        })
      ];
      break;

    // location_selector
    case 'message.location_selector.1':
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
    case 'message.location_selector.2':
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
    case 'message.location_selector.3':
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
    case 'message.location_selector.10':
      buttons = [
        buttonElement('OK').click(() => {
          reply('ok', false);
          close();
        })
      ];
      break;

    // resolution_setting
    case 'message.resolution_setting.1':
    case 'message.resolution_setting.2':
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
