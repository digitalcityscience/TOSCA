function display() {
  const value = $('#results-select')[0].value;
  if (value != '') {
    $('#results-iframe').attr('src', '/output/' + value);
  } else {
    $('#results-iframe').attr('src', '');
  }
}

function hideResults() {
  $('#results-modal').hide();
}
