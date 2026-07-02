package com.tesis.sjl.dao;

import com.tesis.sjl.utils.DatabaseConnection;
import java.math.BigDecimal;
import java.sql.*;
import java.util.*;

public class DashboardDAO {
    public Map<String, Object> obtenerResumenDia() {
        Map<String, Object> resumen = new LinkedHashMap<>();
        String sql = "SELECT ISNULL(SUM(total),0) ventas, ISNULL(SUM(descuento),0) descuentos, COUNT(*) cantidad FROM Ventas.Ventas WHERE CAST(fecha AS DATE) = CAST(SYSDATETIME() AS DATE)";
        try (Connection cn = DatabaseConnection.getConnection();
             Statement st = cn.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            if (rs.next()) {
                resumen.put("ventas", rs.getBigDecimal("ventas"));
                resumen.put("descuentos", rs.getBigDecimal("descuentos"));
                resumen.put("cantidad", rs.getInt("cantidad"));
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return resumen;
    }

    public List<Object[]> productosMasVendidos() {
        List<Object[]> lista = new ArrayList<>();
        String sql = "SELECT TOP 5 p.nombre, SUM(dv.cantidad) cant, SUM(dv.subtotal) total " +
                     "FROM Ventas.DetalleVenta dv JOIN Ventas.Ventas v ON v.id_venta=dv.id_venta " +
                     "JOIN Inventario.Productos p ON p.id_producto=dv.id_producto " +
                     "WHERE CAST(v.fecha AS DATE)=CAST(SYSDATETIME() AS DATE) " +
                     "GROUP BY p.nombre ORDER BY SUM(dv.cantidad) DESC";
        try (Connection cn = DatabaseConnection.getConnection();
             Statement st = cn.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) lista.add(new Object[]{rs.getString("nombre"), rs.getBigDecimal("cant"), rs.getBigDecimal("total")});
        } catch (SQLException e) { e.printStackTrace(); }
        return lista;
    }

    public BigDecimal obtenerGastosDia() {
        try (Connection cn = DatabaseConnection.getConnection();
             Statement st = cn.createStatement();
             ResultSet rs = st.executeQuery("SELECT ISNULL(SUM(monto),0) FROM Finanzas.Gastos WHERE CAST(fecha AS DATE)=CAST(SYSDATETIME() AS DATE)")) {
            return rs.next() ? rs.getBigDecimal(1) : BigDecimal.ZERO;
        } catch (SQLException e) { e.printStackTrace(); return BigDecimal.ZERO; }
    }
}
