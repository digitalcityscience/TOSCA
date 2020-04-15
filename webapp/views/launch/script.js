/* Handle incoming messages from backend */

function handleResponse(res) {
  if (res.processing) {
    console.log(`${res.filename}:`, res.processing)

    if (res.processing > -1) {
      poll(res.filename);
    } else {
      $('#loading').hide();
    }
    return;
  }

  if (!res.message) {
    return;
  }

  console.log(`${res.filename}:`, res.message)

  clearDialog();

  const messageId = res.filename.replace(/\./g, '_');

  const textarea = $('#textarea');
  const buttonarea = $('#buttonarea');

  if (res.message.success !== undefined) {
    if (res.message.success) {
      textarea.append(textElement('Success!'));
    } else {
      textarea.append(textElement('Failed!'));
    }
  }

  if (res.message.lat && res.message.lon) {
    map.panTo(new L.LatLng(res.message.lat, res.message.lon));

    poll();
    return;
  }

  $('#loading').hide();

  if (res.message.text) {
    let text = textElement(res.message.text), form, buttons;

    switch (res.filename) {
      // The various actions required in response to server messages are defined here.

      // == add_map ==

      // • message id: add_map.1
      // • text: "Selection" map not found. Before adding a new layer, first you have to define a location and a selection. For this end please, use Location Selector tool of CityApp. Add_Map modul now quit.
      // • expectation: A request file with text OK
      // • consequence: Since no valid selection, the module exit after the user acknowledge the message.
      case 'add_map.1.message':
        buttons = [
          buttonElement('OK').click(() => {
            reply('ok', true);
          })
        ];
        break;

      // • message id: add_map.2
      // • text: Select a map to add CityApp. Only gpkg (geopackage), geojson and openstreetmap vector files and geotiff (gtif or tif) raster files are accepted.
      // • expectation: An uploaded file with a supported filename extension in data_from_browser directory. Request file is not expected, the question is only to draw the user's focus to the next step (select a file). Therefore in this case the trigger for the back-end is the presence of the uploaded file (and not a request file)
      // • consequence: When the selected file is uploaded succesfully, there is a new message: => add_map.3
      case 'add_map.2.message':
        form = formElement(messageId);
        form.append($(`<input id="${messageId}-input" type="file" name="file" />`));
        buttons = [
          buttonElement('Submit').click(() => {
            const input = $(`#${messageId}-input`);
            if (input[0].files.length) {
              upload(form[0], handleResponse);
            }
          })
        ];
        break;

      // • message id: add_map.3
      // • text: Please, define an output map name. Name can contain only english characters, numbers, or underline character. Space and other specific characters are not allowed. For first character a letter only accepted.
      // • expectation: a request file with a single word as output name, defined by the user
      case 'add_map.3.message':
        form = formElement(messageId);
        form.append($(`<input id="${messageId}-input" type="text" />`));
        buttons = [
          buttonElement('Submit').click(() => {
            const input = $(`#${messageId}-input`);
            reply(input.val(), true);
          })
        ];
        break;

      // • message id: add_map.4
      // • text: Selected map is now succesfully added to your mapset. Add map module now exit
      // • expectation: A request file with text OK
      // • consequence: Module exit after user acknowledge the message.
      case 'add_map.4.message':
        buttons = [
          buttonElement('OK').click(() => {
            reply('ok', false);
            clearDialog();
          })
        ];
        break;

      // == location_selector ==

      // • message id: location_selector.1
      // • text: No valid location found. First have to add a location to the dataset. Without such location, CityApp will not work. Adding a new location may take a long time, depending on the file size. If you want to continue, click Yes.
      // • expectation: A request file with yes or no text.
      // • consequence:
      //   - If answer is NO, then location_selector send a message and when the message is acknowledged, exit: => location_selector.10
      //   - If answer is YES: => location_selector.2
      case 'location_selector.1.message':
        buttons = [
          buttonElement('Yes').click(() => {
            reply('yes', true);
          }),
          buttonElement('No').click(() => {
            reply('no', true);
          })
        ];
        break;

      // • message id: location_selector.2
      // • text: Select a map to add to CityApp. Map has to be in Open Street Map format -- osm is the only accepted format.
      // • expectation: Finding an uploaded osm file in data_from_browser directory. Request file is not expected, and therefore it is not neccessary to create.
      // • consequence: No specific consequences
      case 'location_selector.2.message':
        form = formElement(messageId);
        form.append($(`<input id="${messageId}-input" type="file" name="file" />`));
        buttons = [
          buttonElement('Submit').click(() => {
            const input = $(`#${messageId}-input`);
            if (input[0].files.length) {
              upload(form[0], handleResponse);
            }
          })
        ];
        break;

      // • message id: location_selector.3
      // • text: There is an already defined area. To reshape the existing selection, select Yes. If do not want reshape the selection, beceause you want to replace the entire location, select No.
      // • expectation: A request file with yes or no text
      // • consequence:
      //   - If answer is yes: => location_selector.8
      //   - If answer is no: => location_selector.2
      case 'location_selector.3.message':
        buttons = [
          buttonElement('Yes').click(() => {
            reply('yes', true);
          }),
          buttonElement('No').click(() => {
            reply('no', true);
          })
        ];
        break;

      // • message id: location_selector.8
      // • text: Now zoom to area of your interest, then use drawing tool to define your location. Next, save your selection.
      // • expectation: Finding an uploaded goejson file in data_from_browser directory. This file is created by the browser, when the user define interactively the selection area. Request file is not expected, and therefore it is not neccessary to create.
      // • consequence: No specific consequences
      case 'location_selector.8.message':
        buttons = [
          buttonElement('Save').click(() => {
            saveDrawing();
          })
        ];
        break;

      // • message id: location_selector.9
      // • text: Process finished. Now CityApp Location selector exit
      // • expectation: A request file with OK text
      // • consequence: Module exit when message is acknowledged
      // ----
      // • message id: location_selector.10
      // • text: Location selector is now exiting.
      // • expectation: A request file with OK text.
      case 'location_selector.9.message':
      case 'location_selector.10.message':
        buttons = [
          buttonElement('OK').click(() => {
            reply('ok', false);
            clearDialog();
          })
        ];
        break;

      // == resolution_setting ==

      // • message id: resolution_setting.1
      // • text: Type the resolution in meters, you want to use. For further details see manual.
      // • expectation: A request file with a positive number.
      // • consequence: If user gives a negative number, then UNTIL number is greater than zero: => resolution_setting.2
      case 'resolution_setting.1.message':
        form = formElement(messageId);
        form.append($(`<input id="${messageId}-input" type="number" />`));
        buttons = [
          buttonElement('Submit').click(() => {
            const input = $(`#${messageId}-input`);
            reply(input.val(), true);
          })
        ];
        break;

      // • message id: resolution_setting.2
      // • text: Resolution has to be an integer number, greater than 0.  Please, define the resolution for calculations in meters.
      // • expectation: A request file with a positive number.
      // • consequence: No specific consequences
      case 'resolution_setting.2.message':
        form = formElement(messageId);
        form.append($(`<input id="${messageId}-input" type="number" />`));
        buttons = [
          buttonElement('Submit').click(() => {
            const input = $(`#${messageId}-input`);
            reply(input.val(), true);
          })
        ];
        break;

      // == module_1 ==

      case 'module_1.1.message':
        buttons = [
          buttonElement('Yes').click(() => {
            reply('yes', false);
            const saveButton = buttonElement('Save').click(() => {
              saveDrawing();
            })
            buttonarea.append(saveButton);
          }),
          buttonElement('No').click(() => {
            reply('no', true);
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

function clearDialog() {
  $('#textarea').empty();
  $('#buttonarea').empty();
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
  console.log(`Reply:`, message);
  sendMessage('/request', { msg: message }, expectResponse ? handleResponse : null);
}

function poll(process) {
  $('#loading').show();
  sendMessage('/poll', { process }, handleResponse);
}

function saveDrawing() {
  const geojson = featureGroup.toGeoJSON();
  console.log(`Save drawing:`, geojson);
  sendMessage('/select_location', geojson, handleResponse);
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
  })
  .done(callback ? callback : null)
  .fail(onServerTimeout);
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
  })
  .done(callback ? callback : null)
  .fail(onServerTimeout);
}

function onServerTimeout() {
  const text = 'The server is not responding. Please check if it is running.';
  const alert = $(`<div class="alert alert-danger" role="alert">${text}&nbsp;&nbsp;<button class="close" data-dismiss="alert">×</button></div>`);
  $('#alert-anchor').append(alert);
  $('#loading').hide();
}
