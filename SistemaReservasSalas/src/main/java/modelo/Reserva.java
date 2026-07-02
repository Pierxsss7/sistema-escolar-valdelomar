package modelo;

public class Reserva {
    private int id;
    private Estudiante estudiante;
    private Sala sala;
    private String turno;
    private String horaInicio;
    private String horaFin;
    private double duracion;
    private String fecha;
    private boolean activa;

    public Reserva() { this.activa = true; }

    public Reserva(int id, Estudiante estudiante, Sala sala, String turno,
                   String horaInicio, String horaFin, double duracion, String fecha) {
        this.id = id; this.estudiante = estudiante; this.sala = sala;
        this.turno = turno; this.horaInicio = horaInicio; this.horaFin = horaFin;
        this.duracion = duracion; this.fecha = fecha; this.activa = true;
    }

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }
    public Estudiante getEstudiante() { return estudiante; }
    public void setEstudiante(Estudiante estudiante) { this.estudiante = estudiante; }
    public Sala getSala() { return sala; }
    public void setSala(Sala sala) { this.sala = sala; }
    public String getTurno() { return turno; }
    public void setTurno(String turno) { this.turno = turno; }
    public String getHoraInicio() { return horaInicio; }
    public void setHoraInicio(String horaInicio) { this.horaInicio = horaInicio; }
    public String getHoraFin() { return horaFin; }
    public void setHoraFin(String horaFin) { this.horaFin = horaFin; }
    public double getDuracion() { return duracion; }
    public void setDuracion(double duracion) { this.duracion = duracion; }
    public String getFecha() { return fecha; }
    public void setFecha(String fecha) { this.fecha = fecha; }
    public boolean isActiva() { return activa; }
    public void setActiva(boolean activa) { this.activa = activa; }

    public boolean excedeLimiteTurno() {
        switch (turno) {
            case "Mañana": return duracion > 4;
            case "Tarde":   return duracion > 4;
            case "Noche":   return duracion > 3;
            default:        return false;
        }
    }

    public double getMaximoHoras() {
        switch (turno) {
            case "Mañana": return 4;
            case "Tarde":   return 4;
            case "Noche":   return 3;
            default:        return 0;
        }
    }

    @Override
    public String toString() { return id + " - " + estudiante.toString(); }
}
