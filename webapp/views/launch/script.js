var saveFile = () => {
  // Get the data from each element on the form.
  const item_1 = document.getElementById('Select_menu');
  var data = '' + item_1.value + '\n';
  const textToBLOB = new Blob([data], { type: 'text/plain' });
  const sFileName = 'launch';
  var newLink = document.createElement('a');
  newLink.download = sFileName;
  if (window.webkitURL != null) {
    newLink.href = window.webkitURL.createObjectURL(textToBLOB);
  }
  else {
    newLink.href = window.URL.createObjectURL(textToBLOB);
    newLink.style.display = 'none';
    document.body.appendChild(newLink);
  }
  newLink.click();
}

var saveFile_2 = () => {
  // Get the data from each element on the form.
  const item_2 = document.getElementById('Display_menu');
  var data = '' + item_2.value + '\n';
  const textToBLOB = new Blob([data], { type: 'text/plain' });
  const sFileName = 'display';
  var newLink = document.createElement('a');
  newLink.download = sFileName;
  if (window.webkitURL != null) {
    newLink.href = window.webkitURL.createObjectURL(textToBLOB);
  }
  else {
    newLink.href = window.URL.createObjectURL(textToBLOB);
    newLink.style.display = 'none';
    document.body.appendChild(newLink);
  }
  newLink.click();
}

var saveFile_3 = () => {
  // Get the data from each element on the form.
  const item_3 = document.getElementById('Query_menu');
  var data = '' + item_3.value + '\n';
  const textToBLOB = new Blob([data], { type: 'text/plain' });
  const sFileName = 'query';
  var newLink = document.createElement('a');
  newLink.download = sFileName;
  if (window.webkitURL != null) {
    newLink.href = window.webkitURL.createObjectURL(textToBLOB);
  }
  else {
    newLink.href = window.URL.createObjectURL(textToBLOB);
    newLink.style.display = 'none';
    document.body.appendChild(newLink);
  }
  newLink.click();
}
