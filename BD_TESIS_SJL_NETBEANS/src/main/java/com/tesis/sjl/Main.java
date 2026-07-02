package com.tesis.sjl;

import com.formdev.flatlaf.FlatLightLaf;
import com.formdev.flatlaf.themes.FlatMacLightLaf;
import com.tesis.sjl.views.LoginView;
import javax.swing.UIManager;
import javax.swing.UnsupportedLookAndFeelException;

public class Main {
    public static void main(String[] args) {
        try {
            FlatMacLightLaf.setup();
            UIManager.put("Button.arc", 10);
            UIManager.put("Component.arc", 8);
            UIManager.put("TabbedPane.tabArc", 8);
            UIManager.put("Table.showHorizontalLines", true);
            UIManager.put("Table.rowHeight", 36);
        } catch (Exception e) {
            try { UIManager.setLookAndFeel(new FlatLightLaf()); }
            catch (UnsupportedLookAndFeelException ex) { ex.printStackTrace(); }
        }
        new LoginView().setVisible(true);
    }
}
