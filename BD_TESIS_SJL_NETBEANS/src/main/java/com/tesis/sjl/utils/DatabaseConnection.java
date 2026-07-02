package com.tesis.sjl.utils;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DatabaseConnection {
    private static final String URL = "jdbc:sqlserver://localhost:1433;databaseName=BD_TESIS_SJL_2026;encrypt=false;trustServerCertificate=true";
    private static final String USER = "sa";
    private static final String PASSWORD = "123456";
    private static Connection connection;

    public static Connection getConnection() throws SQLException {
        if (connection == null || connection.isClosed()) {
            connection = DriverManager.getConnection(URL, USER, PASSWORD);
        }
        return connection;
    }

    public static void close() {
        try { if (connection != null && !connection.isClosed()) connection.close(); }
        catch (SQLException e) { e.printStackTrace(); }
    }
}
