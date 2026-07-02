package com.tesis.sjl.views;

import com.tesis.sjl.dao.DashboardDAO;
import com.tesis.sjl.models.Usuario;
import com.tesis.sjl.utils.Constants;
import net.miginfocom.swing.MigLayout;
import javax.swing.*;
import javax.swing.border.EmptyBorder;
import javax.swing.table.DefaultTableCellRenderer;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.math.BigDecimal;
import java.text.DecimalFormat;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Map;

public class DashboardView extends JFrame {
    private final Usuario usuario;
    private final JPanel contentPanel = new JPanel(new CardLayout());
    private final Color sidebarBg = Constants.COLOR_SIDEBAR;
    private final Color sidebarText = new Color(0xCBD5E1);
    private final JLabel lblTitulo = new JLabel("Dashboard", SwingConstants.LEFT);
    private final DecimalFormat sf = new DecimalFormat("S/ #,##0.00");
    private final JLabel lblReloj = new JLabel();

    public DashboardView(Usuario usuario) {
        this.usuario = usuario;
        setTitle(Constants.APP_NAME);
        setDefaultCloseOperation(EXIT_ON_CLOSE);
        setSize(1280, 780);
        setLocationRelativeTo(null);
        setMinimumSize(new Dimension(1024, 600));

        setLayout(new BorderLayout(0, 0));

        add(crearSidebar(), BorderLayout.WEST);
        add(crearMainArea(), BorderLayout.CENTER);

        cargarDashboard();
        iniciarReloj();
    }

    private JPanel crearSidebar() {
        JPanel sidebar = new JPanel(new MigLayout("fillx,insets 0, gap 0", "[220px]"));
        sidebar.setBackground(sidebarBg);

        JPanel header = new JPanel(new MigLayout("insets 20 15 15 15, gap 0"));
        header.setBackground(sidebarBg);
        JLabel logo = new JLabel("\uD83C\uDF7D\uFE0F  SJL 2026", SwingConstants.CENTER);
        logo.setFont(new Font("Segoe UI", Font.BOLD, 18));
        logo.setForeground(Color.WHITE);
        header.add(logo, "wrap");
        JLabel userLabel = new JLabel(usuario.getNombre() + " (" + usuario.getRolNombre() + ")", SwingConstants.CENTER);
        userLabel.setFont(new Font("Segoe UI", Font.PLAIN, 12));
        userLabel.setForeground(sidebarText);
        header.add(userLabel, "wrap");
        sidebar.add(header, "wrap");

        JSeparator sep = new JSeparator();
        sep.setForeground(new Color(0x334155));
        sidebar.add(sep, "wrap, growx");

        String[][] menus = {
            {"\uD83D\uDCCA  Dashboard", "dashboard"},
            {"\uD83D\uDED2  Ventas", "ventas"},
            {"\uD83D\uDCE6  Inventario", "inventario"},
            {"\uD83D\uDCCB  Pedidos", "pedidos"},
            {"\uD83D\uDCB0  Caja", "caja"},
            {"\uD83D\uDCC8  Reportes", "reportes"},
            {"\uD83D\uDD12  Configuraci\u00F3n", "config"}
        };

        ButtonGroup group = new ButtonGroup();
        for (String[] m : menus) {
            JButton btn = new JButton(m[0]);
            btn.setActionCommand(m[1]);
            btn.setHorizontalAlignment(SwingConstants.LEFT);
            btn.setFont(new Font("Segoe UI", Font.PLAIN, 14));
            btn.setForeground(sidebarText);
            btn.setBackground(sidebarBg);
            btn.setBorder(BorderFactory.createEmptyBorder(12, 20, 12, 20));
            btn.setFocusPainted(false);
            btn.setCursor(new Cursor(Cursor.HAND_CURSOR));
            btn.setContentAreaFilled(false);
            btn.setOpaque(true);

            btn.addMouseListener(new java.awt.event.MouseAdapter() {
                @Override public void mouseEntered(java.awt.event.MouseEvent e) {
                    if (!btn.isSelected()) btn.setBackground(Constants.COLOR_SIDEBAR_HOVER);
                }
                @Override public void mouseExited(java.awt.event.MouseEvent e) {
                    if (!btn.isSelected()) btn.setBackground(sidebarBg);
                }
            });

            btn.addActionListener(e -> {
                for (Component c : sidebar.getComponents())
                    if (c instanceof JButton) ((JButton)c).setBackground(sidebarBg);
                btn.setBackground(Constants.COLOR_PRIMARY);
                btn.setForeground(Color.WHITE);
                lblTitulo.setText(m[0].trim());
                mostrarPanel(m[1]);
            });

            group.add(btn);
            sidebar.add(btn, "wrap, growx");
        }

        sidebar.add(Box.createVerticalGlue(), "wrap, push");

        JButton btnSalir = new JButton("\uD83D\uDEAA  Cerrar Sesi\u00F3n");
        btnSalir.setHorizontalAlignment(SwingConstants.LEFT);
        btnSalir.setFont(new Font("Segoe UI", Font.PLAIN, 13));
        btnSalir.setForeground(new Color(0xF87171));
        btnSalir.setBackground(sidebarBg);
        btnSalir.setBorder(BorderFactory.createEmptyBorder(12, 20, 12, 20));
        btnSalir.setFocusPainted(false);
        btnSalir.setCursor(new Cursor(Cursor.HAND_CURSOR));
        btnSalir.setContentAreaFilled(false);
        btnSalir.setOpaque(true);
        btnSalir.addActionListener(e -> {
            dispose();
            new LoginView().setVisible(true);
        });
        sidebar.add(btnSalir, "wrap, growx, gapbottom 10");

        return sidebar;
    }

