package com.tesis.sjl.views;

import com.tesis.sjl.dao.UsuarioDAO;
import com.tesis.sjl.models.Usuario;
import com.tesis.sjl.utils.Constants;
import net.miginfocom.swing.MigLayout;
import javax.swing.*;
import java.awt.*;

public class LoginView extends JFrame {
    private final JTextField txtUsuario = new JTextField(20);
    private final JPasswordField txtClave = new JPasswordField(20);

    public LoginView() {
        setTitle("Iniciar Sesi\u00F3n - " + Constants.APP_NAME);
        setDefaultCloseOperation(EXIT_ON_CLOSE);
        setSize(420, 520);
        setLocationRelativeTo(null);
        setResizable(false);

        JPanel panel = new JPanel(new MigLayout("fill,insets 30", "[center]")) {
            @Override protected void paintComponent(Graphics g) {
                super.paintComponent(g);
                Graphics2D g2 = (Graphics2D) g.create();
                g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
                g2.setPaint(new GradientPaint(0, 0, Constants.COLOR_PRIMARY, getWidth(), getHeight(), Constants.COLOR_SECONDARY));
                g2.fillRect(0, 0, getWidth(), 140);
                g2.dispose();
            }
        };
        panel.setBackground(Color.WHITE);

        panel.add(Box.createVerticalStrut(30), "wrap");

        JLabel lblIcono = new JLabel("\uD83C\uDF7D\uFE0F", SwingConstants.CENTER);
        lblIcono.setFont(new Font("Segoe UI", Font.PLAIN, 48));
        panel.add(lblIcono, "wrap, gapbottom 2");

        JLabel lblTitulo = new JLabel(Constants.APP_NAME, SwingConstants.CENTER);
        lblTitulo.setFont(new Font("Segoe UI", Font.BOLD, 16));
        lblTitulo.setForeground(Color.WHITE);
        panel.add(lblTitulo, "wrap");

        JLabel lblSub = new JLabel("Ingrese sus credenciales", SwingConstants.CENTER);
        lblSub.setFont(new Font("Segoe UI", Font.PLAIN, 12));
        lblSub.setForeground(new Color(0x94A3B8));
        panel.add(lblSub, "wrap, gapbottom 20");

        JPanel form = new JPanel(new MigLayout("insets 0, gapy 8", "[180px]"));
        form.setOpaque(false);

        form.add(new JLabel("Usuario:"), "wrap");
        txtUsuario.setFont(new Font("Segoe UI", Font.PLAIN, 14));
        txtUsuario.putClientProperty("JTextField.placeholderText", "Ingrese su usuario");
        form.add(txtUsuario, "wrap, h 35!");

        form.add(new JLabel("Contrase\u00F1a:"), "wrap, gaptop 5");
        txtClave.setFont(new Font("Segoe UI", Font.PLAIN, 14));
        txtClave.putClientProperty("JTextField.placeholderText", "Ingrese su contrase\u00F1a");
        form.add(txtClave, "wrap, h 35!");

        panel.add(form, "wrap, gapbottom 10");

        JButton btnIngresar = new JButton("INGRESAR");
        btnIngresar.setFont(new Font("Segoe UI", Font.BOLD, 14));
        btnIngresar.setBackground(Constants.COLOR_PRIMARY);
        btnIngresar.setForeground(Color.WHITE);
        btnIngresar.setFocusPainted(false);
        btnIngresar.setCursor(new Cursor(Cursor.HAND_CURSOR));
        btnIngresar.setPreferredSize(new Dimension(200, 40));
        panel.add(btnIngresar, "wrap");

        JLabel lblError = new JLabel(" ", SwingConstants.CENTER);
        lblError.setForeground(Constants.COLOR_DANGER);
        lblError.setFont(new Font("Segoe UI", Font.PLAIN, 12));
        panel.add(lblError);

        add(panel);

        btnIngresar.addActionListener(e -> login());
        txtClave.addActionListener(e -> login());
        txtUsuario.addActionListener(e -> txtClave.requestFocus());
    }

    private void login() {
        String user = txtUsuario.getText().trim();
        String pass = new String(txtClave.getPassword());

        if (user.isEmpty() || pass.isEmpty()) {
            JOptionPane.showMessageDialog(this, "Complete todos los campos", "Error", JOptionPane.ERROR_MESSAGE);
            return;
        }

        UsuarioDAO dao = new UsuarioDAO();
        Usuario u = dao.login(user, pass);
        if (u != null) {
            dao.actualizarUltimoAcceso(u.getIdUsuario());
            new DashboardView(u).setVisible(true);
            dispose();
        } else {
            JOptionPane.showMessageDialog(this, "Usuario o contrase\u00F1a incorrectos", "Error", JOptionPane.ERROR_MESSAGE);
        }
    }
}
