/* eslint-disable no-undef */
/* eslint-disable no-unused-vars */

/* Handle incoming messages from backend */

function handleResponse(res) {
  if (res.processing) {
    console.log(`${res.filename}:`, res.processing)

    if (res.processing > -1) {
      poll(res.filename);
    } else {
      $('#loading').hide();
    }
  }

  if (!res.message) {
    return;
  }

  console.log(`${res.filename}:`, res.message)

  clearDialog();

  const messageId = res.filename.replace(/\./g, '_');

  const textarea = $('#textarea');
  const buttonarea = $('#buttonarea');
  const lists = $('#lists');

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

  const mapList = (res.message.list || []).sort((a, b) => a.split('@')[1].localeCompare(b.split('@')[1]));

  $('#loading').hide();

  if (res.message.text) {
    let text = textElement(res.message.text), form, buttons;

    switch (res.filename) {
      // The various actions required in response to server messages are defined here.

      // == add_location ==

      // • message id: add_location.1
      // • text: There is an already added location, and it is not allowed to add further locations. If you want to add a new location, the already existing location will automatically removed. If you want to store the already existing location, save manually (refer to the manual, please). Do you want to add a new location? If yes, click OK.
      // • expectation: A request file with yes or no text.
      // • consequence:
      //   - If answer is NO, then add_location send a message and when the message is acknowledged, exit: => add_location.3
      //   - If answer is YES: => add_location.4
      case 'add_location.1.message':
        buttons = [
          buttonElement('Yes').click(() => {
            reply('yes', true);
          }),
          buttonElement('No').click(() => {
            reply('no', true);
          })
        ];
        break;

      // • message id: add_location.2
      // • text: No valid location found. First have to add a location to the dataset. Without such location, CityApp will not work. Adding a new location may take a long time, depending on the file size. If you want to continue, click Yes.
      // • expectation: A request file with yes or no text.
      // • consequence:
      //   - If answer is NO, then add_location send a message and when the message is acknowledged, exit: => add_location.3
      //   - If answer is YES: => add_location.4

      case 'add_location.2.message':
        buttons = [
          buttonElement('Yes').click(() => {
            reply('yes', true);
          }),
          buttonElement('No').click(() => {
            reply('no', true);
          })
        ];
        break;

      // • message id: add_location.3
      // • text: Exit process, click OK.
      // • expectation: A request file with OK text
      // • consequence: Module exit when message is acknowledged
      case 'add_location.3.message':
        buttons = [
          buttonElement('OK').click(() => {
            reply('ok', false);
            clearDialog();
          })
        ];
        break;

      // • message id: add_location.4
      // • text: Select a map to add to CityApp. Map has to be in Open Street Map format -- osm is the only accepted format.
      // • expectation: Finding an uploaded osm file in data_from_browser directory. Request file is not expected, and therefore it is not neccessary to create.
      // • consequence: No specific consequences
      case 'add_location.4.message':
        form = formElement(messageId);
        form.append($(`<input id="${messageId}-input" type="file" name="file" />`));
        buttons = [
          buttonElement('Submit').click(() => {
            $(`#${messageId}-error`).remove();
            const input = $(`#${messageId}-input`);
            if (input[0].files.length) {
              upload(form[0], handleResponse);
            } else {
              textarea.append($(`<span id="${messageId}-error" class="validation-error">Please choose a file for upload.</span>`));
            }
          })
        ];
        break;

      // • message id: add_location.5
      // • text: New location is set. To exit, click OK.
      // • expectation: A request file with OK text
      // • consequence: Module exit when message is acknowledged
      case 'add_location.5.message':
        buttons = [
          buttonElement('OK').click(() => {
            reply('ok', false);
            clearDialog();
          })
        ];
        break;

      // == make_selection ==

      // • message id: make_selection.1
      // • text: No valid location found. First have to add a location to the dataset. Without such location, CityApp will not work. To add a location, use Add Location menu. Now click OK to exit.
      // • expectation: A request file with OK text
      // • consequence: Module exit when message is acknowledged
      case 'make_selection.1.message':
        buttons = [
          buttonElement('OK').click(() => {
            reply('ok', false);
            clearDialog();
          })
        ];
        break;

      // • message id: make_selection.2
      // • text: Now zoom to area of your interest, then use drawing tool to define your location. Next, save your selection.
      // • expectation: Finding an uploaded goejson file in data_from_browser directory. This file is created by the browser, when the user define interactively the selection area. Request file is not expected, and therefore it is not neccessary to create.
      // • consequence: No specific consequences
      case 'make_selection.2.message':
        buttons = [
          buttonElement('Save').click(() => {
            $(`#${messageId}-error`).remove();
            const success = saveDrawing();
            if (!success) {
              textarea.append($(`<span id="${messageId}-error" class="validation-error">Please draw a polygon using the map’s drawing tool.</span>`));
            }
          })
        ];
        break;

      // • message id: make_selection.3
      // • text: Process finished, selection is saved. To process exit, click OK.
      // • expectation: A request file with OK text
      // • consequence: Module exit when message is acknowledged
      case 'make_selection.3.message':
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
            $(`#${messageId}-error`).remove();
            const input = $(`#${messageId}-input`);
            if (!isNaN(parseInt(input.val()))) {
              reply(input.val(), true);
            } else {
              textarea.append($(`<span id="${messageId}-error" class="validation-error">Please enter a numeric value.</span>`));
            }
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
            $(`#${messageId}-error`).remove();
            const input = $(`#${messageId}-input`);
            if (!isNaN(parseInt(input.val()))) {
              reply(input.val(), true);
            } else {
              textarea.append($(`<span id="${messageId}-error" class="validation-error">Please enter a numeric value.</span>`));
            }
          })
        ];
        break;

      case 'resolution_setting.3.message':
        buttons = [
          buttonElement('OK').click(() => {
            reply('ok', false);
            clearDialog();
          })
        ];
        break;

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
            $(`#${messageId}-error`).remove();
            const input = $(`#${messageId}-input`);
            if (input[0].files.length) {
              upload(form[0], handleResponse);
            } else {
              textarea.append($(`<span id="${messageId}-error" class="validation-error">Please choose a file for upload.</span>`));
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
            $(`#${messageId}-error`).remove();
            const input = $(`#${messageId}-input`);
            if (input.val()) {
              reply(input.val(), true);
            } else {
              textarea.append($(`<span id="${messageId}-error" class="validation-error">Please enter a name.</span>`));
            }
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

      // == module_1 ==

      // • message id: module_1.1
      // • text: Start points are required. Do you want to draw start points on the basemap now? If yes, click Yes, then draw one or more point and click Save button. If you want to use an already existing map, select No.
      // • expectation: request file with text Yes or No
      // • consequence:
      //   - If answer is "yes", the module is waiting for a geojson file in data_from_browser. Module only goes to the next step, when geojson file is created.
      //   - If answer is "no", module send a new message: => module_1.2
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

      // • message id: module_1.2
      // • text: Select a map (only point maps are supported). Avilable maps are:
      // • expectation: request file with the select item only.
      //   Since „message.module_1.2” containes a list in json format (list items are the availabe maps), user has to select one of them. The modal type is select, therefore the answer (new request file) conatains only the selected item (in this case: a map name). It is not expected to create a separate request file containig "yes".
      // ----
      // • message id: module_1.4
      // • text: Select a map (only point maps are supported). Avilable maps are:
      // • expectation: request file with the select item only.
      //   Since „message.module_1.4” containes a list in json format (list items are the availabe maps), user has to select one of them. The modal type is select, therefore the answer (new request file) conatains only the selected item (in this case: a map name). It is not expected to create a separate request file containig "yes".
      // ----
      // • message id: module_1.6
      // • text: Select a map (only point maps are supported). Avilable maps are:
      // • expectation: request file with the select item only
      //   Since „message.module_1.6” containes a list in json format (list items are the availabe maps), user has to select one of them. The modal type is select, therefore the answer (new request file) conatains only the selected item (in this case: a map name). It is not expected to create a separate request file containig "yes".
      // ----
      // • message id: module_1.8
      // • text: Select a map (only area maps are supported). Avilable maps are:
      // • expectation: request file with the select item only
      //   Since „message.module_1.8” containes a list in json format (list items are the availabe maps), user has to select one of them. The modal type is select, therefore the answer (new request file) conatains only the selected item (in this case: a map name). It is not expected to create a separate request file containig "yes"
      case 'module_1.2.message':
      case 'module_1.4.message':
      case 'module_1.6.message':
      case 'module_1.8.message':
        form = formElement(messageId);

        // TODO: add maps
        lists.append($(`<select id="${messageId}-input" size="10">` +
          mapList.map(map => `<option selected value="${map}">${map}</option>`) +
        `</select>`));
        buttons = [
          buttonElement('Submit').click(() => {
            const input = $(`#${messageId}-input`);
            reply(input[0].value, true);
          })
        ];
        break;

      // • message id: module_1.3
      // • text: Via points are optional. If you want to select 'via' points from the map, click Yes. If you want to use an already existing map, select No. If you do not want to use via points, click Cancel.
      // • expectation: request file with text yes or no or cancel.
      // • consequence:
      //   - If answer is "yes", the module is waiting for a geojson file in data_from_browser. Module only goes to the next step, when geojson file is created.
      //   - If answer is "no", module send a new message: => module_1.4
      //   - If answer is "cancel": => module_1.5
      // ----
      // • message id: module_1.5
      // • text: Target points are required. If you want to select target points from the map, click Yes. If you want to use an already existing map containing target points, click No. If you want to use the default target points map, click Cancel.
      // • expectation: request file with text yes or no or cancel.
      // • consequence:
      //   - If answer is "yes", the module is waiting for a geojson file in data_from_browser. Module only goes to the next step, when geojson file is created.
      //   - If answer is "no", module send a new message: => module_1.6
      //   - If answer is "cancel": => module_1.7
      // ----
      // • message id: module_1.7
      // • text: Optionally you may define stricken area. If you want to draw area on the map, click Yes. If you want to select a map already containing area, click No. If you do not want to use any area, click Cancel.
      // • expectation: request file with text yes or no or cancel.
      // • consequence:
      //   - If answer is "yes", the module is waiting for a geojson file in data_from_browser. Module only goes to the next step, when geojson file is created.
      //   - If answer is "no", module send a new message: => module_1.8
      //   - If answer is "cancel": => module_1.9
      case 'module_1.3.message':
      case 'module_1.5.message':
      case 'module_1.7.message':
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
          }),
          buttonElement('Cancel').click(() => {
            reply('cancel', true);
          })
        ];
        break;

      // • message id: module_1.9
      // • text: Do you want to set the speed on the road network? If not, the current values will used.
      // • expectation: request file with a single yes or no.
      // • consequence: If answer is "yes", there is a new message: => module_1.10
      case 'module_1.9.message':
        buttons = [
          buttonElement('Yes').click(() => {
            reply('yes', true);
          }),
          buttonElement('No').click(() => {
            reply('no', true);
          })
        ];
        break;

      // • message id: module_1.12
      // • text: Set speed for roads of stricken area.
      // • expectation: reqest file with single a floating point numeric value
      case 'module_1.12.message':
        form = formElement(messageId);
        form.append($(`<input id="${messageId}-input" type="number" />`));
        buttons = [
          buttonElement('Submit').click(() => {
            const input = $(`#${messageId}-input`);
            reply(input.val(), true);
          })
        ];
        break;

      // • message id: module_1.14
      // • text: Calculations are ready, display output time maps.
      // • expectation: A request file with a single "OK" word
      // • consequence: After the user acknowledge the message, the module exit.
      case 'module_1.14.message':
        buttons = [
          buttonElement('OK').click(() => {
            reply('ok', false);
            clearDialog();
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
  $('#lists').empty();
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

function restart() {
  sendMessage('/restart', 'RESTART');
}

function saveDrawing() {
  const geojson = featureGroup.toGeoJSON();
  if (geojson.features.length === 0) {
    return false;
  }
  console.log(`Save drawing:`, geojson);
  sendMessage('/select_location', geojson, handleResponse);
  return true;
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
