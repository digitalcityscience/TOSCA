/* eslint-disable no-undef */
/* eslint-disable no-unused-vars */

/* Handle incoming messages from backend */

function handleResponse(res) {
  if (!res.message) {
    return;
  }

  clearDialog();

  const messageId = res.message_id.replace(/\./g, '_');

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
  }

  const list = (res.message.list || []).sort();

  $('#loading').hide();

  if (res.message.text) {
    let text = textElement(res.message.text), form, buttons;

    switch (res.message_id) {
      // The various actions required in response to server messages are defined here.

      // == add_location ==

      // • message id: add_location.1
      // • text: There is an already added location, and it is not allowed to add further locations. If you want to add a new location, the already existing location will automatically removed. If you want to store the already existing location, save manually (refer to the manual, please). Do you want to add a new location? If yes, click OK.
      // • expectation: A request file with yes or no text.
      // • consequence:
      //   - If answer is NO, then add_location send a message and when the message is acknowledged, exit: => add_location.3
      //   - If answer is YES: => add_location.4
      case 'add_location.1':
        buttons = [
          buttonElement('Yes').click(() => {
            reply(res, 'yes');
          }),
          buttonElement('No').click(() => {
            reply(res, 'no');
          })
        ];
        break;

      // • message id: add_location.4
      // • text: Select a map to add to CityApp. Map has to be in Open Street Map format -- osm is the only accepted format.
      // • expectation: Finding an uploaded osm file in data_from_browser directory. Request file is not expected, and therefore it is not neccessary to create.
      // • consequence: No specific consequences
      case 'add_location.4':
        form = formElement(messageId);
        form.append($(`<input id="${messageId}-input" type="file" name="file" />`));
        buttons = [
          buttonElement('Submit').click(() => {
            $(`#${messageId}-error`).remove();
            const input = $(`#${messageId}-input`);
            if (input[0].files.length) {
              upload(form[0], { message_id: res.message_id }, handleResponse);
            } else {
              textarea.append($(`<span id="${messageId}-error" class="validation-error">Please choose a file for upload.</span>`));
            }
          })
        ];
        break;

      // == set_selection ==

      // • message id: set_selection.2
      // • text: Now zoom to area of your interest, then use drawing tool to define your location. Next, save your selection.
      // • expectation: Finding an uploaded goejson file in data_from_browser directory. This file is created by the browser, when the user define interactively the selection area. Request file is not expected, and therefore it is not neccessary to create.
      // • consequence: No specific consequences
      case 'set_selection.2':
        drawnItems.clearLayers();
        buttons = [
          buttonElement('Save').click(() => {
            $(`#${messageId}-error`).remove();
            if (!saveDrawing(res)) {
              textarea.append($(`<span id="${messageId}-error" class="validation-error">Please draw a polygon using the map’s drawing tool.</span>`));
            }
          })
        ];
        break;

      // == set_resolution ==

      // • message id: set_resolution.1
      // • text: Type the resolution in meters, you want to use. For further details see manual.
      // • expectation: A request file with a positive number.
      // • consequence: If user gives a negative number, then UNTIL number is greater than zero: => set_resolution.2
      // ----
      // • message id: set_resolution.2
      // • text: Resolution has to be an integer number, greater than 0. Please, define the resolution for calculations in meters.
      // • expectation: A request file with a positive number.
      // • consequence: No specific consequences
      case 'set_resolution.1':
      case 'set_resolution.2':
        form = formElement(messageId);
        form.append($(`<input id="${messageId}-input" type="number" />`));
        form.append($(`<span>&nbsp;m</span>`));
        buttons = [
          buttonElement('Submit').click(() => {
            $(`#${messageId}-error`).remove();
            const input = $(`#${messageId}-input`);
            if (!isNaN(parseInt(input.val()))) {
              reply(res, input.val());
            } else {
              textarea.append($(`<span id="${messageId}-error" class="validation-error">Please enter a numeric value.</span>`));
            }
          })
        ];
        break;

      // == add_map ==

      // • message id: add_map.1
      // • text: "Selection" map not found. Before adding a new layer, first you have to define a location and a selection. For this end please, use Location Selector tool of CityApp. Add_Map modul now quit.
      // • expectation: A request file with text OK
      // • consequence: Since no valid selection, the module exit after the user acknowledge the message.
      case 'add_map.1':
        buttons = [
          buttonElement('OK').click(() => {
            reply(res, 'ok');
          })
        ];
        break;

      // • message id: add_map.2
      // • text: Select a map to add CityApp. Only gpkg (geopackage), geojson and openstreetmap vector files and geotiff (gtif or tif) raster files are accepted.
      // • expectation: An uploaded file with a supported filename extension in data_from_browser directory. Request file is not expected, the question is only to draw the user's focus to the next step (select a file). Therefore in this case the trigger for the back-end is the presence of the uploaded file (and not a request file)
      // • consequence: When the selected file is uploaded succesfully, there is a new message: => add_map.3
      case 'add_map.2':
        form = formElement(messageId);
        form.append($(`<input id="${messageId}-input" type="file" name="file" />`));
        buttons = [
          buttonElement('Submit').click(() => {
            $(`#${messageId}-error`).remove();
            const input = $(`#${messageId}-input`);
            if (input[0].files.length) {
              upload(form[0], { message_id: res.message_id }, handleResponse);
            } else {
              textarea.append($(`<span id="${messageId}-error" class="validation-error">Please choose a file for upload.</span>`));
            }
          })
        ];
        break;

      // • message id: add_map.3
      // • text: Please, define an output map name. Name can contain only english characters, numbers, or underline character. Space and other specific characters are not allowed. For first character a letter only accepted.
      // • expectation: a request file with a single word as output name, defined by the user
      case 'add_map.3':
        form = formElement(messageId);
        form.append($(`<input id="${messageId}-input" type="text" />`));
        buttons = [
          buttonElement('Submit').click(() => {
            $(`#${messageId}-error`).remove();
            const input = $(`#${messageId}-input`);
            if (input.val()) {
              reply(res, input.val());
            } else {
              textarea.append($(`<span id="${messageId}-error" class="validation-error">Please enter a name.</span>`));
            }
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
      case 'module_1.1':
        buttons = [
          buttonElement('Yes').click(() => {
            const saveButton = buttonElement('Save').click(() => {
              saveDrawing(res);
            })
            buttonarea.append(saveButton);
          }),
          buttonElement('No').click(() => {
            reply(res, 'no');
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
      case 'module_1.2':
      case 'module_1.4':
      case 'module_1.6':
      case 'module_1.8':
        form = formElement(messageId);
        lists.append($(`<select id="${messageId}-input" size="10">` + list.map(map => `<option selected value="${map}">${map}</option>`) + `</select>`));
        buttons = [
          buttonElement('Submit').click(() => {
            const input = $(`#${messageId}-input`);
            reply(res, input[0].value);
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
      case 'module_1.3':
      case 'module_1.5':
      case 'module_1.7':
        buttons = [
          buttonElement('Yes').click(() => {
            const saveButton = buttonElement('Save').click(() => {
              saveDrawing(res);
            })
            buttonarea.append(saveButton);
          }),
          buttonElement('No').click(() => {
            reply(res, 'no');
          }),
          buttonElement('Cancel').click(() => {
            reply(res, 'cancel');
          })
        ];
        break;

      // • message id: module_1.9
      // • text: Do you want to set the speed on the road network? If not, the current values will used.
      // • expectation: request file with a single yes or no.
      // • consequence: If answer is "yes", there is a new message: => module_1.11
      case 'module_1.9':
        buttons = [
          buttonElement('Yes').click(() => {
            reply(res, 'yes');
          }),
          buttonElement('No').click(() => {
            reply(res, 'no');
          })
        ];
        break;

      // • message id: module_1.12
      // • text: Set speed reduction ratio for roads of stricken area
      // • expectation: reqest file with single a floating point numeric value
      // • message id: module_1.10
      // • text: Set the speed on the road network.
      // • expectation: reqest file with single a floating point numeric value
      case 'module_1.12':
      case 'module_1.10':
        form = formElement(messageId);
        form.append($(`<input id="${messageId}-input" type="number" />`));
        buttons = [
          buttonElement('Submit').click(() => {
            const input = $(`#${messageId}-input`);
            reply(res, input.val());
          })
        ];
        break;

      // == module_1a ==

      // Start points / via points
      case 'module_1a.1':
      case 'module_1a.2':
        drawnItems.clearLayers();
        map.addLayer(drawnItems)
        map.addLayer(FromPoints)
        map.addLayer(ViaPoints)
        map.addLayer(ToPoints)
        map.addLayer(StrickenArea)

        buttons = [
          buttonElement('Save').click(() => {
            $(`#${messageId}-error`).remove();
            if (!saveDrawing(res)) {
              textarea.append($(`<span id="${messageId}-error" class="validation-error">Please draw a point using the circlemarker drawing tool.</span>`));
            }
          }),
          buttonElement('Cancel').click(() => {
            reply(res, 'cancel');
          })
        ];
        break;

      // stricken area
      case 'module_1a.3':
        drawnItems.clearLayers();
        map.addLayer(drawnItems)
        buttons = [
          buttonElement('Save').click(() => {
            $(`#${messageId}-error`).remove();
            if (!saveDrawing(res)) {
              textarea.append($(`<span id="${messageId}-error" class="validation-error">Please draw a polygon using the polygon drawing tool.</span>`));
            }
          }),
          buttonElement('Cancel').click(() => {
            reply(res, 'cancel');
          })
        ];
        break;

      // Speed reduction ratio
      case 'module_1a.4':
      case 'module_1a.9':
        form = formElement(messageId);
        form.append($(`<input id="${messageId}-input" type="number" />`));
        form.append($(`<span>&nbsp;%</span>`));
        buttons = [
          buttonElement('Submit').click(() => {
            const input = $(`#${messageId}-input`);
            reply(res, input.val());
          })
        ];
        break;

      case 'module_1a.8':
        drawnItems.clearLayers();
        buttons = [
          buttonElement('Yes').click(() => {
            reply(res, 'yes');
          }),
          buttonElement('No').click(() => {
            reply(res, 'no');
          })
        ];
        break;

      // == module_2 ==

      case 'module_2.1':
        drawnItems.clearLayers();
        map.addLayer(drawnItems)
        buttons = [
          buttonElement('Save').click(() => {
            $(`#${messageId}-error`).remove();
            if (!saveDrawing(res)) {
              textarea.append($(`<span id="${messageId}-error" class="validation-error">Please draw a polygon using the map’s drawing tool.</span>`));
            }
          })
        ];
        break;

      case 'module_2.2':
        form = formElement(messageId);
        lists.append($(`<select id="${messageId}-input" class='custom-select' size="10">` + list.map(col => `<option selected value="${col}">${col}</option>`) + `</select>`));
        buttons = [
          buttonElement('Show attributes').click(() => {
            const input = $(`#${messageId}-input`);
            getAttributes(input[0].value)
          }),
          buttonElement('Submit').click(() => {
            const input = $(`#${messageId}-input`);
            reply(res, input[0].value);
          })
        ];
        break;

      case 'module_2.3': {
        form = formElement(messageId);
        const columns = list.map(col => `<option value="${col}">${col}</option>`);
        const rel = ['AND', 'OR', 'NOT'].map(el => `<option value="${el}">${el}</option>`);
        const op = ['>', '<', '=', '>=', '<='].map(el => `<option value="${el}">${el}</option>`);
        const condition = `
        <li class='d-flex'>
              <select class='${messageId}-input custom-select mr-2'>${columns}</select>
              <select class='${messageId}-input custom-select mr-2'>${op}</select>
              <input class='${messageId}-input form-control' type="number" />
        </li>
        `
        lists.append($('<span>WHERE</span>'));
        lists.append($(condition));
        let inputs = $(`.${messageId}-input`)
        buttons = [
          buttonElement('＋').click(() => {
            lists.append($(`<select class='${messageId}-input custom-select mt-2 mb-2'>${rel}</select>`));
            lists.append($(condition));
            inputs = $(`.${messageId}-input`)
          }),
          buttonElement('−').click(() => {
            if (lists.children().length > 3) {
              lists.children().last().remove()
              lists.children().last().remove()
            }
            inputs = $(`.${messageId}-input`)
          }),
          buttonElement('Submit').click(() => {
            $(`#${messageId}-error`).remove();
            let msg = []
            // inputs.map is problematic because jquery objs behave differently
            for (let i = 0; i < inputs.length; i++) {
              // validate input
              if ((inputs[i].type === 'number' && inputs[i].value.match(/^(-?\d+\.\d+)$|^(-?\d+)$/))
                ||
                (inputs[i].type != 'number')) {
                msg.push(inputs[i].value)
              } else {
                msg = []
                textarea.append($(`<span id="${messageId}-error" class="validation-error">Please enter valid numbers in the fields.</span>`));
                break
              }
            }
            if (msg.length) reply(res, msg)
          })
        ];
        break;
      }

      // == module_2b ==

      // • message id: module_2b.1
      // • text: If you want to use an existing map as query area, click 'Map' button, then draw the area, and click 'Save'.  If you want to draw a new query area, click 'Draw' button. If you want to exit, click 'Cancel'.
      // • expectation: request file with text "map", "draw" or "cancel"
      // • consequence:
      //    - If answer is "draw", the module is waiting for a geojson file in data_from_browser. Module only goes to the next step, when geojson file is created.
      //    - If answer is "map", module send a new message: => module_2b.2
      //    - If answer is cancel, module exit.
      case 'module_2b.1.message':
        buttons = [
          buttonElement('Draw').click(() => {
            reply('draw', false);
            const saveButton = buttonElement('Save').click(() => {
              saveDrawing();
            })
            buttonarea.append(saveButton);
          }),
          buttonElement('Cancel').click(() => {
            reply('cancel', true);
          })
        ];
        break;

      // • message id: module_2b.2
      // • text: To process exit, click OK.
      // • expectation: A request file with a single "OK" word
      // • consequence: After the user acknowledge the message, the module exit.
      case 'module_2b.2.message':
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
  return $(`<form id="${id}-form" enctype="${isMultipart ? 'multipart/form-data' : ''}" onsubmit="event.preventDefault()"></form>`);
}

function buttonElement(action) {
  return $(`<button type="button" class="btn btn-primary">${action}</button>`);
}

/**
 * create a table element from data
 * @param {Array} data an array of identically structured js objects 
 * @param {string} className className of the table
 */
function tableElement(className, data) {
  let html = `<table class=${className}><tr>`
  Object.keys(data[0]).forEach(field => {
    html += `<th>${field}</th>`
  })
  html += '</tr>'
  data.forEach(entry => {
    html += '<tr>'
    Object.keys(entry).forEach(field => {
      html += `<td>${entry[field]}</td>`
    })
    html += '</tr>'
  })
  html += '</table>'
  return html
}

function clearDialog() {
  $('#textarea').empty();
  $('#buttonarea').empty();
  $('#lists').empty();
}

function showResults() {
  getOutput({})
  $('#results-modal').show()
  // empty iframe content
  $('#results-iframe').attr('src', '')
}

function show_help() {
  $('#help-modal').show()
}

let blinkTimeout;
function blink(selector) {
  if (!blinkTimeout) {
    $(selector).addClass("blink");
    blinkTimeout = setTimeout(function () {
      blinkTimeout = null;
      $(selector).removeClass("blink");
    }, 3600);
  }
}

$('#launch-module-menu').on('change', (event) => {
  clearDialog();
  const value = $(event.target).val();
  if (value.match(/module_1/)) {
    $('#textarea').append('The Calculate Time Map Module creates a heat map, showing the time it takes to reach any part of the selected area from a ‘start point’. Optionally, affected areas with reduced speed limit, and via-points can be defined.');
  } else if (value.match(/module_2/)) {
    $('#textarea').append('To query an area means to filter the map features/elements based on some user-determined values. For example, a housing map layer can be queried based on the household population and monthly income, and only the houses with the corresponding value range will be returned.');
  }
})

/* Send messages to the backend */

function launchModule() {
  // Get the selected item
  const value = $('#launch-module-menu')[0].value;
  if (value) {
    sendMessage('/launch', { launch: value }, {}, handleResponse);
  }
}

function launchSettings(value) {
  if (value) {
    sendMessage('/launch', { launch: value }, {}, handleResponse);
  }
}

function reply(res, message) {
  sendMessage('/reply', { msg: message }, { message_id: res.message_id }, handleResponse);
}

function saveDrawing(res) {
  const geojson = drawnItems.toGeoJSON();
  if (geojson.features.length === 0) {
    return false;
  }
  sendMessage('/drawing', { data: geojson }, { message_id: res.message_id }, handleResponse);
  return true;
}

function getOutput() {
  get('/output', {}, function (res) {
    const baseOption = "<option selected value=''> - </option>"
    const options = res.message.list.reduce((str, file) => str + `<option value="${file}">${file}</option>`, '')
    $('#results-select').html(baseOption + options)
  });
}

function getAttributes(table) {
  get('/attributes', { table }, function (res) {
    const { head, body } = JSON.parse(res.message.attributes)
    const html = "<h5>Table description</h5>" + tableElement('table table-bordered', head) + "<br><h5>Column description</h5>" + tableElement('table table-bordered', body)
    $('#attributes-content').html(html)
    $('#table-attributes-modal').show()
  });
}

function sendMessage(target, message, params, callback) {
  $('#loading').show();

  $.ajax({
    type: 'POST',
    url: target + '?' + $.param(params),
    data: JSON.stringify(message),
    dataType: 'json',
    contentType: 'application/json; encoding=utf-8',
    error: onServerError
  })
    .done(callback)
    .always(() => $('#loading').hide());
}

function get(target, params, callback) {
  $('#loading').show();
  console.log('params: ', params);
  console.log('$.param(params): ', $.param(params));

  $.ajax({
    type: 'GET',
    url: target + '?' + $.param(params),
    contentType: 'application/json; encoding=utf-8',
    error: onServerError
  })
    .done(callback)
    .always(() => $('#loading').hide());
}

function upload(form, params, callback) {
  $('#loading').show();

  $.ajax({
    type: 'POST',
    url: '/file?' + $.param(params),
    data: new FormData(form),
    dataType: 'json',
    cache: false,
    contentType: false,
    processData: false,
    error: onServerError
  })
    .done(callback)
    .always(() => $('#loading').hide());
}

function onServerError(xhr, textStatus) {
  const text = xhr.responseJSON && xhr.responseJSON.message || textStatus || 'Unknown error';
  const alert = $(`<div class="alert alert-danger" role="alert"><b>Server error:</b> ${text}&nbsp;&nbsp;<button class="close" data-dismiss="alert">×</button></div>`);
  $('#alert-anchor').append(alert);
  $('#loading').hide();
}
