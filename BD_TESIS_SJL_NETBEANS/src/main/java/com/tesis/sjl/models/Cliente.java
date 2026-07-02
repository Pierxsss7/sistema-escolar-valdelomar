package com.tesis.sjl.models;

import java.math.BigDecimal;

public class Cliente {
    private int idCliente, puntos;
    private String dni, nombre, telefono, direccion;
    private boolean activo;
    private BigDecimal totalGastado;

    public int getIdCliente() { return idCliente; }
    public void setIdCliente(int v) { idCliente = v; }
    public int getPuntos() { return puntos; }
    public void setPuntos(int v) { puntos = v; }
    public String getDni() { return dni; }
    public void setDni(String v) { dni = v; }
    public String getNombre() { return nombre; }
    public void setNombre(String v) { nombre = v; }
    public String getTelefono() { return telefono; }
    public void setTelefono(String v) { telefono = v; }
    public String getDireccion() { return direccion; }
    public void setDireccion(String v) { direccion = v; }
    public boolean isActivo() { return activo; }
    public void setActivo(boolean v) { activo = v; }
    public BigDecimal getTotalGastado() { return totalGastado; }
    public void setTotalGastado(BigDecimal v) { totalGastado = v; }
    @Override public String toString() { return nombre + " (" + dni + ")"; }
}
