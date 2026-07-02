package vista;

import controlador.ReservaControlador;
import java.awt.BorderLayout;
import java.awt.FlowLayout;
import java.awt.GridBagConstraints;
import java.awt.GridBagLayout;
import java.awt.Insets;
import java.util.List;
import javax.swing.JButton;
import javax.swing.JComboBox;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JTabbedPane;
import javax.swing.JTable;
import javax.swing.JTextField;
import javax.swing.ListSelectionModel;
import javax.swing.table.DefaultTableModel;
import modelo.Estudiante;
import modelo.Reserva;
import modelo.Sala;

public class ReservaVista extends JFrame {

    private ReservaControlador controlador;
    private JTextField txtCodigo, txtNombre, txtApellido, txtEmail;
    private JTextField txtHoraInicio, txtHoraFin, txtFecha;
    private JComboBox<String> comboTurno, comboFiltroTurno;
    private JComboBox<Sala> comboSala;
    private JTable tblReservas, tblPapelera;
    private DefaultTableModel modeloReservas, modeloPapelera;

    public ReservaVista() {
        controlador = new ReservaControlador();
        initComponents();
        cargarReservas();
        cargarPapelera();
    }

    private void initComponents() {
        setTitle("Sistema de Reservas de Salas");
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setSize(950, 650);
        setLocationRelativeTo(null);
        JTabbedPane tp = new JTabbedPane();
        tp.addTab("Reservas", crearPanelReservas());
        tp.addTab("Papelera", crearPanelPapelera());
        add(tp);
    }

    private JPanel crearPanelReservas() {
        JPanel p = new JPanel(new BorderLayout(10, 10));
        p.add(crearFormulario(), BorderLayout.NORTH);
        p.add(crearTabla(), BorderLayout.CENTER);
        return p;
    }

    private JPanel crearFormulario() {
        JPanel p = new JPanel(new GridBagLayout());
        p.setBorder(javax.swing.BorderFactory.createTitledBorder("Registrar Reserva"));
        GridBagConstraints g = new GridBagConstraints();
        g.insets = new Insets(5, 5, 5, 5);
        g.fill = GridBagConstraints.HORIZONTAL;

        txtCodigo = new JTextField(8); txtNombre = new JTextField(8);
        txtApellido = new JTextField(8); txtEmail = new JTextField(12);
        comboSala = new JComboBox<>(); comboTurno = new JComboBox<>(new String[]{"Mañana","Tarde","Noche"});
        txtHoraInicio = new JTextField(6); txtHoraFin = new JTextField(6); txtFecha = new JTextField(10);
        JButton btnReg = new JButton("Registrar");

        g.gridx=0;g.gridy=0; p.add(new JLabel("Código:"),g); g.gridx=1; p.add(txtCodigo,g);
        g.gridx=2; p.add(new JLabel("Nombre:"),g); g.gridx=3; p.add(txtNombre,g);
        g.gridx=4; p.add(new JLabel("Apellido:"),g); g.gridx=5; p.add(txtApellido,g);
        g.gridx=0;g.gridy=1; p.add(new JLabel("Email:"),g); g.gridx=1; p.add(txtEmail,g);
        g.gridx=2; p.add(new JLabel("Sala:"),g); g.gridx=3; p.add(comboSala,g);
        g.gridx=4; p.add(new JLabel("Turno:"),g); g.gridx=5; p.add(comboTurno,g);
        g.gridx=0;g.gridy=2; p.add(new JLabel("Inicio (HH:mm):"),g); g.gridx=1; p.add(txtHoraInicio,g);
        g.gridx=2; p.add(new JLabel("Fin (HH:mm):"),g); g.gridx=3; p.add(txtHoraFin,g);
        g.gridx=4; p.add(new JLabel("Fecha (dd/mm/aaaa):"),g); g.gridx=5; p.add(txtFecha,g);
        g.gridx=5;g.gridy=3; p.add(btnReg,g);

        for (Sala s : controlador.getSalas()) comboSala.addItem(s);
        btnReg.addActionListener(e -> registrarReserva());
        return p;
    }

    private JPanel crearTabla() {
        JPanel p = new JPanel(new BorderLayout(5, 5));
        p.setBorder(javax.swing.BorderFactory.createTitledBorder("Reservas Activas"));

        JPanel f = new JPanel(new FlowLayout(FlowLayout.LEFT));
        f.add(new JLabel("Filtrar turno:"));
        comboFiltroTurno = new JComboBox<>(new String[]{"Todos","Mañana","Tarde","Noche"});
        f.add(comboFiltroTurno);
        comboFiltroTurno.addActionListener(e -> cargarReservas());

        modeloReservas = new DefaultTableModel(
            new String[]{"ID","Estudiante","Sala","Turno","Inicio","Fin","Duración","Fecha"}, 0) {
            @Override public boolean isCellEditable(int r, int c) { return false; }
        };
        tblReservas = new JTable(modeloReservas);
        tblReservas.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);

        JButton btnBorrar = new JButton("Borrar");
        btnBorrar.addActionListener(e -> borrarReserva());

