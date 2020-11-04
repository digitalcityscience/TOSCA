/* global $ */

// eslint-disable-next-line no-unused-vars
function display() {
  const value = $('#results-select')[0].value;
  if (value != '') {
    $('#results-iframe').attr('src', '/output/' + value);
  } else {
    $('#results-iframe').attr('src', '');
  }
}

// eslint-disable-next-line no-unused-vars
function hideResults() {
  $('#results-modal').hide();
}
