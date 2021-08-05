/* global $, L, t, map, drawnItems, refreshLayer, resultModal */
const selection = window['selection']
const fromPoints = window['time_map_from_points']
const strickenArea = window['time_map_stricken_area']
const timeMap = window['m1_time_map']
const sMap = window['Service_Area_Map']
let buffer_point, buffer_radius, buffered, buffered_layers=[], buffer_layer_remove=null, remove_buffer=[]
/**
 * Handle incoming messages from backend
 * @param {object} res backend response
 * @return Promise resolving if the message is processed successfully
 */

var points;

function clearBuffer(buffered_layers){
    if(buffered_layers.length > 0){
      buffered_layers.map(layer =>  map.removeLayer(layer))
    }
 }

function onLayerToggle(name, element){
  const layer = jsonData.filter(layer => layer.name == name)
  var ptsWithin = turf.pointsWithinPolygon(layer[0], buffered)
  if(element.checked){
    var layer_icon = L.icon({
      iconUrl: handleIcon(layer[0].name),
      iconSize: [32,37],
      iconAnchor: [16, 37],
      popupAnchor: [0, -28]
    });
    const buffer_layer = L.geoJSON(ptsWithin, {
      pointToLayer: function (feature, latlng) {
        return L.marker(latlng, {icon: layer_icon});
      }
    }).addTo(map)
    buffer_layer['id'] = name
    buffered_layers.push(buffer_layer)
  }
  else{
    remove_buffer = buffered_layers.filter(layer => layer.id == name)
    map.removeLayer(remove_buffer[0])
    buffered_layers=  buffered_layers.filter(layer => layer.id != name)
  }
}

function handleIcon(layer_name){
  if(layer_name == 'Police_Out_Post' || layer_name == 'Police_Stations'){
    const url = `images/Police.png`
    return url
  }
  else{
    const url = `images/${layer_name}.png`
    return url
  }
}

