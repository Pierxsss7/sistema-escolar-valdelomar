IF EXISTS (SELECT 1 FROM sys.databases WHERE name = N'BD_SJL')
BEGIN
    ALTER DATABASE BD_SJL SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BD_SJL;
END
GO

CREATE DATABASE BD_SJL;
GO

USE BD_SJL;
GO

CREATE SCHEMA seg;
GO
CREATE SCHEMA negocio;
GO
CREATE SCHEMA producto;
GO
CREATE SCHEMA venta;
GO
CREATE SCHEMA compra;
GO
CREATE SCHEMA inventario;
GO
CREATE SCHEMA financiero;
GO
CREATE SCHEMA produccion;
GO
CREATE SCHEMA auditoria;
GO

-- USUARIOS Y ROLES
CREATE TABLE seg.roles (
    id_rol INT IDENTITY PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL
);
GO

CREATE TABLE seg.permisos (
    id_permiso INT IDENTITY PRIMARY KEY,
    codigo VARCHAR(30) NOT NULL,
    nombre VARCHAR(80) NOT NULL
);
GO

CREATE TABLE seg.rol_permiso (
    id_rol INT NOT NULL,
    id_permiso INT NOT NULL,
    PRIMARY KEY (id_rol, id_permiso),
    FOREIGN KEY (id_rol) REFERENCES seg.roles(id_rol),
    FOREIGN KEY (id_permiso) REFERENCES seg.permisos(id_permiso)
);
GO

CREATE TABLE seg.usuarios (
    id_usuario INT IDENTITY PRIMARY KEY,
    id_rol INT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    usuario VARCHAR(50) NOT NULL,
    clave VARCHAR(255) NOT NULL,
    activo BIT NOT NULL DEFAULT 1,
    FOREIGN KEY (id_rol) REFERENCES seg.roles(id_rol)
);
GO

-- PROVEEDORES Y CLIENTES
CREATE TABLE negocio.proveedores (
    id_proveedor INT IDENTITY PRIMARY KEY,
    ruc VARCHAR(11) NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    telefono VARCHAR(20),
    direccion VARCHAR(200),
    activo BIT NOT NULL DEFAULT 1
);
GO

CREATE TABLE negocio.clientes (
    id_cliente INT IDENTITY PRIMARY KEY,
    dni VARCHAR(8) NOT NULL,
    nombre VARCHAR(120) NOT NULL,
    telefono VARCHAR(20),
    direccion VARCHAR(200),
    activo BIT NOT NULL DEFAULT 1
);
GO

-- PRODUCTOS
CREATE TABLE producto.categorias (
    id_categoria INT IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL
);
GO

CREATE TABLE producto.productos (
    id_producto INT IDENTITY PRIMARY KEY,
    id_categoria INT NOT NULL,
    nombre VARCHAR(120) NOT NULL,
    tipo VARCHAR(15) NOT NULL,
    precio_venta DECIMAL(10,2) NOT NULL DEFAULT 0,
    costo DECIMAL(10,2) NOT NULL DEFAULT 0,
    stock DECIMAL(10,2) NOT NULL DEFAULT 0,
    stock_minimo DECIMAL(10,2) NOT NULL DEFAULT 0,
    activo BIT NOT NULL DEFAULT 1,
    FOREIGN KEY (id_categoria) REFERENCES producto.categorias(id_categoria)
);
GO

-- RECETAS
CREATE TABLE produccion.recetas (
    id_receta INT IDENTITY PRIMARY KEY,
    id_producto INT NOT NULL,
    nombre VARCHAR(120) NOT NULL,
    rendimiento DECIMAL(10,2) NOT NULL DEFAULT 1,
    FOREIGN KEY (id_producto) REFERENCES producto.productos(id_producto)
);
GO

CREATE TABLE produccion.detalle_receta (
    id_detalle INT IDENTITY PRIMARY KEY,
    id_receta INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (id_receta) REFERENCES produccion.recetas(id_receta),
    FOREIGN KEY (id_producto) REFERENCES producto.productos(id_producto)
);
GO

