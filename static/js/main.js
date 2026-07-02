document.addEventListener('DOMContentLoaded', function() {
    // Auto-cerrar alerts después de 5 segundos
    setTimeout(function() {
        document.querySelectorAll('.alert-dismissible').forEach(function(alert) {
            var bsAlert = new bootstrap.Alert(alert);
            bsAlert.close();
        });
    }, 5000);

    // Marcar el sidebar activo según la URL
    var path = window.location.pathname;
    document.querySelectorAll('.sidebar .nav-link').forEach(function(link) {
        if (link.getAttribute('href') === path) {
            link.closest('.nav-item').classList.add('active');
        }
    });

    // Búsqueda en tablas (filtro por texto)
    var searchInputs = document.querySelectorAll('.table-search-input');
    searchInputs.forEach(function(input) {
        input.addEventListener('keyup', function() {
            var q = this.value.toLowerCase();
            var table = this.closest('.table-container') || this.closest('div').querySelector('.table');
            if (!table) table = document.querySelector('.table');
            if (!table) return;
            var rows = table.querySelectorAll('tbody tr');
            rows.forEach(function(row) {
                var text = row.textContent.toLowerCase();
                row.style.display = text.indexOf(q) > -1 ? '' : 'none';
            });
        });
    });

    // Cerrar sidebar al hacer clic fuera en móvil
    document.addEventListener('click', function(e) {
        var sidebar = document.getElementById('sidebar');
        if (!sidebar) return;
        var isMobile = window.innerWidth < 768;
        if (isMobile && sidebar.classList.contains('show') &&
            !sidebar.contains(e.target) && !e.target.closest('[onclick*="sidebar"]')) {
            sidebar.classList.remove('show');
        }
    });
});
