/* global $, t, get, deleteMethod */

const modules = [
  { name: 'TIMEMAP', btnSelector: '#time-map-btn', regex: /^time/ },
  { name: 'QUERY', btnSelector: '#query-btn', regex: /^query/ },
  { name: 'COTOPAXI', btnSelector: '#cotopaxi-btn', regex: /^cotopaxi/ },
  { name: 'ALL', btnSelector: '#all-btn', regex: /.*/ }
]

/**
 * result modal class
 */
class ResultModal {
  constructor(results = [], resultToDelete = '', currentView = 'ALL') {
    this.results = results;
    this.resultToDelete = resultToDelete;
    this.currentView = currentView;
  }

  remove(file) {
    this.results.splice(this.results.indexOf(file), 1);
  }

  onClickView(btn) {
    const module = modules.filter(m => m.btnSelector === `#${btn.id}`)[0];

    if (module.name === this.currentView) {
      return;
    }
    this.updateView(module);
  }

  updateView(module) {
    const tbody = $('#results-table table tbody').empty();
    for (const m of modules) {
      $(m.btnSelector).removeClass('active');
    }
    $(module.btnSelector).addClass('active');

    this.results.filter(str => str.file.match(module.regex))
      .sort((a, b) => b.date.valueOf() - a.date.valueOf())
      .forEach(result => {
        tbody.append(result.getTableRow());
      });

    this.currentView = module.name;
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

      const currentModule = modules.filter(m => m.name === this.currentView)[0];
      this.updateView(currentModule);

      resolve();
    }));
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
  <td><button type="button" class="btn btn-outline-danger" value="${this.file}" onclick="resultModal.onClickDelete(this)">${t['Delete']}</button></td>
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