-- COMPRAS
CREATE TABLE compra.compras (
    id_compra INT IDENTITY PRIMARY KEY,
    id_proveedor INT NOT NULL,
    id_usuario INT NOT NULL,
    total DECIMAL(10,2) NOT NULL,
    fecha DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (id_proveedor) REFERENCES negocio.proveedores(id_proveedor),
    FOREIGN KEY (id_usuario) REFERENCES seg.usuarios(id_usuario)
);
GO

CREATE TABLE compra.detalle_compra (
    id_detalle INT IDENTITY PRIMARY KEY,
    id_compra INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad DECIMAL(10,2) NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (id_compra) REFERENCES compra.compras(id_compra),
    FOREIGN KEY (id_producto) REFERENCES producto.productos(id_producto)
);
GO

-- VENTAS
CREATE TABLE venta.ventas (
    id_venta INT IDENTITY PRIMARY KEY,
    id_cliente INT,
    id_usuario INT NOT NULL,
    total DECIMAL(10,2) NOT NULL,
    fecha DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (id_cliente) REFERENCES negocio.clientes(id_cliente),
    FOREIGN KEY (id_usuario) REFERENCES seg.usuarios(id_usuario)
);
GO

CREATE TABLE venta.detalle_venta (
    id_detalle INT IDENTITY PRIMARY KEY,
    id_venta INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad DECIMAL(10,2) NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (id_venta) REFERENCES venta.ventas(id_venta),
    FOREIGN KEY (id_producto) REFERENCES producto.productos(id_producto)
);
GO

-- PAGOS
CREATE TABLE financiero.metodos_pago (
    id_metodo INT IDENTITY PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL
);
GO

CREATE TABLE venta.pagos (
    id_pago INT IDENTITY PRIMARY KEY,
    id_venta INT NOT NULL,
    id_metodo INT NOT NULL,
    monto DECIMAL(10,2) NOT NULL,
    referencia VARCHAR(100),
    FOREIGN KEY (id_venta) REFERENCES venta.ventas(id_venta),
    FOREIGN KEY (id_metodo) REFERENCES financiero.metodos_pago(id_metodo)
);
GO

-- DATOS INICIALES
INSERT INTO seg.roles (nombre) VALUES
('ADMINISTRADOR'), ('CAJERO'), ('COCINA'), ('ALMACENERO');
GO

INSERT INTO seg.permisos (codigo, nombre) VALUES
('USUARIOS', 'Usuarios'), ('PRODUCTOS', 'Productos'),
('VENTAS', 'Ventas'), ('COMPRAS', 'Compras'),
('INVENTARIO', 'Inventario'), ('CAJA', 'Caja'),
('REPORTES', 'Reportes'), ('RECETAS', 'Recetas');
GO

