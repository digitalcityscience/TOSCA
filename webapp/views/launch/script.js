/* global $, L, map, drawnItems, selection */

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

      case 'add_location.4':
        form = formElement(messageId);
        form.append($(`<input id="${messageId}-input" type="file" name="file" />`));
        buttons = [
          buttonElement('Submit').click(() => {
            $(`#${messageId}-error`).remove();
            const input = $(`#${messageId}-input`);
            if (input[0].files.length) {
              upload(form[0], { messageId: res.message_id }, handleResponse);
            } else {
              textarea.append($(`<span id="${messageId}-error" class="validation-error">Please choose a file for upload.</span>`));
            }
          })
        ];
        break;

      // == set_selection ==
      case 'set_selection.2':
        buttons = [
          buttonElement('Save').click(() => {
            $(`#${messageId}-error`).remove();
            if (!saveDrawing(res)) {
              textarea.append($(`<span id="${messageId}-error" class="validation-error">Please draw a polygon using the map’s drawing tool.</span>`));
            }
          })
        ];
        drawnItems.clearLayers();
        startDrawPolygon();
        break;

      case 'set_selection.3':
        // Force reloading of the selection layer
        selection.setParams({ ts: Date.now() });
        map.addLayer(selection);
        drawnItems.clearLayers();
        break;

      // == set_resolution ==
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
      case 'add_map.1':
        buttons = [
          buttonElement('OK').click(() => {
            reply(res, 'ok');
          })
        ];
        break;

      case 'add_map.2':
        form = formElement(messageId);
        form.append($(`<input id="${messageId}-input" type="file" name="file" />`));
        buttons = [
          buttonElement('Submit').click(() => {
            $(`#${messageId}-error`).remove();
            const input = $(`#${messageId}-input`);
            if (input[0].files.length) {
              upload(form[0], { messageId: res.message_id }, handleResponse);
            } else {
              textarea.append($(`<span id="${messageId}-error" class="validation-error">Please choose a file for upload.</span>`));
            }
          })
        ];
        break;

      case 'add_map.3':
        form = formElement(messageId);
        form.append($(`<input id="${messageId}-input" type="text" value="${res.message.layerName}" />`));
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
        drawnItems.clearLayers();
        startDrawCirclemarker();
        break;

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
        drawnItems.clearLayers();
        startDrawPolygon();
        break;

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
        map.addLayer(selection);
        drawnItems.clearLayers();
        startDrawCirclemarker();
        break;

      // stricken area
      case 'module_1a.3':
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
        drawnItems.clearLayers();
        startDrawPolygon();
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
        buttons = [
          buttonElement('Save').click(() => {
            $(`#${messageId}-error`).remove();
            if (!saveDrawing(res)) {
              textarea.append($(`<span id="${messageId}-error" class="validation-error">Please draw a polygon using the map’s drawing tool.</span>`));
            }
          })
        ];
        drawnItems.clearLayers();
        startDrawPolygon();
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
        const query = $(`<div class='query'></div>`)
        query.append(conditionElement(list))
        lists.append(query);

        buttons = [
          buttonElement('Show attributes').click(() => {
            getAttributes(res.message.map)
          }),
          buttonElement('＋').click(() => {
            len = $('.query').length
            const query = $(`<div class='query'></div>`)
            if (len > 0) query.append(relationSelect())
            query.append(conditionElement(list))
            lists.append(query);
          }),
          buttonElement('OK').click(() => {
            $(`#${messageId}-error`).remove();
            let msg = []
            const querys = $('.query')

            // inputs.map is problematic because jquery objs behave differently
            for (const query of querys) {
              const [rel, sel, min, max] = [
                $(query).find('.rel').val(),
                $(query).find('.sel').val(),
                $(query).find('.min').val(),
                $(query).find('.max').val()
              ]
              if (rel != undefined) msg.push(rel)
              if (validateNum(min) && validateNum(max)) {
                msg.push(sel, '>=', min, 'AND', sel, '<=', max)
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

      /* Cotopaxi module */

      // Choose type of volcanic threat
      case 'cotopaxi_scenarios.0':
        form = formElement(messageId);
        buttons = [
          buttonElement('Ash fall').click(() => {
            reply(res, 'ash_fall');
          }),
          buttonElement('Lahar flows').click(() => {
            reply(res, 'lahar_flow');
          }),
          buttonElement('Lava flows').click(() => {
            reply(res, 'lava_flow');
          })
        ];
        form.append(buttons);
        break;

      // Upload dataset containing risk zones
      case 'cotopaxi_scenarios.1':
        form = formElement(messageId);
        form.append($(`<input id="${messageId}-input" type="file" name="file" />`));
        buttons = [
          buttonElement('Submit').click(() => {
            $(`#${messageId}-error`).remove();
            const input = $(`#${messageId}-input`);
            if (input[0].files.length) {
              upload(form[0], { message_id: res.message_id }, handleResponse);
            } else {
              textarea.append($(`<span id="${messageId}-error" class="validation-error">Please choose a file to upload.</span>`));
            }
          })
        ];
        break;

      // Select scenario (i.e., feature of risk zones layer)
      case 'cotopaxi_scenarios.2':
        form = formElement(messageId);
        lists.append($(`<select id="${messageId}-input" class='custom-select' size="10">` + list.map(col => `<option selected value="${col}">${col}</option>`) + `</select>`));
        buttons = [
          buttonElement('Submit').click(() => {
            const input = $(`#${messageId}-input`);
            reply(res, input[0].value);
          })
        ];
        break;

      // Select dataset for analysis
      case 'cotopaxi_scenarios.3':
        form = formElement(messageId);
        lists.append($(`<select id="${messageId}-input" class='custom-select' size="10">` + list.map(col => `<option selected value="${col}">${col}</option>`) + `</select>`));
        buttons = [
          buttonElement('Submit').click(() => {
            const input = $(`#${messageId}-input`);
            reply(res, input[0].value);
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

function relationSelect() {
  const relationOption = ['AND', 'OR'].map(el => `<option value="${el}">${el}</option>`);
  return $(`<select class="rel custom-select mb-2">${relationOption}</select>`)
}

function conditionElement(data, id) {
  const container = $(`<div class='card-body border-info m-0 p-10'></div>`)
  const row1 = $(`<div class='d-flex mb-2' id='${id}'><small>query attribute</small></div>`)
  const columns = data.map(item => `<option value="${item.column}">${item.column}</option>`)
  const select = $(`<select class='custom-select mr-2 ml-2 sel'>${columns}</select>`)
  const remove = $('<button type="button" class="btn btn-secondary ml-2">&times;</button>')
  const row2 = $(`
  <div class='d-flex justify-content-between mb-2'>
    <small>min <span class='min-badge badge badge-secondary'> >= ${data[0].bounds[0]}</span></small>
    <input id='${id}-input-min' type='number' class='form-control ml-2 mr-2 min'>
  </div>
  <div class='d-flex justify-content-between mb-2'>
    <small>max <span class='max-badge badge badge-secondary'> <= ${data[0].bounds[1]}</span></small>
    <input id='${id}-input-max' type='number' class='form-control ml-2 mr-2 max'>
  </div>
  `)

  row1.append(select)
  row1.append(remove)
  container.append(row1)
  container.append(row2)

  remove.click((e) => {
    $(e.target).parent().parent().parent().remove();
  })

  select.change((e) => {
    const bounds = data.filter(d => d.column === e.target.value)[0].bounds
    const min = $(e.target).parent().parent().find('.min-badge')
    const max = $(e.target).parent().parent().find('.max-badge')
    min.html('>= ' + bounds[0])
    max.html('<= ' + bounds[1])
  })
  return container
}

/**
 * create a table element from data
 * @param {Array} data an array of identically structured js objects
 * @param {string} className className of the table
 */
function tableElement(className, data) {
  const table = $(`<table class=${className}><tr>`)
  const headRow = $(`<tr></tr>`)

  table.append(headRow)
  data.headFields.forEach(field => {
    headRow.append($(`<th>${field}</th>`))
  })

  data.rows.forEach(row => {
    const contentRow = $(`<tr></tr>`)
    table.append(contentRow)

    Object.keys(row).forEach(field => {
      contentRow.append($(`<td>${row[field]}</td>`))
    })
  })

  return table
}

function clearDialog() {
  $('#textarea').empty();
  $('#buttonarea').empty();
  $('#lists').empty();
}

function validateNum(num) {
  return !isNaN(parseFloat(num))
}

// eslint-disable-next-line no-unused-vars
function showResults() {
  getOutput({})
  $('#results-modal').show()
  // empty iframe content
  $('#results-iframe').attr('src', '')
}

// eslint-disable-next-line no-unused-vars
function showHelp() {
  $('#help-modal').show()
}

let blinkTimeout;
// eslint-disable-next-line no-unused-vars
function blink(selector) {
  if (!blinkTimeout) {
    $(selector).addClass("blink");
    blinkTimeout = setTimeout(function () {
      blinkTimeout = null;
      $(selector).removeClass("blink");
    }, 3600);
  }
}

// eslint-disable-next-line no-unused-vars
function removeCondition(e) {
  const rootNode = e.parentNode.parentNode;
  rootNode.parentNode.removeChild(rootNode);
}

function startDrawPolygon() {
  const btn = $('.leaflet-draw-draw-polygon')[0];
  btn && btn.dispatchEvent(new Event('click'));
}

function startDrawCirclemarker() {
  const btn = $('.leaflet-draw-draw-circlemarker')[0];
  btn && btn.dispatchEvent(new Event('click'));
}

/* Send messages to the backend */

// eslint-disable-next-line no-unused-vars
function launchModule() {
  // Get the selected item
  const value = $('#launch-module-menu')[0].value;
  if (value) {
    sendMessage('/launch', { launch: value }, {}, handleResponse);
  }
}

// eslint-disable-next-line no-unused-vars
function launchSettings(value) {
  if (value) {
    sendMessage('/launch', { launch: value }, {}, handleResponse);
  }
}

function reply(res, message) {
  sendMessage('/reply', { msg: message }, { messageId: res.message_id }, handleResponse);
}

function saveDrawing(res) {
  const geojson = drawnItems.toGeoJSON();
  if (geojson.features.length === 0) {
    return false;
  }
  sendMessage('/drawing', { data: geojson }, { messageId: res.message_id }, handleResponse);
  return true;
}

function getOutput() {
  get('/output', {}, function (res) {
    const baseOption = "<option selected value=''> - </option>"
    const options = res.list.reduce((str, file) => str + `<option value="${file}">${file}</option>`, '')
    $('#results-select').html(baseOption + options)
  })
}

function getAttributes(table) {
  get('/attributes', { table }, function (res) {
    const { tableObj, columnObj } = JSON.parse(res.attributes)

    // the headFields are GRASS GIS attribute names (except 'min' and 'max')
    const tObj = { headFields: ['table', 'description'], rows: [] }
    const cObj = { headFields: ['column', 'description', 'min', 'max'], rows: [] }
    // filter unwanted fields
    for (const row of tableObj.rows) {
      tObj.rows.push({ 'table': row.table, 'description': row.description })
    }
    for (const row of columnObj.rows) {
      if (['DOUBLE PRECISION', 'INTEGER'].indexOf(row.type) > -1 &&
        ['cat'].indexOf(row.column) == -1)
        cObj.rows.push({ 'column': row.column, 'description': row.description, 'min': row.min, 'max': row.max })
    }

    $('#table-description').html(tableElement('table table-bordered', tObj))
    $('#column-description').html(tableElement('table table-bordered', cObj))
    $('#table-attributes-modal').show()
  })
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
    .always(() => $('#loading').hide())
}

function get(target, params, callback) {
  $('#loading').show();

  $.ajax({
    type: 'GET',
    url: target + '?' + $.param(params),
    contentType: 'application/json; encoding=utf-8',
    error: onServerError
  })
    .done(callback)
    .always(() => $('#loading').hide())
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
  const text = $('<span>').text(xhr.responseJSON && xhr.responseJSON.message || textStatus || 'Unknown error');
  const alert = $('<div class="alert alert-danger" role="alert"></div>');
  alert.append($('<b>Server error: </b>')).append(text).append($('<button class="close" data-dismiss="alert">×</button>'));
  $('#alert-anchor').append(alert);
  $('#loading').hide();
}