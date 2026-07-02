package controlador;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;
import modelo.Estudiante;
import modelo.Reserva;
import modelo.Sala;

public class ReservaControlador {

    private ArrayList<Reserva> reservas;
    private ArrayList<Reserva> papelera;
    private int nextId;

    public ReservaControlador() {
        reservas = new ArrayList<>();
        papelera = new ArrayList<>();
        nextId = 1;
        cargarDatosPrueba();
    }

    private void cargarDatosPrueba() {
        Estudiante e1 = new Estudiante("E001", "Ana", "Lopez", "ana@mail.com");
        Estudiante e2 = new Estudiante("E002", "Luis", "Martinez", "luis@mail.com");
        Sala s1 = new Sala("Sala A", "Piso 1", 30);
        Sala s2 = new Sala("Sala B", "Piso 2", 20);

        agregarReserva(e1, s1, "Mañana", 3, "15/06/2026");
        agregarReserva(e2, s2, "Tarde", 2, "15/06/2026");
        agregarReserva(e1, s2, "Noche", 2, "16/06/2026");
    }

    public String agregarReserva(Estudiante e, Sala s, String turno, int horas, String fecha) {
        if (horas <= 0) return "Las horas deben ser mayor a cero.";
        Reserva tmp = new Reserva(0, e, s, turno, horas, fecha);
        if (tmp.excedeLimite()) return "El turno " + turno + " permite máximo " + (turno.equals("Noche")?3:4) + " horas.";
        reservas.add(new Reserva(nextId++, e, s, turno, horas, fecha));
        return null;
    }

    public void eliminarReserva(int id) {
        for (Reserva r : reservas) {
            if (r.getId() == id && r.isActiva()) {
                r.setActiva(false);
                papelera.add(r);
                return;
            }
        }
    }

    public void restaurarReserva(int id) {
        for (Reserva r : papelera) {
            if (r.getId() == id) {
                r.setActiva(true);
                papelera.remove(r);
                return;
            }
        }
    }

    public void eliminarDefinitivamente(int id) {
        papelera.removeIf(r -> r.getId() == id);
    }

    public List<Reserva> listarActivas() {
        return reservas.stream().filter(Reserva::isActiva).collect(Collectors.toList());
    }

    public List<Reserva> listarActivasPorTurno(String turno) {
        if (turno == null || turno.equals("Todos")) return listarActivas();
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