INSERT INTO seg.rol_permiso (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso FROM seg.roles r, seg.permisos p WHERE r.nombre = 'ADMINISTRADOR';
GO

INSERT INTO seg.usuarios (id_rol, nombre, usuario, clave) VALUES
(1, 'Admin', 'admin', 'admin123'),
(2, 'Cajero', 'cajero', 'cajero123');
GO

INSERT INTO negocio.proveedores (ruc, nombre, telefono, direccion) VALUES
('20123456789', 'Mercado Mayorista SJL', '987000001', 'Av. Central SJL'),
('20123456788', 'Distribuidora San Juan', '987000002', 'Jr. Las Flores 123');
GO

INSERT INTO negocio.clientes (dni, nombre, telefono) VALUES
('00000000', 'Cliente General', ''),
('12345678', 'Juan Perez', '987654321'),
('87654321', 'Maria Lopez', '987654322');
GO

INSERT INTO financiero.metodos_pago (nombre) VALUES
('EFECTIVO'), ('YAPE'), ('PLIN'), ('TARJETA'), ('TRANSFERENCIA');
GO

-- CATEGORIAS CON PRODUCTOS REALES
INSERT INTO producto.categorias (nombre) VALUES
('Verduras y Hortalizas'),
('Carnes y Aves'),
('Abarrotes y Condimentos'),
('Lacteos y Huevos'),
('Bebidas'),
('Platos de Fondo'),
('Entradas y Sopas'),
('Combos'),
('Postres');
GO

-- VERDURAS
INSERT INTO producto.productos (id_categoria, nombre, tipo, precio_venta, costo, stock, stock_minimo) VALUES
(1, 'Papa Amarilla', 'INSUMO', 0, 2.50, 10, 3),
(1, 'Papa Blanca', 'INSUMO', 0, 2.00, 15, 5),
(1, 'Camote', 'INSUMO', 0, 3.00, 8, 2),
(1, 'Yuca', 'INSUMO', 0, 2.80, 6, 2),
(1, 'Zanahoria', 'INSUMO', 0, 2.00, 10, 3),
(1, 'Cebolla Roja', 'INSUMO', 0, 2.50, 12, 4),
(1, 'Cebolla Blanca', 'INSUMO', 0, 2.50, 8, 2),
(1, 'Tomate', 'INSUMO', 0, 3.00, 10, 3),
(1, 'Ajo', 'INSUMO', 0, 5.00, 5, 2),
(1, 'Kion', 'INSUMO', 0, 4.00, 3, 1),
(1, 'Lechuga', 'INSUMO', 0, 1.50, 8, 3),
(1, 'Espinaca', 'INSUMO', 0, 2.00, 5, 2),
(1, 'Apio', 'INSUMO', 0, 1.50, 6, 2),
(1, 'Culantro', 'INSUMO', 0, 1.00, 10, 4),
(1, 'Perejil', 'INSUMO', 0, 1.00, 8, 3),
(1, 'Rocoto', 'INSUMO', 0, 3.00, 4, 1),
(1, 'Aji Amarillo', 'INSUMO', 0, 4.00, 5, 2),
(1, 'Pimiento', 'INSUMO', 0, 3.50, 5, 2),
(1, 'Zapallo', 'INSUMO', 0, 2.00, 8, 2),
(1, 'Vainita', 'INSUMO', 0, 3.00, 5, 2),
(1, 'Choclo', 'INSUMO', 0, 2.00, 10, 3),
(1, 'Arveja', 'INSUMO', 0, 4.00, 5, 2),
(1, 'Palta', 'INSUMO', 0, 5.00, 6, 2),
(1, 'Limón', 'INSUMO', 0, 2.00, 15, 5);
GO

-- CARNES Y AVES
INSERT INTO producto.productos (id_categoria, nombre, tipo, precio_venta, costo, stock, stock_minimo) VALUES
(2, 'Pollo Entero', 'INSUMO', 0, 8.00, 10, 3),
(2, 'Pollo Pierna', 'INSUMO', 0, 9.00, 8, 3),
(2, 'Pollo Pechuga', 'INSUMO', 0, 12.00, 8, 3),
(2, 'Pollo Ala', 'INSUMO', 0, 7.00, 6, 2),
(2, 'Carne de Res Molida', 'INSUMO', 0, 15.00, 5, 2),
(2, 'Carne de Res Lomo', 'INSUMO', 0, 22.00, 4, 1),
(2, 'Carne Cerdo', 'INSUMO', 0, 14.00, 4, 1),
(2, 'Pescado Merluza', 'INSUMO', 0, 10.00, 5, 2),
(2, 'Pescado Bonito', 'INSUMO', 0, 12.00, 4, 1),
(2, 'Pescado Lenguado', 'INSUMO', 0, 18.00, 3, 1),
(2, 'Huevo', 'INSUMO', 0, 1.50, 30, 10);
GO

-- ABARROTES
INSERT INTO producto.productos (id_categoria, nombre, tipo, precio_venta, costo, stock, stock_minimo) VALUES
(3, 'Arroz', 'INSUMO', 0, 3.50, 25, 10),
(3, 'Fideo Tallarin', 'INSUMO', 0, 2.50, 15, 5),
(3, 'Fideo Canelon', 'INSUMO', 0, 3.00, 10, 3),
(3, 'Aceite Vegetal', 'INSUMO', 0, 7.00, 10, 3),
(3, 'Sal', 'INSUMO', 0, 1.00, 10, 3),
(3, 'Azucar', 'INSUMO', 0, 3.00, 10, 3),
(3, 'Vinagre', 'INSUMO', 0, 2.50, 5, 2),
(3, 'Sillao', 'INSUMO', 0, 3.50, 5, 2),
(3, 'Comino', 'INSUMO', 0, 1.50, 4, 1),
(3, 'Pimienta', 'INSUMO', 0, 1.50, 4, 1),
(3, 'Oregano', 'INSUMO', 0, 1.50, 3, 1),
(3, 'Laurel', 'INSUMO', 0, 1.00, 3, 1),
(3, 'Caldo de Pollo', 'INSUMO', 0, 2.00, 8, 3),
(3, 'Caldo de Carne', 'INSUMO', 0, 2.00, 5, 2),
(3, 'Leche Evaporada', 'INSUMO', 0, 3.50, 10, 3),
(3, 'Leche Condensada', 'INSUMO', 0, 4.50, 5, 2),
(3, 'Harina', 'INSUMO', 0, 2.50, 8, 3),
(3, 'Pan Rayado', 'INSUMO', 0, 3.00, 4, 1),
(3, 'Mayonesa', 'INSUMO', 0, 5.00, 5, 2),
(3, 'Mostaza', 'INSUMO', 0, 3.00, 3, 1),
(3, 'Ketchup', 'INSUMO', 0, 3.00, 3, 1),
(3, 'Conserva de Pescado', 'INSUMO', 0, 4.00, 5, 2),
(3, 'Tomate Enlatado', 'INSUMO', 0, 3.50, 4, 1),
(3, 'Arverja Enlatada', 'INSUMO', 0, 3.00, 3, 1);
GO

-- LACTEOS
INSERT INTO producto.productos (id_categoria, nombre, tipo, precio_venta, costo, stock, stock_minimo) VALUES
(4, 'Queso Fresco', 'INSUMO', 0, 8.00, 5, 2),
(4, 'Queso Parmesano', 'INSUMO', 0, 12.00, 3, 1),
(4, 'Mantequilla', 'INSUMO', 0, 5.00, 5, 2),
(4, 'Yogurt Natural', 'INSUMO', 0, 4.00, 6, 2),
(4, 'Crema de Leche', 'INSUMO', 0, 6.00, 4, 1);
GO

-- BEBIDAS
INSERT INTO producto.productos (id_categoria, nombre, tipo, precio_venta, costo, stock, stock_minimo) VALUES
(5, 'Gaseosa Coca Cola 500ml', 'VENTA', 3.50, 2.00, 30, 10),
(5, 'Gaseosa Inca Kola 500ml', 'VENTA', 3.50, 2.00, 30, 10),
(5, 'Gaseosa Sprite 500ml', 'VENTA', 3.50, 2.00, 20, 8),
(5, 'Gaseosa Fanta 500ml', 'VENTA', 3.50, 2.00, 15, 5),
(5, 'Agua Mineral 500ml', 'VENTA', 2.00, 1.00, 25, 10),
(5, 'Agua Mineral 1L', 'VENTA', 3.00, 1.50, 15, 5),
(5, 'Jugo de Naranja Natural', 'VENTA', 5.00, 2.00, 10, 3),
(5, 'Jugo de Maracuya', 'VENTA', 5.00, 2.00, 8, 3),
(5, 'Chicha Morada', 'VENTA', 4.00, 1.50, 10, 4),
(5, 'Limonada', 'VENTA', 4.00, 1.50, 10, 4),
(5, 'Cafe Americano', 'VENTA', 4.00, 1.50, 15, 5),
(5, 'Cafe con Leche', 'VENTA', 5.00, 2.00, 10, 4),
(5, 'Te Helado', 'VENTA', 3.50, 1.00, 8, 3);
GO

-- PLATOS DE FONDO
INSERT INTO producto.productos (id_categoria, nombre, tipo, precio_venta, costo, stock, stock_minimo) VALUES
(6, 'Pollo a la Brasa 1/4', 'VENTA', 12.00, 6.00, 20, 5),
(6, 'Pollo a la Brasa 1/2', 'VENTA', 22.00, 11.00, 15, 4),
(6, 'Pollo a la Brasa Entero', 'VENTA', 40.00, 20.00, 10, 3),
(6, 'Ceviche Mixto', 'VENTA', 18.00, 8.00, 10, 3),
(6, 'Ceviche de Pescado', 'VENTA', 15.00, 7.00, 10, 3),
(6, 'Lomo Saltado', 'VENTA', 16.00, 8.00, 15, 4),
(6, 'Ají de Gallina', 'VENTA', 14.00, 6.00, 12, 4),
(6, 'Tallarin Verde', 'VENTA', 13.00, 5.00, 10, 3),
(6, 'Tallarin Saltado', 'VENTA', 15.00, 7.00, 10, 3),
(6, 'Arroz con Pollo', 'VENTA', 14.00, 6.00, 12, 4),
(6, 'Seco de Res', 'VENTA', 16.00, 8.00, 10, 3),
(6, 'Estofado de Pollo', 'VENTA', 13.00, 6.00, 10, 3),
(6, 'Bisteck a lo Pobre', 'VENTA', 18.00, 9.00, 8, 3),
(6, 'Pescado Frito', 'VENTA', 15.00, 7.00, 10, 3),
(6, 'Milanesa de Pollo', 'VENTA', 14.00, 6.50, 10, 3);
GO

-- ENTRADAS Y SOPAS
INSERT INTO producto.productos (id_categoria, nombre, tipo, precio_venta, costo, stock, stock_minimo) VALUES
(7, 'Sopa del Dia', 'VENTA', 6.00, 2.50, 15, 5),
(7, 'Sopa de Pollo', 'VENTA', 7.00, 3.00, 12, 4),
(7, 'Caldo de Gallina', 'VENTA', 10.00, 5.00, 10, 3),
(7, 'Papa Rellena', 'VENTA', 5.00, 2.00, 15, 5),
(7, 'Causa Rellena', 'VENTA', 6.00, 2.50, 10, 3),
(7, 'Tequeños (6 und)', 'VENTA', 8.00, 3.00, 10, 3),
(7, 'Salchipapa', 'VENTA', 7.00, 2.50, 15, 5),
(7, 'Chaufa de Pollo', 'VENTA', 12.00, 5.00, 10, 3);
GO

-- COMBOS
INSERT INTO producto.productos (id_categoria, nombre, tipo, precio_venta, costo, stock, stock_minimo) VALUES
(8, 'Combo Pollo + Gaseosa', 'VENTA', 15.00, 7.00, 10, 3),
(8, 'Combo Lomo + Gaseosa', 'VENTA', 18.00, 9.00, 8, 3),
(8, 'Combo Ceviche + Chicha', 'VENTA', 20.00, 9.50, 8, 2),
(8, 'Combo Familiar (2 pollos + 4 bebidas)', 'VENTA', 55.00, 28.00, 5, 2);
GO

-- POSTRES
INSERT INTO producto.productos (id_categoria, nombre, tipo, precio_venta, costo, stock, stock_minimo) VALUES
(9, 'Arroz con Leche', 'VENTA', 5.00, 1.50, 12, 4),
(9, 'Mazamorra Morada', 'VENTA', 5.00, 1.50, 10, 3),
(9, 'Picarones (4 und)', 'VENTA', 6.00, 2.00, 8, 3),
(9, 'Flan Casero', 'VENTA', 5.00, 2.00, 8, 3),
(9, 'Helado de Lúcuma', 'VENTA', 4.00, 1.50, 15, 5);
GO

PRINT 'BD_SJL creada con productos reales de comida peruana.';
GO
