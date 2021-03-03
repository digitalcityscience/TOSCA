/* global $, get */

get('/output', {}, res => new Promise(resolve => {
  const tbody = $('#results-table table tbody');
  res.list.sort().reverse();
  res.list.forEach(file => {
    const m = file.match(/.*(\d{4})-(\d{2})-(\d{2})_(\d{4})\.pdf$/);
    const date = new Date(m[1], m[2] - 1, m[3]);
    tbody.append(`<tr>
<td>${date.toDateString()}</td>
<td><a href="/output/${file}" target="_blank">${file}</a></td>
<td><button type="button" class="btn btn-outline-danger">Delete</button></td>
</tr>`)
  });
  resolve();
}));

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
