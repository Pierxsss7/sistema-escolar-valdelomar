package controlador;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;
import modelo.Estudiante;
import modelo.Reserva;
import modelo.Sala;

public class ReservaControlador {

    private final ArrayList<Reserva> reservas;
    private final ArrayList<Reserva> papelera;
    private int nextId;

    public ReservaControlador() {
        reservas = new ArrayList<>();
        papelera = new ArrayList<>();
        nextId = 1;
        cargarDatosPrueba();
    }

    private void cargarDatosPrueba() {
        Estudiante e1 = new Estudiante("E001", "Ana", "Lopez", "ana@email.com");
        Estudiante e2 = new Estudiante("E002", "Luis", "Martinez", "luis@email.com");
        Estudiante e3 = new Estudiante("E003", "Carla", "Gomez", "carla@email.com");
        Sala s1 = new Sala("Sala A", "Piso 1", 30);
        Sala s2 = new Sala("Sala B", "Piso 2", 20);
        Sala s3 = new Sala("Sala C", "Piso 1", 15);

        agregarReserva(e1, s1, "Mañana", "07:15", "10:15", "15/06/2026");
        agregarReserva(e2, s2, "Tarde", "14:00", "16:30", "15/06/2026");
        agregarReserva(e3, s3, "Noche", "19:00", "21:00", "15/06/2026");
        agregarReserva(e1, s2, "Mañana", "08:00", "12:00", "16/06/2026");
        agregarReserva(e2, s1, "Noche", "20:00", "21:10", "16/06/2026");
    }

    public static double calcularDuracion(String horaInicio, String horaFin) {
        try {
            String[] ini = horaInicio.split(":");
            String[] fin = horaFin.split(":");
            double hIni = Integer.parseInt(ini[0]) + Integer.parseInt(ini[1]) / 60.0;
            double hFin = Integer.parseInt(fin[0]) + Integer.parseInt(fin[1]) / 60.0;
            double diff = hFin - hIni;
            return diff > 0 ? diff : 0;
        } catch (Exception e) { return -1; }
    }

    public static boolean esHoraValida(String hora) {
        if (!hora.matches("\\d{1,2}:\\d{2}")) return false;
        try {
            String[] p = hora.split(":");
            int hh = Integer.parseInt(p[0]), mm = Integer.parseInt(p[1]);
            return hh >= 0 && hh <= 23 && mm >= 0 && mm <= 59;
        } catch (Exception e) { return false; }
    }

    public String agregarReserva(Estudiante e, Sala s, String turno,
                                  String hi, String hf, String fecha) {
        if (!esHoraValida(hi)) return "Hora de inicio inválida. Use HH:mm (ej: 07:15).";
        if (!esHoraValida(hf)) return "Hora de fin inválida. Use HH:mm (ej: 10:30).";
        double d = calcularDuracion(hi, hf);
        if (d <= 0) return "La hora de fin debe ser mayor que la hora de inicio.";
        Reserva tmp = new Reserva(0, e, s, turno, hi, hf, d, fecha);
        if (tmp.excedeLimiteTurno())
            return "Error: Turno " + turno + " máximo " + String.format("%.0f", tmp.getMaximoHoras())
                    + "h. Su reserva dura " + String.format("%.1f", d) + "h.";
        reservas.add(new Reserva(nextId++, e, s, turno, hi, hf, d, fecha));
        return null;
    }

    public boolean eliminarReserva(int id) {
        for (Reserva r : reservas) {
            if (r.getId() == id && r.isActiva()) {
                r.setActiva(false); papelera.add(r); return true;
            }
        }
        return false;
    }

    public boolean restaurarReserva(int id) {
        for (Reserva r : papelera) {
            if (r.getId() == id) { r.setActiva(true); papelera.remove(r); return true; }
        }
        return false;
    }

    public boolean eliminarDefinitivamente(int id) { return papelera.removeIf(r -> r.getId() == id); }

    public List<Reserva> listarReservasActivas() {
        return reservas.stream().filter(Reserva::isActiva).collect(Collectors.toList());
    }

    public List<Reserva> listarReservasActivasPorTurno(String turno) {
        if (turno == null || turno.equals("Todos")) return listarReservasActivas();
        return reservas.stream().filter(r -> r.isActiva() && r.getTurno().equals(turno)).collect(Collectors.toList());
    }

    public List<Reserva> listarPapelera() { return new ArrayList<>(papelera); }

    public List<Sala> getSalas() {
        List<Sala> salas = new ArrayList<>();
        salas.add(new Sala("Sala A", "Piso 1", 30));
        salas.add(new Sala("Sala B", "Piso 2", 20));
        salas.add(new Sala("Sala C", "Piso 1", 15));
        return salas;
    }
}