    private JPanel crearMainArea() {
        JPanel main = new JPanel(new BorderLayout());

        JPanel topBar = new JPanel(new MigLayout("insets 10 20 10 20, fillx", "[][right]push[right]"));
        topBar.setBackground(Color.WHITE);
        topBar.setBorder(BorderFactory.createMatteBorder(0, 0, 1, 0, Constants.COLOR_BORDER));

        lblTitulo.setFont(new Font("Segoe UI", Font.BOLD, 20));
        lblTitulo.setForeground(Constants.COLOR_TEXT);
        topBar.add(lblTitulo);

        lblReloj.setFont(new Font("Segoe UI", Font.PLAIN, 13));
        lblReloj.setForeground(Constants.COLOR_TEXT_SECONDARY);
        topBar.add(lblReloj, "gapright 15");

        JLabel lblUser = new JLabel(usuario.getNombre());
        lblUser.setFont(new Font("Segoe UI", Font.BOLD, 13));
        lblUser.setForeground(Constants.COLOR_TEXT);
        topBar.add(lblUser);

        main.add(topBar, BorderLayout.NORTH);

        contentPanel.setBackground(Constants.COLOR_BG_CARD);
        contentPanel.add(crearPanelDashboard(), "dashboard");
        contentPanel.add(crearPanelVentas(), "ventas");
        contentPanel.add(crearPanelInventario(), "inventario");
        contentPanel.add(new JPanel(), "pedidos");
        contentPanel.add(new JPanel(), "caja");
        contentPanel.add(new JPanel(), "reportes");
        contentPanel.add(new JPanel(), "config");

        main.add(contentPanel, BorderLayout.CENTER);
        return main;
    }

