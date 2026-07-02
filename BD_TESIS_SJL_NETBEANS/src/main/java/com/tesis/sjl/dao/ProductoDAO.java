package com.tesis.sjl.dao;

import com.tesis.sjl.models.Producto;
import com.tesis.sjl.utils.DatabaseConnection;
import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ProductoDAO {
    public List<Producto> listarActivos() {
        List<Producto> lista = new ArrayList<>();
        String sql = "SELECT p.*, c.nombre AS categoria FROM Inventario.Productos p " +
                     "JOIN Inventario.Categorias c ON c.id_categoria = p.id_categoria WHERE p.activo = 1";
        try (Connection cn = DatabaseConnection.getConnection();
             Statement st = cn.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) lista.add(mapear(rs));
        } catch (SQLException e) { e.printStackTrace(); }
        return lista;
    }

    public List<Producto> buscar(String texto) {
        List<Producto> lista = new ArrayList<>();
        String sql = "SELECT p.*, c.nombre AS categoria FROM Inventario.Productos p " +
                     "JOIN Inventario.Categorias c ON c.id_categoria = p.id_categoria " +
                     "WHERE p.activo = 1 AND (p.nombre LIKE ? OR p.codigo_barras LIKE ?)";
        try (Connection cn = DatabaseConnection.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, "%" + texto + "%");
            ps.setString(2, "%" + texto + "%");
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) lista.add(mapear(rs));
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return lista;
    }

    public List<Producto> bajoStock() {
        List<Producto> lista = new ArrayList<>();
        String sql = "SELECT p.*, c.nombre AS categoria FROM Inventario.Productos p " +
                     "JOIN Inventario.Categorias c ON c.id_categoria = p.id_categoria " +
                     "WHERE p.activo = 1 AND p.stock_actual <= p.stock_minimo";
        try (Connection cn = DatabaseConnection.getConnection();
             Statement st = cn.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) lista.add(mapear(rs));
        } catch (SQLException e) { e.printStackTrace(); }
        return lista;
    }

    public boolean insertar(Producto p) {
        String sql = "INSERT INTO Inventario.Productos (id_categoria, nombre, tipo, precio_venta, costo_unitario, stock_actual, stock_minimo) VALUES (?,?,?,?,?,?,?)";
        try (Connection cn = DatabaseConnection.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, p.getIdCategoria());
            ps.setString(2, p.getNombre());
            ps.setString(3, p.getTipo());
            ps.setBigDecimal(4, p.getPrecioVenta());
            ps.setBigDecimal(5, p.getCostoUnitario());
            ps.setBigDecimal(6, p.getStockActual());
            ps.setBigDecimal(7, p.getStockMinimo());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); return false; }
    }

    public boolean actualizar(Producto p) {
        String sql = "UPDATE Inventario.Productos SET id_categoria=?, nombre=?, precio_venta=?, costo_unitario=?, stock_minimo=? WHERE id_producto=?";
        try (Connection cn = DatabaseConnection.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, p.getIdCategoria());
            ps.setString(2, p.getNombre());
            ps.setBigDecimal(3, p.getPrecioVenta());
            ps.setBigDecimal(4, p.getCostoUnitario());
            ps.setBigDecimal(5, p.getStockMinimo());
            ps.setInt(6, p.getIdProducto());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); return false; }
    }

    private Producto mapear(ResultSet rs) throws SQLException {
        Producto p = new Producto();
        p.setIdProducto(rs.getInt("id_producto"));
        p.setIdCategoria(rs.getInt("id_categoria"));
        p.setNombre(rs.getString("nombre"));
        p.setTipo(rs.getString("tipo"));
        p.setCodigoBarras(rs.getString("codigo_barras"));
        p.setCategoriaNombre(rs.getString("categoria"));
        p.setPrecioVenta(rs.getBigDecimal("precio_venta"));
        p.setCostoUnitario(rs.getBigDecimal("costo_unitario"));
        p.setStockActual(rs.getBigDecimal("stock_actual"));
        p.setStockMinimo(rs.getBigDecimal("stock_minimo"));
        p.setActivo(rs.getBoolean("activo"));
        return p;
    }
}
