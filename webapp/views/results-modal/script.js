/* global $, get, deleteMethod */

/**
 * result modal class
 */
class ResultModal {
  constructor(data = [], resultToDelete = '', currentView = 'ALL') {
    this._data = data;
    this.resultToDelete = resultToDelete;
    this.currentView = currentView;
  }

  get dataAll() {
    return this._data;
  }
  set dataAll(val) {
    this._data = val;
  }
  get dataTimeMap() {
    return this._data.filter(str => str.match(/^time/));
  }
  get dataQuery() {
    return this._data.filter(str => str.match(/^query/));
  }

  remove(file) {
    this.dataAll.splice(this.dataAll.indexOf(file), 1);
  }

  onClickTimeMap() {
    const tbody = $('#results-table table tbody').empty();
    $('#all-btn').removeClass('active');
    $('#query-btn').removeClass('active');
    $('#time-map-btn').addClass('active');

    this.currentView = 'TIMEMAP';
    this.dataTimeMap.forEach(file => {
      this.appendItem(tbody, file);
    });
  }

  onClickQuery() {
    const tbody = $('#results-table table tbody').empty();
    $('#all-btn').removeClass('active');
    $('#query-btn').addClass('active');
    $('#time-map-btn').removeClass('active');

    this.currentView = 'QUERY';
    this.dataQuery.forEach(file => {
      this.appendItem(tbody, file);
    });
  }

  onClickAll() {
    const tbody = $('#results-table table tbody').empty();
    $('#all-btn').addClass('active');
    $('#query-btn').removeClass('active');
    $('#time-map-btn').removeClass('active');

    this.currentView = 'ALL';
    this.dataAll.forEach(file => {
      this.appendItem(tbody, file);
    });
  }

  onClickDeleteAll() {
    $('#delete-all-modal').show();
  }

  onClickDelete(btn) {
    $('#delete-modal').show();

    this.resultToDelete = btn.value;
    $('#result-to-delete-span').text(resultModal.resultToDelete);
  }

  updateResults() {
    get('/output', {}, res => new Promise(resolve => {
      res.list.sort().reverse();
      this.dataAll = res.list;

      switch (this.currentView) {
        case 'QUERY':
          this.onClickQuery();
          break;
        case 'TIMEMAP':
          this.onClickTimeMap();
          break;
        default:
          this.onClickAll();
          break;
      }
      resolve();
    }));
  }

  appendItem(tbody, file) {
    const m = file.match(/.*(\d{4})-(\d{2})-(\d{2})_(\d{4})\.pdf$/);
    const date = new Date(m[1], m[2] - 1, m[3]);
    tbody.append(`<tr>
  <td>${date.toDateString()}</td>
  <td><a href="/output/${file}" target="_blank">${file}</a></td>
  <td><button type="button" class="btn btn-outline-danger" value="${file}" onclick="resultModal.onClickDelete(this)">Delete</button></td>
  </tr>`);
  }

  hide() {
    $('#results-modal').hide();
  }
}

class DeleteModal {
  constructor(resultModal) {
    this.resultModal = resultModal;
  }

  hide() {
    $('#delete-modal').hide();
  }

  onClickDelete() {
    deleteMethod('/output', { file: this.resultModal.resultToDelete }, () => new Promise((resolve) => {
      this.resultModal.remove(this.resultModal.resultToDelete);
      resolve();
    }));
    this.resultModal.resultToDelete = '';
    this.resultModal.updateResults();
    this.hide();
  }
}

class DeleteAllModal {
  constructor(resultModal) {
    this.resultModal = resultModal;
  }

  onClickDelete() {
    deleteMethod('/output-all', {}, () => new Promise((resolve) => {
      resolve();
    }));
    this.resultModal.dataAll = []
    this.resultModal.resultToDelete = '';
    $('#results-table table tbody').empty();
    this.hide();
  }

  hide() {
    $('#delete-all-modal').hide();
  }
}

const resultModal = new ResultModal();
// eslint-disable-next-line no-unused-vars
const deleteModal = new DeleteModal(resultModal);
// eslint-disable-next-line no-unused-vars
const deleteAllModal = new DeleteAllModal(resultModal);