        p.add(f, BorderLayout.NORTH);
        p.add(new JScrollPane(tblReservas), BorderLayout.CENTER);
        JPanel pb = new JPanel(new FlowLayout(FlowLayout.LEFT));
        pb.add(btnBorrar);
        p.add(pb, BorderLayout.SOUTH);
        return p;
    }

    private JPanel crearPanelPapelera() {
        JPanel p = new JPanel(new BorderLayout(5, 5));
        p.setBorder(javax.swing.BorderFactory.createTitledBorder("Reservas Eliminadas"));

        modeloPapelera = new DefaultTableModel(
            new String[]{"ID","Estudiante","Sala","Turno","Inicio","Fin","Duración","Fecha"}, 0) {
            @Override public boolean isCellEditable(int r, int c) { return false; }
        };
        tblPapelera = new JTable(modeloPapelera);
        tblPapelera.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);

        JButton btnRest = new JButton("Restaurar");
        JButton btnElim = new JButton("Eliminar Definitivamente");
        btnRest.addActionListener(e -> restaurarReserva());
        btnElim.addActionListener(e -> eliminarDefinitivamente());

        p.add(new JScrollPane(tblPapelera), BorderLayout.CENTER);
        JPanel pb = new JPanel(new FlowLayout(FlowLayout.LEFT));
        pb.add(btnRest); pb.add(btnElim);
        p.add(pb, BorderLayout.SOUTH);
        return p;
    }

    private void registrarReserva() {
        if (txtCodigo.getText().trim().isEmpty() || txtNombre.getText().trim().isEmpty()
            || txtApellido.getText().trim().isEmpty()) {
            JOptionPane.showMessageDialog(this, "Complete datos del estudiante.");
            return;
        }
        if (txtHoraInicio.getText().trim().isEmpty() || txtHoraFin.getText().trim().isEmpty()) {
            JOptionPane.showMessageDialog(this, "Ingrese hora inicio y fin.");
            return;
        }
        if (txtFecha.getText().trim().isEmpty()) {
            JOptionPane.showMessageDialog(this, "Ingrese fecha.");
            return;
        }
        String error = controlador.agregarReserva(
            new Estudiante(txtCodigo.getText().trim(), txtNombre.getText().trim(),
                           txtApellido.getText().trim(), txtEmail.getText().trim()),
            (Sala)comboSala.getSelectedItem(), (String)comboTurno.getSelectedItem(),
            txtHoraInicio.getText().trim(), txtHoraFin.getText().trim(), txtFecha.getText().trim());
        if (error != null) { JOptionPane.showMessageDialog(this, error, "Error", JOptionPane.WARNING_MESSAGE); return; }
        JOptionPane.showMessageDialog(this, "Reserva registrada con éxito.");
        txtCodigo.setText(""); txtNombre.setText(""); txtApellido.setText(""); txtEmail.setText("");
        txtHoraInicio.setText(""); txtHoraFin.setText(""); txtFecha.setText("");
        comboSala.setSelectedIndex(0); comboTurno.setSelectedIndex(0);
        cargarReservas();
    }

    private void cargarReservas() {
        modeloReservas.setRowCount(0);
        for (Reserva r : controlador.listarReservasActivasPorTurno((String)comboFiltroTurno.getSelectedItem()))
            modeloReservas.addRow(new Object[]{r.getId(), r.getEstudiante().getNombre()+" "+r.getEstudiante().getApellido(),
                r.getSala().getNombre(), r.getTurno(), r.getHoraInicio(), r.getHoraFin(),
                String.format("%.1f h", r.getDuracion()), r.getFecha()});
    }

    private void cargarPapelera() {
        modeloPapelera.setRowCount(0);
        for (Reserva r : controlador.listarPapelera())
            modeloPapelera.addRow(new Object[]{r.getId(), r.getEstudiante().getNombre()+" "+r.getEstudiante().getApellido(),
                r.getSala().getNombre(), r.getTurno(), r.getHoraInicio(), r.getHoraFin(),
                String.format("%.1f h", r.getDuracion()), r.getFecha()});
    }

    private void borrarReserva() {
        int fila = tblReservas.getSelectedRow();
        if (fila == -1) { JOptionPane.showMessageDialog(this, "Seleccione una reserva."); return; }
        int id = (int)modeloReservas.getValueAt(fila, 0);
        if (JOptionPane.showConfirmDialog(this, "¿Borrar reserva ID "+id+"?", "Confirmar",
                JOptionPane.YES_NO_OPTION) == JOptionPane.YES_OPTION) {
            controlador.eliminarReserva(id); cargarReservas(); cargarPapelera();
        }
    }

    private void restaurarReserva() {
        int fila = tblPapelera.getSelectedRow();
        if (fila == -1) { JOptionPane.showMessageDialog(this, "Seleccione una reserva."); return; }
        controlador.restaurarReserva((int)modeloPapelera.getValueAt(fila, 0));
        cargarReservas(); cargarPapelera();
    }

    private void eliminarDefinitivamente() {
        int fila = tblPapelera.getSelectedRow();
        if (fila == -1) { JOptionPane.showMessageDialog(this, "Seleccione una reserva."); return; }
        int id = (int)modeloPapelera.getValueAt(fila, 0);
        if (JOptionPane.showConfirmDialog(this, "¿Eliminar definitivamente ID "+id+"?", "Confirmar",
                JOptionPane.YES_NO_OPTION) == JOptionPane.YES_OPTION) {
            controlador.eliminarDefinitivamente(id); cargarPapelera();
        }
    }

    public static void main(String[] args) {
        java.awt.EventQueue.invokeLater(() -> new ReservaVista().setVisible(true));
    }
}
