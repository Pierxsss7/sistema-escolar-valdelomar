package vista;

import controlador.ReservaControlador;
import java.awt.*;
import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import modelo.Estudiante;
import modelo.Reserva;
import modelo.Sala;

public class ReservaVista extends JFrame {

    private ReservaControlador ctrl;
    private JTextField txtCodigo, txtNombre, txtApellido, txtEmail, txtHoras, txtFecha;
    private JComboBox<String> comboTurno, comboFiltro;
    private JComboBox<Sala> comboSala;
    private JTable tblActivas, tblPapelera;
    private DefaultTableModel mdActivas, mdPapelera;

    public ReservaVista() {
        ctrl = new ReservaControlador();
        initComponents();
        cargarActivas();
        cargarPapelera();
    }

    private void initComponents() {
        setTitle("Reservas de Salas");
        setDefaultCloseOperation(EXIT_ON_CLOSE);
        setSize(800, 600);
        setLocationRelativeTo(null);

        JTabbedPane tabs = new JTabbedPane();
        tabs.addTab("Reservas", panelReservas());
        tabs.addTab("Papelera", panelPapelera());
        add(tabs);
    }

    private JPanel panelReservas() {
        JPanel p = new JPanel(new BorderLayout(10, 10));

        JPanel form = new JPanel(new GridBagLayout());
        form.setBorder(BorderFactory.createTitledBorder("Nueva Reserva"));
        GridBagConstraints g = new GridBagConstraints();
        g.insets = new Insets(3, 3, 3, 3);
        g.fill = GridBagConstraints.HORIZONTAL;

        txtCodigo = new JTextField(8);
        txtNombre = new JTextField(8);
        txtApellido = new JTextField(8);
        txtEmail = new JTextField(12);
        comboSala = new JComboBox<>();
        comboTurno = new JComboBox<>(new String[]{"Mañana", "Tarde", "Noche"});
        txtHoras = new JTextField(4);
        txtFecha = new JTextField(10);
        JButton btnReg = new JButton("Registrar");

        g.gridx=0; g.gridy=0; form.add(new JLabel("Código:"), g); g.gridx=1; form.add(txtCodigo, g);
        g.gridx=2; form.add(new JLabel("Nombre:"), g); g.gridx=3; form.add(txtNombre, g);
        g.gridx=4; form.add(new JLabel("Apellido:"), g); g.gridx=5; form.add(txtApellido, g);
        g.gridx=0; g.gridy=1; form.add(new JLabel("Email:"), g); g.gridx=1; form.add(txtEmail, g);
        g.gridx=2; form.add(new JLabel("Sala:"), g); g.gridx=3; form.add(comboSala, g);
        g.gridx=4; form.add(new JLabel("Turno:"), g); g.gridx=5; form.add(comboTurno, g);
        g.gridx=0; g.gridy=2; form.add(new JLabel("Horas:"), g); g.gridx=1; form.add(txtHoras, g);
        g.gridx=2; form.add(new JLabel("Fecha:"), g); g.gridx=3; form.add(txtFecha, g);
        g.gridx=5; g.gridy=2; form.add(btnReg, g);

        for (Sala s : ctrl.getSalas()) comboSala.addItem(s);
        btnReg.addActionListener(e -> registrar());

        JPanel tablaPanel = new JPanel(new BorderLayout(5, 5));
        tablaPanel.setBorder(BorderFactory.createTitledBorder("Reservas Activas"));

        JPanel filtro = new JPanel(new FlowLayout(FlowLayout.LEFT));
        filtro.add(new JLabel("Filtrar:"));
        comboFiltro = new JComboBox<>(new String[]{"Todos", "Mañana", "Tarde", "Noche"});
        filtro.add(comboFiltro);
        comboFiltro.addActionListener(e -> cargarActivas());

        mdActivas = new DefaultTableModel(new String[]{"ID", "Estudiante", "Sala", "Turno", "Horas", "Fecha"}, 0) {
            @Override public boolean isCellEditable(int r, int c) { return false; }
        };
        tblActivas = new JTable(mdActivas);
        tblActivas.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);

        JButton btnBorrar = new JButton("Borrar");
        btnBorrar.addActionListener(e -> borrar());

        JPanel sur = new JPanel(new FlowLayout(FlowLayout.LEFT));
        sur.add(btnBorrar);

        tablaPanel.add(filtro, BorderLayout.NORTH);
        tablaPanel.add(new JScrollPane(tblActivas), BorderLayout.CENTER);
        tablaPanel.add(sur, BorderLayout.SOUTH);

