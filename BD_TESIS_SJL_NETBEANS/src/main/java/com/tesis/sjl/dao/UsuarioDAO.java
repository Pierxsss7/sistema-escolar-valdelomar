package com.tesis.sjl.dao;

import com.tesis.sjl.models.Usuario;
import com.tesis.sjl.utils.DatabaseConnection;
import java.sql.*;

public class UsuarioDAO {
    public Usuario login(String usuario, String clave) {
        String sql = "SELECT u.*, r.nombre AS rol FROM Seguridad.Usuarios u " +
                     "JOIN Seguridad.Roles r ON r.id_rol = u.id_rol " +
                     "WHERE u.usuario = ? AND u.clave = ? AND u.activo = 1";
        try (Connection cn = DatabaseConnection.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, usuario);
            ps.setString(2, clave);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Usuario u = new Usuario();
                    u.setIdUsuario(rs.getInt("id_usuario"));
                    u.setIdRol(rs.getInt("id_rol"));
                    u.setNombre(rs.getString("nombre"));
                    u.setUsuario(rs.getString("usuario"));
                    u.setRolNombre(rs.getString("rol"));
                    u.setActivo(rs.getBoolean("activo"));
                    return u;
                }
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return null;
    }

    public void actualizarUltimoAcceso(int idUsuario) {
        try (Connection cn = DatabaseConnection.getConnection();
             PreparedStatement ps = cn.prepareStatement("UPDATE Seguridad.Usuarios SET ultimo_acceso = SYSDATETIME() WHERE id_usuario = ?")) {
            ps.setInt(1, idUsuario);
            ps.executeUpdate();
        } catch (SQLException e) { e.printStackTrace(); }
    }
}
