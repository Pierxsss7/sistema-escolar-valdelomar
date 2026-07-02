package com.tesis.sjl.models;

import java.math.BigDecimal;

public class Producto {
    private int idProducto, idCategoria;
    private String nombre, tipo, codigoBarras, categoriaNombre;
    private BigDecimal precioVenta, costoUnitario, stockActual, stockMinimo;
    private boolean activo;

    public int getIdProducto() { return idProducto; }
    public void setIdProducto(int v) { idProducto = v; }
    public int getIdCategoria() { return idCategoria; }
    public void setIdCategoria(int v) { idCategoria = v; }
    public String getNombre() { return nombre; }
    public void setNombre(String v) { nombre = v; }
    public String getTipo() { return tipo; }
    public void setTipo(String v) { tipo = v; }
    public String getCodigoBarras() { return codigoBarras; }
    public void setCodigoBarras(String v) { codigoBarras = v; }
    public String getCategoriaNombre() { return categoriaNombre; }
    public void setCategoriaNombre(String v) { categoriaNombre = v; }
    public BigDecimal getPrecioVenta() { return precioVenta; }
    public void setPrecioVenta(BigDecimal v) { precioVenta = v; }
    public BigDecimal getCostoUnitario() { return costoUnitario; }
    public void setCostoUnitario(BigDecimal v) { costoUnitario = v; }
    public BigDecimal getStockActual() { return stockActual; }
    public void setStockActual(BigDecimal v) { stockActual = v; }
    public BigDecimal getStockMinimo() { return stockMinimo; }
    public void setStockMinimo(BigDecimal v) { stockMinimo = v; }
    public boolean isActivo() { return activo; }
    public void setActivo(boolean v) { activo = v; }
    @Override public String toString() { return nombre; }
}
