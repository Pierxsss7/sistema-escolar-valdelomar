package modelo;

public class Reserva {
    private int id;
    private Estudiante estudiante;
    private Sala sala;
    private String turno;
    private int horas;
    private String fecha;
    private boolean activa;

    public Reserva() { activa = true; }

    public Reserva(int id, Estudiante estudiante, Sala sala, String turno, int horas, String fecha) {
        this.id = id;
        this.estudiante = estudiante;
        this.sala = sala;
        this.turno = turno;
        this.horas = horas;
        this.fecha = fecha;
        this.activa = true;
    }

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }
    public Estudiante getEstudiante() { return estudiante; }
    public void setEstudiante(Estudiante estudiante) { this.estudiante = estudiante; }
    public Sala getSala() { return sala; }
    public void setSala(Sala sala) { this.sala = sala; }
    public String getTurno() { return turno; }
    public void setTurno(String turno) { this.turno = turno; }
    public int getHoras() { return horas; }
    public void setHoras(int horas) { this.horas = horas; }
    public String getFecha() { return fecha; }
    public void setFecha(String fecha) { this.fecha = fecha; }
    public boolean isActiva() { return activa; }
    public void setActiva(boolean activa) { this.activa = activa; }

    public boolean excedeLimite() {
        if (turno.equals("Noche")) return horas > 3;
        return horas > 4;
    }

    @Override
    public String toString() { return id + " - " + estudiante.getNombre(); }
}
