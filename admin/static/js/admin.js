/**
 * BharatBrief Admin Panel - JavaScript
 */

// ---- Sidebar toggle (mobile) ----
document.addEventListener('DOMContentLoaded', function () {
    const toggle = document.getElementById('sidebarToggle');
    const sidebar = document.getElementById('sidebar');
    if (toggle && sidebar) {
        toggle.addEventListener('click', function () {
            sidebar.classList.toggle('show');
        });
        // Close sidebar when clicking outside on mobile
        document.addEventListener('click', function (e) {
            if (window.innerWidth < 992 && sidebar.classList.contains('show')) {
                if (!sidebar.contains(e.target) && !toggle.contains(e.target)) {
                    sidebar.classList.remove('show');
                }
            }
        });
    }
});

// ---- Toast notifications ----
function showToast(message, type) {
    type = type || 'info';
    var bgClass = {
        success: 'bg-success',
        danger: 'bg-danger',
        warning: 'bg-warning text-dark',
        info: 'bg-info text-white',
    }[type] || 'bg-secondary';

    var container = document.getElementById('toastContainer');
    if (!container) return;

    var id = 'toast-' + Date.now();
    var html =
        '<div id="' + id + '" class="toast align-items-center ' + bgClass + ' text-white border-0" role="alert">' +
        '  <div class="d-flex">' +
        '    <div class="toast-body">' + message + '</div>' +
        '    <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>' +
        '  </div>' +
        '</div>';

    container.insertAdjacentHTML('beforeend', html);
    var toastEl = document.getElementById(id);
    var toast = new bootstrap.Toast(toastEl, { delay: 4000 });
    toast.show();
    toastEl.addEventListener('hidden.bs.toast', function () {
        toastEl.remove();
    });
}

// ---- AJAX helpers ----
function postJSON(url, data) {
    return fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data || {}),
    }).then(function (r) { return r.json(); });
}

// ---- Run Pipeline ----
function runPipeline() {
    if (!confirm('Run the full pipeline (fetch -> summarize -> translate)? This may take a few minutes.')) return;
    showToast('Starting pipeline...', 'info');
    postJSON('/pipeline/run', {})
        .then(function (res) {
            if (res.ok) {
                showToast('Pipeline completed successfully!', 'success');
            } else {
                showToast('Pipeline error: ' + (res.error || 'Unknown'), 'danger');
            }
        })
        .catch(function () {
            showToast('Failed to reach server.', 'danger');
        });
}

// ---- Generate Quiz ----
function generateQuiz() {
    if (!confirm('Generate a new quiz for today?')) return;
    showToast('Generating quiz...', 'info');
    postJSON('/quiz/generate', {})
        .then(function (res) {
            if (res.ok) {
                showToast('Quiz generated!', 'success');
                setTimeout(function () { location.reload(); }, 1000);
            } else {
                showToast('Quiz error: ' + (res.error || 'Unknown'), 'danger');
            }
        })
        .catch(function () {
            showToast('Failed to reach server.', 'danger');
        });
}

// ---- Auto-refresh dashboard stats ----
function refreshDashboardStats() {
    fetch('/api/stats')
        .then(function (r) { return r.json(); })
        .then(function (data) {
            var mapping = {
                statTotalArticles: data.total_articles,
                statTodayArticles: data.today_articles,
                statActiveFeeds: data.active_feeds,
                statTotalUsers: data.total_users,
            };
            for (var id in mapping) {
                var el = document.getElementById(id);
                if (el) el.textContent = mapping[id];
            }
        })
        .catch(function () {
            // silently ignore refresh errors
        });
}

// ---- Confirm dialogs for dangerous actions ----
document.addEventListener('DOMContentLoaded', function () {
    document.querySelectorAll('[data-confirm]').forEach(function (el) {
        el.addEventListener('click', function (e) {
            if (!confirm(el.getAttribute('data-confirm'))) {
                e.preventDefault();
            }
        });
    });
});