function handleResponse(res) {
  return new Promise((resolve) => {
    clearDialog();

    const messageId = res.id.replace(/\./g, '_');

    const textarea = $('#textarea');
    const buttonarea = $('#buttonarea');
    const lists = $('#lists');

    if (res.lat && res.lon) {
      map.panTo(new L.LatLng(res.lat, res.lon));
    }

    const list = (res.list || []).sort();

    $('#loading').hide();

    if (res.message) {
      let text = textElement(res.message), form, buttons;

      switch (res.id) {
        // The various actions required in response to server messages are defined here.

        // == add_location ==
        case 'add_location.1':
          buttons = [
            buttonElement(t['Yes']).click(() => {
              reply(res, 'yes');
            }),
            buttonElement(t['No']).click(() => {
              reply(res, 'no');
            })
          ];
          break;

        case 'add_location.4':
          form = formElement(messageId);
          form.append($(`<input id="${messageId}-input" type="file" name="file" />`));
          buttons = [
            buttonElement(t['Submit']).click(() => {
              $(`#${messageId}-error`).remove();
              const input = $(`#${messageId}-input`);
              if (input[0].files.length) {
                upload(form[0], { messageId: res.id }, handleResponse);
              } else {
                textarea.append($(`<span id="${messageId}-error" class="validation-error">${t['error:file upload']}</span>`));
              }
            })
          ];
          break;

        // == set_selection ==
        case 'set_selection.2':
          buttons = [
            buttonElement(t['Save']).click(() => {
              $(`#${messageId}-error`).remove();
              if (!saveDrawing(res)) {
                textarea.append($(`<span id="${messageId}-error" class="validation-error">${t['error:draw polygon']}</span>`));
              }
            })
          ];
          drawnItems.clearLayers();
          startDrawPolygon();
          break;

        case 'set_selection.3':
          refreshLayer(selection);
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
            buttonElement(t['Submit']).click(() => {
              $(`#${messageId}-error`).remove();
              const input = $(`#${messageId}-input`);
              if (!isNaN(parseInt(input.val()))) {
                reply(res, input.val());
              } else {
                textarea.append($(`<span id="${messageId}-error" class="validation-error">${t['error:number']}</span>`));
              }
            })
          ];
          break;

        // == add_map ==
        case 'add_map.1':
          buttons = [
            buttonElement(t['OK']).click(() => {
              reply(res, 'ok');
            })
          ];
          break;

        case 'add_map.2':
          form = formElement(messageId);
          form.append($(`<input id="${messageId}-input" type="file" name="file" />`));
          buttons = [
            buttonElement(t['Submit']).click(() => {
              $(`#${messageId}-error`).remove();
              const input = $(`#${messageId}-input`);
              if (input[0].files.length) {
                upload(form[0], { messageId: res.id }, handleResponse);
              } else {
                textarea.append($(`<span id="${messageId}-error" class="validation-error">${t['error:file upload']}</span>`));
              }
            })
          ];
          break;

        case 'add_map.3':
          form = formElement(messageId);
          form.append($(`<input id="${messageId}-input" type="text" value="${res.layerName}" />`));
          buttons = [
            buttonElement(t['Submit']).click(() => {
              $(`#${messageId}-error`).remove();
              const input = $(`#${messageId}-input`);
              if (input.val()) {
                reply(res, input.val());
              } else {
                textarea.append($(`<span id="${messageId}-error" class="validation-error">${t['error:name']}</span>`));
              }
            })
          ];
          break;

        // Input type selection
        case 'service_area.1':
          map.removeLayer(sMap);
          drawnItems.clearLayers();
          form = formElement(messageId);
          buttons = [
            buttonElement(t['Select point']).click(()=>{
              reply(res, 'Select point');
            }),
            buttonElement(t['Select Layer File']).click(()=>{
              reply(res, 'Select Layer File');
            })
          ];
          form.append(buttons);
          break;
        
        // Draw circle marker
        case 'service_area.3':
          drawnItems.clearLayers();
          startDrawCirclemarker();
          form = formElement(messageId)
          buttons = [
            buttonElement(t['Save']).click(() => {
              $(`#${messageId}-error`).remove();
              if (!saveDrawing(res)) {
                textarea.append($(`<span id="${messageId}-error" class="validation-error">${t['error:draw point']}</span>`));
              }
              reply(res, 'Point Selected');
            }),
            buttonElement(t['Cancel']).click(() => {
              reply(res, 'cancel');
            })
          ];
          break;

        // Select point layer file
        case 'service_area.4':
          const LayerFilesArray = ["Bank Locations", "Mo Bus Stops BMC"] // File names should contain spaces only
          let optionsAppend = '';
          LayerFilesArray.forEach(function(arrayItem){
            var arr = arrayItem.split(" ");
            var valueItem = arr.join("_");
            optionsAppend += " <option value="+valueItem+">"+ arrayItem + "<option/> ";
          })
          form = formElement(messageId);
          form.append($(`<select id="${messageId}-input" class='custom-select custom-select-sm mr-2'> ${optionsAppend} <select/>`));

          buttons = [
            buttonElement(t['Submit']).click(()=> {
              $(`#${messageId}-error`).remove();
              const input = $(`#${messageId}-input`);
              if(input.val()){
              reply(res, input.val())}
              else{
                textarea.append($(`<span id="${messageId}-error" class="validation-error"> ${t['error:layer select']}</span>`))
              }
            })
          ];
          break;
        
        // Take input for cost parameter and request to process the python script
        case 'service_area.5':
          form = formElement(messageId);
          form.append($(`<input id="${messageId}-input" type="number" />`));
          form.append($(`<span>&nbsp;m</span>`));
          buttons = [
            buttonElement(t['Submit']).click(() => {
              $(`#${messageId}-error`).remove();
              const input = $(`#${messageId}-input`);
              if (!isNaN(parseInt(input.val()))) {
                if(points){
                sendMessage('/execFile', {}, { messageId: res.id , msg: 'Output from selected point', val: input.val(), longg: points[0], latt: points[1]}, handleResponse);
                points = null;
                }
                else{
                sendMessage('/execFile', {}, { messageId: res.id , msg: 'Output from layer file', val: input.val(), LayerFile: res.Layer}, handleResponse);
                }
              } 
              else {
                textarea.append($(`<span id="${messageId}-error" class="validation-error">${t['error:number']}</span>`));
              }
            })
          ];
          form.append(buttons);
          break;

        // EndScreen options, Load layers, Export map with layers toggeled
        case 'service_area.2':
          refreshLayer(sMap);
          map.addLayer(sMap);
          cancelDrawing();

          form = formElement(messageId);
          buttons = [
            buttonElement(t['Export Map']).click(()=> {
              handleResponse({id: 'service_area.7', message: "You can choose to either export the Printable Map in Landscape mode or in Portrait mode"})
            })
          ];
          break;
        
        case 'service_area.7':

          form = formElement(messageId);
          buttons = [

            // Landscape print button -------------------------------------------------------------------------
            buttonElement(t['Landscape mode'], 'leaflet-browser-print--manualMode-button').click(() => {
              var legcontent = null;
              const options = {
                printModes: [
                  L.control.browserPrint.mode.landscape(),
                ],
                manualMode: false,
                pagesSelector: "[leaflet-browser-print-pages-serviceArea]",
                contentSelector: "[leaflet-browser-print-content-serviceArea]",
              }
              L.control.browserPrint(options).addTo(map)

              // Get Legend content as html before print starts
              map.on('browser-pre-print', function(e){
                legcontent = document.getElementById("leaflet-legend-content");
                htmlcontent = document.querySelectorAll(".leaflet-legend-item");
                legcontent.style.maxHeight = "inherit";
                appendedLegContent = formatContent(htmlcontent);
                $("#service-area-output-legend").html(appendedLegContent);
              })

              // Add the legend content to its respective div element after print is over
              map.on('browser-print-end', function(e){
                legcontent.style.maxHeight = "";
                document.getElementById("leaflet-legend-container").append(legcontent)
              })
              var modeToUse = L.control.browserPrint.mode.landscape();
              map.printControl.print(modeToUse);
            }),

            // Portrait print button -------------------------------------------------------------------------
            buttonElement(t['Portrait mode'], 'leaflet-browser-print--manualMode-button').click(() => {
              var legcontent = null;
              const options = {
                printModes: [
                  L.control.browserPrint.mode.portrait(),
                ],
                manualMode: false,
                pagesSelector: "[leaflet-browser-print-pages-serviceArea]",
                contentSelector: "[leaflet-browser-print-content-serviceArea]",
              }
              L.control.browserPrint(options).addTo(map)

              // Get Legend content as html before print starts
              map.on('browser-pre-print', function(e){
                legcontent = document.getElementById("leaflet-legend-content");
                htmlcontent = document.querySelectorAll(".leaflet-legend-item");
                legcontent.style.maxHeight = "inherit";
                appendedLegContent = formatContent(htmlcontent);
                $("#service-area-output-legend").html(appendedLegContent);
              })

              // Add the legend content to its respective div element after print is over
              map.on('browser-print-end', function(e){
                legcontent.style.maxHeight = "";
                document.getElementById("leaflet-legend-container").append(legcontent)
              })
              var modeToUse = L.control.browserPrint.mode.portrait();
              map.printControl.print(modeToUse);
            }),
          ];
          form.append(buttons);

          break;

        // == time map module ==
        // Start points

        // Travel mode
        case 'time_map.0':
          map.removeLayer(fromPoints);
          map.removeLayer(strickenArea);
          map.removeLayer(timeMap);
          map.legend.toggleLegendForLayer(false, timeMap);

          form = formElement(messageId);
          buttons = [
            buttonElement(t['Automobile']).click(() => {
              // timeMap.setParams({styles: 'time_map_vector_car'});
              reply(res, 'Automobile');
            }),
            buttonElement(t['Bicycle']).click(() => {
              // timeMap.setParams({styles: 'time_map_vector_bicycle'});
              reply(res, 'Bicycle');
            }),
            buttonElement(t['Walking']).click(() => {
              // timeMap.setParams({styles: 'time_map_vector_walking'});
              reply(res, 'Walking');
            })
          ];
          form.append(buttons);
          break;

        // Start points
        case 'time_map.1':
          refreshLayer(fromPoints);
          refreshLayer(strickenArea);
          map.addLayer(selection);

          drawnItems.clearLayers();
          startDrawCirclemarker();

          buttons = [
            buttonElement(t['Save']).click(() => {
              $(`#${messageId}-error`).remove();
              if (!saveDrawing(res)) {
                textarea.append($(`<span id="${messageId}-error" class="validation-error">${t['error:draw point']}</span>`));
              }
            }),
            buttonElement(t['Cancel']).click(() => {
              reply(res, 'cancel');
            })
          ];
          break;

        // stricken area
        case 'time_map.3':
          refreshLayer(fromPoints);
          map.addLayer(fromPoints);

          drawnItems.clearLayers();
          startDrawPolygon();

          buttons = [
            buttonElement(t['Save']).click(() => {
              $(`#${messageId}-error`).remove();
              if (!saveDrawing(res)) {
                textarea.append($(`<span id="${messageId}-error" class="validation-error">${t['error:draw polygon']}</span>`));
              }
            }),
            buttonElement(t['Skip']).click(() => {
              reply(res, 'cancel');
            })
          ];
          break;

        // Speed reduction ratio
        case 'time_map.4':
          refreshLayer(strickenArea);
          map.addLayer(strickenArea);

          cancelDrawing();
          drawnItems.clearLayers();

          form = formElement(messageId);
          form.append($(`<input id="${messageId}-input" type="number" />`));
          form.append($(`<span>&nbsp;%</span>`));
          buttons = [
            buttonElement(t['Submit']).click(() => {
              const input = $(`#${messageId}-input`);
              reply(res, input.val());
            })
          ];
          break;

        // Done
        case 'time_map.6':
          map.legend.toggleLegendForLayer(false, timeMap);
          map.legend.toggleLegendForLayer(true, timeMap);
          refreshLayer(timeMap);
          map.addLayer(timeMap);

          // refresh the legend
          map.legend.toggleLegendForLayer(false, timeMap);
          map.legend.toggleLegendForLayer(true, timeMap);

          cancelDrawing();
          drawnItems.clearLayers();

          if (res.result) {
            form = formElement(messageId);
            buttons = [
              buttonLinkElement(t['Open result'], 'output/' + res.result)
            ];
          }
          break;

        case 'buffer_module.1' : {
          clearBuffer(buffered_layers)
          if(buffer_layer_remove){
            map.removeLayer(buffer_layer_remove)
          }
         
            map.addLayer(selection);

            drawnItems.clearLayers();
            startDrawCirclemarker();

            buttons = [
              buttonElement(t['Save']).click(() => {
                $(`#${messageId}-error`).remove();
                if (!saveDrawing(res)) {
                  textarea.append($(`<span id="${messageId}-error" class="validation-error">${t['error:draw point']}</span>`));
                }
              }),
              buttonElement(t['Cancel']).click(() => {
                reply(res, 'cancel');
              })
            ];
            break;
        }

        case 'buffer_module.2' : {
          // L.geoJSON(buffer_point).addTo(map);
          form = formElement(messageId);
          form.append($(`<input id="${messageId}-input" type="number" />`));
          form.append($(`<span>&nbsp;m</span>`));
          buttons = [
            buttonElement(t['Submit']).click(() => {
              const input = $(`#${messageId}-input`);
              buffer_radius = input.val()
              reply(res, input.val());
            })
          ];
          break;
        }
        case 'buffer_module.3' : {
          buffered = turf.buffer(buffer_point, buffer_radius, {units: 'meters'})
          drawnItems.clearLayers();
          buffer_layer_remove = L.geoJSON(buffered, {
            pointToLayer: function (feature, latlng) {
              console.log(latlng,"buffer module");
              return L.circle(latlng)
            }
          }).addTo(map)
          const items = layers.filter(service => service.buffered)
          form = formElement(messageId);
          let innerHTML = ""
          items.map(service => {
            innerHTML += `<input type="checkbox" id="${service.id}-input" value='${service.layers}' onchange='onLayerToggle("${service.layers}", this)'}'/><span>&nbsp</span><label>${service.displayName}</label></br>`}) 
          lists.append($(`<form>` + innerHTML + `</form>`))
          buttons = [
            buttonElement(t['Submit'], 'leaflet-browser-print--manualMode-button').click(() => {
              showBuffer(buffered_layers)
              const options = {
                printModes: [
                  L.control.browserPrint.mode.auto("Automatico", "A6"),
                ],
                manualMode: false
              }
              L.control.browserPrint(options).addTo(map)
              var modeToUse = L.control.browserPrint.mode.auto("Automatico", "A6");
              map.printControl.print(modeToUse);
            })
          ];
          break;
        }
          // == query module ==
        case 'query.2':
          if(buffer_layer_remove){
            map.removeLayer(buffer_layer_remove)
          }
          clearBuffer(buffered_layers)
          form = formElement(messageId);
          lists.append($(`<select id="${messageId}-input" class='custom-select' size="10">` + list.map(col => `<option selected value="${col}">${col}</option>`) + `</select>`));
          buttons = [
            buttonElement(t['Show attributes']).click(() => {
              const input = $(`#${messageId}-input`);
              getAttributes(input[0].value)
            }),
            buttonElement(t['Submit']).click(() => {
              const input = $(`#${messageId}-input`);
              reply(res, input[0].value);
            })
          ];
          break;

        case 'query.3': {
          const query = $(`<div class='query'></div>`)
          query.append(conditionElement(list))
          lists.append(query);

          buttons = [
            buttonElement(t['Show attributes']).click(() => {
              getAttributes(res.map)
            }),
            buttonElement('＋').click(() => {
              const len = $('.query').length
              const query = $(`<div class='query'></div>`)
              if (len > 0) query.append(relationSelect())
              query.append(conditionElement(list))
              lists.append(query);
            }),
            buttonElement(t['OK']).click(() => {
              $(`#${messageId}-error`).remove();
              let msg = []
              const querys = $('.query')

              // inputs.map is problematic because jquery objs behave differently
              for (const query of querys) {
                const isNumeric = $(query).find('.val').length
                // character-type column
                if (isNumeric) {
                  const [rel, sel, val] = [
                    $(query).find('.rel').val(),
                    $(query).find('.sel').val(),
                    $(query).find('.val').val()
                  ]
                  msg.push({ 'column': sel, 'isNumeric': isNumeric, 'where': `${sel} = '${val}'` })
                  if (rel !== undefined) msg[msg.length - 1].where = rel + ' ' + msg[msg.length - 1].where
                }
                // numeric-type column
                else {
                  const [rel, sel, min, max] = [
                    $(query).find('.rel').val(),
                    $(query).find('.sel').val(),
                    $(query).find('.min').val(),
                    $(query).find('.max').val()
                  ]
                  if (validateNum(min) && validateNum(max)) {
                    msg.push({ 'column': sel, 'isNumeric': isNumeric, 'where': `${sel} >= ${min} AND ${sel} <= ${max}` })
                    if (rel !== undefined) msg[msg.length - 1].where = rel + ' ' + msg[msg.length - 1].where
                  } else {
                    msg = []
                    textarea.append($(`<span id="${messageId}-error" class="validation-error">${t['error:form numbers']}</span>`));
                    break
                  }
                }
              }
              if (msg.length) reply(res, msg)
            })
          ];
          break;
        }

        case 'query.24':
          if (res.result) {
            form = formElement(messageId);
            buttons = [
              buttonLinkElement(t['Open result'], 'output/' + res.result)
            ];
          }
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

    resolve();
  });
}

function textElement(text) {
  return $(`<div class="textarea-text">${text}</div>`);
}

function formElement(id, isMultipart) {
  return $(`<form id="${id}-form" enctype="${isMultipart ? 'multipart/form-data' : ''}" onsubmit="event.preventDefault()"></form>`);
}

function buttonElement(action, id) {
  return $(`<button type="button" class="btn btn-primary" id=${id}>${action}</button>`);
}

function buttonLinkElement(action, url) {
  return $(`<a type="button" class="btn btn-primary" href="${url}" target="_blank">${action}</a>`);
}

function relationSelect() {
  const relationOption = ['AND', 'OR'].map(el => `<option value="${el}">${el}</option>`);
  return $(`<select class="rel custom-select mb-2">${relationOption}</select>`)
}

function conditionElement(data, id) {
  const firstData = data[0]
  const container = $(`<div class='card-body border-info m-0 p-10'></div>`)
  const row1 = $(`<div class='d-flex mb-2' id='${id}'><small>${t['query attribute']}</small></div>`)
  const columns = data.map(item => `<option value="${item.column}">${item.column}</option>`)
  const select = $(`<select class='custom-select mr-2 ml-2 sel'>${columns}</select>`)
  const remove = $('<button type="button" class="btn btn-secondary ml-2">&times;</button>')

  row1.append(select)
  row1.append(remove)
  container.append(row1)
  if (['DOUBLE PRECISION', 'INTEGER'].indexOf(firstData.type) > -1) {
    container.append(boundSetter(firstData.bounds))
  } else {
    container.append(charSelector(firstData.vals))
  }

  remove.click((e) => {
    $(e.target).parent().parent().parent().remove();
  })

  select.change((e) => {
    const selected = data.filter(d => d.column === e.target.value)[0]
    if (['DOUBLE PRECISION', 'INTEGER'].indexOf(selected.type) > -1) {
      row1.next().remove()
      container.append(boundSetter(selected.bounds))
      const bounds = selected.bounds
      const min = $(e.target).parent().parent().find('.min-badge')
      const max = $(e.target).parent().parent().find('.max-badge')
      min.html('>= ' + bounds[0])
      max.html('<= ' + bounds[1])
    } else {
      row1.next().remove()
      container.append(charSelector(selected.vals))
      const sel = $(e.target).parent().parent().find('select')
      sel.html(selected.values)
    }

  })
  return container
}

/**
 * create bound setters for numeric-type columns
 * @param {array} bounds [min, max]
 */
function boundSetter(bounds) {
  return $(`
<div class='row justify-content-between mb-2'>
  <small class='col-md-2'>${t['min']} <span class='min-badge badge badge-secondary'> >= ${bounds[0]}</span></small>
  <input type='number' class='col-md-10 form-control min'>
  <small class='col-md-2'>${t['max']} <span class='max-badge badge badge-secondary'> <= ${bounds[1]}</span></small>
  <input type='number' class='col-md-10 form-control max'>
</div>`)
}

/**
 * create value selectors for character-type columns
 * @param {array} values
 */
function charSelector(values) {
  const options = values.map(value => `<option value="${value}">${value}</option>`)
  return $(`
<div class='row mb-2'>
  <small class='col-md-2'>value</small>
  <select class='col-md-10 custom-select mr-2 val'>${options}</select>
</div>`)
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
function onClickResults() {
  $('#results-modal').show()
  resultModal.updateResults();
}

function showBuffer(buffered_layers){
  let html = "<tbody>";
  buffered_layers.map(layer => {
    const number_of_point_layers = Object.keys(layer._layers).length
    html += "<tr><td>" + layer['id']+ "</td>"
    html += "<td>"+ number_of_point_layers +  "</td></tr>"
  })
  html = html + "</tbody>";
  $('#buffer-output').html(html)
}

function formatContent(legcontent){
  let html = `<tbody>`;
  legcontent.forEach((content) => {
    html += `<tr><td>  ${content.innerText}  </td>`
    // console.log(content, content.getElementsByTagName('img'))
    html += `<td> <img src="${content.getElementsByTagName('img')[0].src}"  </td></tr>`
  })
  html = html + `</tbody>`;
  // console.log(html)
  return html;
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

function cancelDrawing() {
  const btn = $('.leaflet-draw-actions li:contains("Cancel") a')[0];
  btn && btn.dispatchEvent(new Event('click'));
}

/* Send messages to the backend */

// eslint-disable-next-line no-unused-vars
function launchModule() {
  // Get the selected item
  const value = $('#launch-module-menu')[0].value;
  if(value == 'buffer'){
    const res = {
      id: "buffer_module.1",
      message: "A start point is required. Use the circlemarker tool to draw a start point"
    }
    handleResponse(res)
  }

  else{
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
  if(res.id == 'buffer_module.1'){
    const res = {
      id : 'buffer_module.4',
      message : 'Process Cancelled.'
    }
    handleResponse(res)
  }
  else if(res.id == 'buffer_module.2'){
    const res = {
      id : 'buffer_module.3',
      message : 'Select Layers'
    }
    handleResponse(res)
  }else{
  sendMessage('/reply', { msg: message }, { messageId: res.id }, handleResponse);
  }
}

function saveDrawing(res) {
  const geojson = drawnItems.toGeoJSON();
  buffer_point = geojson
  points = geojson["features"][0]["geometry"]["coordinates"];
  if (geojson.features.length === 0) {
    return false;
  }
  sendMessage('/drawing', { data: geojson }, { messageId: res.id }, handleResponse);
  return true;
}

function getAttributes(table) {
  get('/attributes', { table }, (res) => new Promise((resolve) => {
    const { tableObj, columnObj } = JSON.parse(res.attributes);
    // the headFields are GRASS GIS attribute names (except 'min' and 'max')
    const cObj = { headFields: ['column', 'type', 'description', 'min', 'max'], rows: [] };
    // filter unwanted fields
    for (const row of columnObj.rows) {
      if (row.column !== 'cat') {
        cObj.rows.push({ 'column': row.column, 'type': row.type, 'description': row.description, 'min': row.min, 'max': row.max });
      }
    }
    $('#table-header').text(`Table description for ${tableObj.table}`);
    $('#table-description').text(tableObj.description);
    $('#column-description').html(tableElement('table table-bordered', cObj));
    $('#table-attributes-modal').show();
    resolve();
  }));
}

function sendMessage(target, message, params, callback) {
  $('#loading').show();
if(params.messageId == 'buffer_module.1'){
  const res = {
    id: "buffer_module.2",
    message : "Enter radius in meters"
  }
    handleResponse(res)
}

  else
{  $.ajax({
    type: 'POST',
    url: target + '?' + $.param(params),
    data: JSON.stringify(message),
    dataType: 'json',
    contentType: 'application/json; encoding=utf-8',
    error: onServerError
  })
    .done(res => {
      callback(res).catch(onClientError)})
    .always(() => $('#loading').hide())}
}

function get(target, params, callback) {
  $('#loading').show();

  $.ajax({
    type: 'GET',
    url: target + '?' + $.param(params),
    contentType: 'application/json; encoding=utf-8',
    error: onServerError
  })
    .done(res => callback(res).catch(onClientError))
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
    .done(res => callback(res).catch(onClientError))
    .always(() => $('#loading').hide());
}

// eslint-disable-next-line no-unused-vars
function deleteMethod(target, params, callback) {
  $('#loading').show();

  $.ajax({
    type: 'DELETE',
    url: target + '?' + $.param(params),
    contentType: 'application/json; encoding=utf-8',
    error: onServerError
  })
    .done(res => callback(res).catch(onClientError))
    .always(() => $('#loading').hide())
}

function onClientError(error) {
  console.error(error);
  const text = $('<span>').text(error.message);
  const alert = $('<div class="alert alert-danger" role="alert"></div>');
  alert.append($(`<b>${t['Client error']}: </b>`)).append(text).append($('<button class="close" data-dismiss="alert">×</button>'));
  $('#alert-anchor').append(alert);
}

function onServerError(xhr, textStatus) {
  const text = $('<span>').text(xhr.responseJSON && xhr.responseJSON.message || textStatus || t['Unknown error']);
  const alert = $('<div class="alert alert-danger" role="alert"></div>');
  alert.append($(`<b>${t['Server error']}: </b>`)).append(text).append($('<button class="close" data-dismiss="alert">×</button>'));
  $('#alert-anchor').append(alert);
}