        p.add(form, BorderLayout.NORTH);
        p.add(tablaPanel, BorderLayout.CENTER);
        return p;
    }

    private JPanel panelPapelera() {
        JPanel p = new JPanel(new BorderLayout(5, 5));
        p.setBorder(BorderFactory.createTitledBorder("Reservas Eliminadas"));

        mdPapelera = new DefaultTableModel(new String[]{"ID", "Estudiante", "Sala", "Turno", "Horas", "Fecha"}, 0) {
            @Override public boolean isCellEditable(int r, int c) { return false; }
        };
        tblPapelera = new JTable(mdPapelera);
        tblPapelera.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);

        JButton btnRest = new JButton("Restaurar");
        JButton btnElim = new JButton("Eliminar Definitivamente");
        btnRest.addActionListener(e -> restaurar());
        btnElim.addActionListener(e -> eliminarDef());

        JPanel sur = new JPanel(new FlowLayout(FlowLayout.LEFT));
        sur.add(btnRest);
        sur.add(btnElim);

        p.add(new JScrollPane(tblPapelera), BorderLayout.CENTER);
        p.add(sur, BorderLayout.SOUTH);
        return p;
    }

    private void registrar() {
        if (txtCodigo.getText().trim().isEmpty() || txtNombre.getText().trim().isEmpty()) {
            JOptionPane.showMessageDialog(this, "Complete datos del estudiante.");
            return;
        }
        int horas;
        try {
            horas = Integer.parseInt(txtHoras.getText().trim());
        } catch (NumberFormatException e) {
            JOptionPane.showMessageDialog(this, "Las horas deben ser un número entero.");
            return;
        }
        String error = ctrl.agregarReserva(
            new Estudiante(txtCodigo.getText().trim(), txtNombre.getText().trim(),
                           txtApellido.getText().trim(), txtEmail.getText().trim()),
            (Sala) comboSala.getSelectedItem(), (String) comboTurno.getSelectedItem(),
            horas, txtFecha.getText().trim());
        if (error != null) {
            JOptionPane.showMessageDialog(this, error, "Error", JOptionPane.WARNING_MESSAGE);
            return;
        }
        JOptionPane.showMessageDialog(this, "Reserva registrada.");
        txtCodigo.setText(""); txtNombre.setText(""); txtApellido.setText("");
        txtEmail.setText(""); txtHoras.setText(""); txtFecha.setText("");
        cargarActivas();
    }

    private void borrar() {
        int f = tblActivas.getSelectedRow();
        if (f == -1) { JOptionPane.showMessageDialog(this, "Seleccione una reserva."); return; }
        int id = (int) mdActivas.getValueAt(f, 0);
        if (JOptionPane.showConfirmDialog(this, "¿Borrar reserva?", "Confirmar", JOptionPane.YES_NO_OPTION) == JOptionPane.YES_OPTION) {
            ctrl.eliminarReserva(id);
            cargarActivas();
            cargarPapelera();
        }
    }

    private void restaurar() {
        int f = tblPapelera.getSelectedRow();
        if (f == -1) { JOptionPane.showMessageDialog(this, "Seleccione una reserva."); return; }
        ctrl.restaurarReserva((int) mdPapelera.getValueAt(f, 0));
        cargarActivas();
        cargarPapelera();
    }

    private void eliminarDef() {
        int f = tblPapelera.getSelectedRow();
        if (f == -1) { JOptionPane.showMessageDialog(this, "Seleccione una reserva."); return; }
        int id = (int) mdPapelera.getValueAt(f, 0);
        if (JOptionPane.showConfirmDialog(this, "¿Eliminar para siempre?", "Confirmar", JOptionPane.YES_NO_OPTION) == JOptionPane.YES_OPTION) {
            ctrl.eliminarDefinitivamente(id);
            cargarPapelera();
        }
    }

    private void cargarActivas() {
        mdActivas.setRowCount(0);
        String turno = (String) comboFiltro.getSelectedItem();
        for (Reserva r : ctrl.listarActivasPorTurno(turno)) {
            mdActivas.addRow(new Object[]{r.getId(), r.getEstudiante().getNombre() + " " + r.getEstudiante().getApellido(),
                r.getSala().getNombre(), r.getTurno(), r.getHoras(), r.getFecha()});
        }
    }

    private void cargarPapelera() {
        mdPapelera.setRowCount(0);
        for (Reserva r : ctrl.listarPapelera()) {
            mdPapelera.addRow(new Object[]{r.getId(), r.getEstudiante().getNombre() + " " + r.getEstudiante().getApellido(),
                r.getSala().getNombre(), r.getTurno(), r.getHoras(), r.getFecha()});
        }
    }

    public static void main(String[] args) {
        EventQueue.invokeLater(() -> new ReservaVista().setVisible(true));
    }
}
