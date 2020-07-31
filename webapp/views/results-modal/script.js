function display() {
    const value = $('#results-select')[0].value;
    $('#results-iframe').attr('src', '/output/' + value)
}

function hide_results() {
    $('#results-modal').hide()
}