    private JPanel crearPanelDashboard() {
        JPanel p = new JPanel(new MigLayout("insets 20, gap 15", "[250px]250px[250px]250px[250px]250px", "[]150px[250px]push"));
        p.setBackground(Constants.COLOR_BG_CARD);

        p.add(crearKpiCard("\uD83D\uDCB5  Ventas Hoy", "S/ 0.00", Constants.COLOR_SUCCESS), "");
        p.add(crearKpiCard("\uD83D\uDCCB  Pedidos", "0", Constants.COLOR_PRIMARY), "");
        p.add(crearKpiCard("\u26A0\uFE0F  Stock Bajo", "0", Constants.COLOR_WARNING), "");
        p.add(crearKpiCard("\uD83D\uDCC8  Ganancias", "S/ 0.00", Constants.COLOR_SECONDARY), "wrap");

        JPanel tablaPanel = new JPanel(new BorderLayout());
        tablaPanel.setBackground(Color.WHITE);
        tablaPanel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(Constants.COLOR_BORDER),
                new EmptyBorder(10, 10, 10, 10)));
        JLabel lblProd = new JLabel("Productos m\u00E1s vendidos hoy");
        lblProd.setFont(new Font("Segoe UI", Font.BOLD, 14));
        tablaPanel.add(lblProd, BorderLayout.NORTH);
        JTable tabla = new JTable(new DefaultTableModel(new Object[]{"Producto", "Cant", "Total"}, 0));
        tabla.setRowHeight(30);
        tabla.setFont(new Font("Segoe UI", Font.PLAIN, 13));
        tabla.getTableHeader().setFont(new Font("Segoe UI", Font.BOLD, 12));
        tabla.setShowHorizontalLines(true);
        tabla.setGridColor(Constants.COLOR_BORDER);
        tablaPanel.add(new JScrollPane(tabla), BorderLayout.CENTER);
        p.add(tablaPanel, "span 2, grow");

        JPanel gastosPanel = new JPanel(new BorderLayout());
        gastosPanel.setBackground(Color.WHITE);
        gastosPanel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(Constants.COLOR_BORDER),
                new EmptyBorder(10, 10, 10, 10)));
        JLabel lblGastos = new JLabel("\uD83D\uDCB8  Resumen");
        lblGastos.setFont(new Font("Segoe UI", Font.BOLD, 14));
        gastosPanel.add(lblGastos, BorderLayout.NORTH);
        JPanel resumenInner = new JPanel(new MigLayout("insets 15, gapy 10"));
        resumenInner.setBackground(Color.WHITE);
        resumenInner.add(new JLabel("Cargando..."), "");
        gastosPanel.add(resumenInner, BorderLayout.CENTER);
        p.add(gastosPanel, "span 2, grow, wrap");

        return p;
    }

    private JPanel crearKpiCard(String titulo, String valor, Color color) {
        JPanel card = new JPanel(new MigLayout("insets 15, gap 0")) {
            @Override protected void paintComponent(Graphics g) {
                super.paintComponent(g);
                Graphics2D g2 = (Graphics2D) g.create();
                g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
                g2.setColor(Color.WHITE);
                g2.fillRoundRect(0, 0, getWidth(), getHeight(), 12, 12);
                g2.setColor(new Color(color.getRed(), color.getGreen(), color.getBlue(), 30));
                g2.fillRoundRect(0, 0, 6, getHeight(), 6, 6);
                g2.dispose();
            }
        };
        card.setBackground(Color.WHITE);
        card.setBorder(BorderFactory.createEmptyBorder());

        JLabel lblTitulo = new JLabel(titulo);
        lblTitulo.setFont(new Font("Segoe UI", Font.PLAIN, 13));
        lblTitulo.setForeground(Constants.COLOR_TEXT_SECONDARY);
        card.add(lblTitulo, "wrap");

        JLabel lblValor = new JLabel(valor);
        lblValor.setName("valor");
        lblValor.setFont(new Font("Segoe UI", Font.BOLD, 22));
        lblValor.setForeground(color);
        card.add(lblValor, "wrap");

        return card;
    }

    private JPanel crearPanelVentas() {
        JPanel p = new JPanel(new BorderLayout());
        p.setBackground(Color.WHITE);
        JLabel lbl = new JLabel("M\u00F3dulo de Ventas - Pr\u00F3ximamente", SwingConstants.CENTER);
        lbl.setFont(new Font("Segoe UI", Font.PLAIN, 18));
        lbl.setForeground(Constants.COLOR_TEXT_SECONDARY);
        p.add(lbl);
        return p;
    }

    private JPanel crearPanelInventario() {
        JPanel p = new JPanel(new BorderLayout());
        p.setBackground(Color.WHITE);
        JLabel lbl = new JLabel("M\u00F3dulo de Inventario - Pr\u00F3ximamente", SwingConstants.CENTER);
        lbl.setFont(new Font("Segoe UI", Font.PLAIN, 18));
        lbl.setForeground(Constants.COLOR_TEXT_SECONDARY);
        p.add(lbl);
        return p;
    }

    private void mostrarPanel(String key) {
        CardLayout cl = (CardLayout) contentPanel.getLayout();
        cl.show(contentPanel, key);
    }

    private void cargarDashboard() {
        DashboardDAO dao = new DashboardDAO();
        Map<String, Object> resumen = dao.obtenerResumenDia();

        JPanel dashboardPanel = null;
        for (Component c : contentPanel.getComponents()) {
            if (c instanceof JPanel && ((JPanel)c).getComponents().length > 0) {
                JPanel p = (JPanel) c;
                for (Component comp : p.getComponents()) {
                    if (comp instanceof JPanel && ((JPanel)comp).getComponentCount() > 0) {
                        JPanel card = (JPanel) comp;
                        for (Component inner : card.getComponents()) {
                            if (inner instanceof JLabel && ((JLabel)inner).getName() == "valor") {
                                dashboardPanel = p;
                                break;
                            }
                        }
                    }
                }
            }
        }

        if (dashboardPanel != null) {
            Component[] comps = dashboardPanel.getComponents();
            int idx = 0;
            for (Component c : comps) {
                if (c instanceof JPanel) {
                    JPanel card = (JPanel) c;
                    for (Component inner : card.getComponents()) {
                        if (inner instanceof JLabel && ((JLabel)inner).getName() == "valor") {
                            JLabel lbl = (JLabel) inner;
                            switch (idx) {
                                case 0: lbl.setText(sf.format(resumen.getOrDefault("ventas", BigDecimal.ZERO))); break;
                                case 1: lbl.setText(String.valueOf(resumen.getOrDefault("cantidad", 0))); break;
                                case 3: lbl.setText(sf.format(BigDecimal.ZERO)); break;
                            }
                            idx++;
                        }
                    }
                }
            }
        }
    }

    private void iniciarReloj() {
        Timer t = new Timer(1000, e -> {
            SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm:ss");
            lblReloj.setText(sdf.format(new Date()));
        });
        t.start();
    }
}
