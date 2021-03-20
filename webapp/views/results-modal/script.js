/* global $, get, deleteMethod */

/**
 * result modal class
 */
class ResultModal {
  constructor(results = [], resultToDelete = '', currentView = 'ALL') {
    this._results = results;
    this.resultToDelete = resultToDelete;
    this.currentView = currentView;
  }

  get results() {
    return this._results;
  }
  set results(val) {
    this._results = val;
  }
  get timeMapResults() {
    return this._results.filter(str => str.file.match(/^time/));
  }
  get queryResults() {
    return this._results.filter(str => str.file.match(/^query/));
  }

  remove(file) {
    this.results.splice(this.results.indexOf(file), 1);
  }

  onClickTimeMap() {
    const tbody = $('#results-table table tbody').empty();
    $('#all-btn').removeClass('active');
    $('#query-btn').removeClass('active');
    $('#time-map-btn').addClass('active');

    this.currentView = 'TIMEMAP';
    this.batchedAppend(tbody, this.timeMapResults.sort((a, b) => b.date.valueOf() - a.date.valueOf()));
  }

  onClickQuery() {
    const tbody = $('#results-table table tbody').empty();
    $('#all-btn').removeClass('active');
    $('#query-btn').addClass('active');
    $('#time-map-btn').removeClass('active');

    this.currentView = 'QUERY';
    this.batchedAppend(tbody, this.queryResults.sort((a, b) => b.date.valueOf() - a.date.valueOf()));
  }

  onClickAll() {
    const tbody = $('#results-table table tbody').empty();
    $('#all-btn').addClass('active');
    $('#query-btn').removeClass('active');
    $('#time-map-btn').removeClass('active');

    this.currentView = 'ALL';
    this.batchedAppend(tbody, this.results.sort((a, b) => b.date.valueOf() - a.date.valueOf()));
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
    get('/output/', {}, res => new Promise(resolve => {
      res.list.sort().reverse();
      this.results = res.list.map(file => new Result(file));

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

  batchedAppend(tbody, results) {
    if (results.length) {
      results.forEach(result => {
        const m = result.file.match(/.*(\d{4})-(\d{2})-(\d{2})_(\d{4})\.pdf$/);
        const date = new Date(m[1], m[2] - 1, m[3]);
        tbody.append(`<tr>
      <td>${date.toDateString()}</td>
      <td><a href="/output/${result.file}" target="_blank">${result.file}</a></td>
      <td><button type="button" class="btn btn-outline-danger" value="${result.file}" onclick="resultModal.onClickDelete(this)">Delete</button></td>
      </tr>`);
      });
    }
  }

  hide() {
    $('#results-modal').hide();
  }
}

class Result {
  constructor(file) {
    this.file = file;
    const m = this.file.match(/.*(\d{4})-(\d{2})-(\d{2})_(\d{2})(\d{2})\.pdf$/);
    this.date = new Date(m[1], m[2] - 1, m[3], m[4], m[5]);
  }

  getTableRow() {
    return `<tr>
  <td>${this.date.toDateString()}</td>
  <td><a href="/output/${this.file}" target="_blank">${this.file}</a></td>
  <td><button type="button" class="btn btn-outline-danger" value="${this.file}" onclick="resultModal.onClickDelete(this)">Delete</button></td>
</tr>`;
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
      this.resultModal.resultToDelete = '';
      this.resultModal.updateResults();
      this.hide();
      resolve();
    }));
  }
}

class DeleteAllModal {
  constructor(resultModal) {
    this.resultModal = resultModal;
  }

  onClickDelete() {
    deleteMethod('/output-all', {}, () => new Promise((resolve) => {
      this.resultModal.results = []
      this.resultModal.resultToDelete = '';
      $('#results-table table tbody').empty();
      this.hide();
      resolve();
    }));
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
