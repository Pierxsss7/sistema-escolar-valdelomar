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
});
