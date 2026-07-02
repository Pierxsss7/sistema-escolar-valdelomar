IF EXISTS (SELECT 1 FROM sys.databases WHERE name = N'BD_TESIS_SJL_2026')
BEGIN
    ALTER DATABASE BD_TESIS_SJL_2026 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BD_TESIS_SJL_2026;
END
GO

CREATE DATABASE BD_TESIS_SJL_2026;
GO

USE BD_TESIS_SJL_2026;
GO

CREATE SCHEMA Ventas;
GO
CREATE SCHEMA Inventario;
GO
CREATE SCHEMA Pedidos;
GO
CREATE SCHEMA Seguridad;
GO
CREATE SCHEMA Finanzas;
GO

-- TABLA: Clientes
CREATE TABLE Ventas.Clientes (
    id_cliente INT IDENTITY PRIMARY KEY,
    dni VARCHAR(8) NOT NULL,
    nombre VARCHAR(120) NOT NULL,
    telefono VARCHAR(20),
    direccion VARCHAR(200),
    fecha_registro DATE NOT NULL DEFAULT CAST(SYSDATETIME() AS DATE),
    activo BIT NOT NULL DEFAULT 1
);
GO

-- TABLA: Categorias
CREATE TABLE Inventario.Categorias (
    id_categoria INT IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL
);
GO

-- TABLA: Productos
CREATE TABLE Inventario.Productos (
    id_producto INT IDENTITY PRIMARY KEY,
    id_categoria INT NOT NULL,
    nombre VARCHAR(120) NOT NULL,
    tipo VARCHAR(15) NOT NULL,
    precio_venta DECIMAL(10,2) NOT NULL DEFAULT 0,
    costo_unitario DECIMAL(10,2) NOT NULL DEFAULT 0,
    stock_actual DECIMAL(10,2) NOT NULL DEFAULT 0,
    stock_minimo DECIMAL(10,2) NOT NULL DEFAULT 0,
    activo BIT NOT NULL DEFAULT 1,
    FOREIGN KEY (id_categoria) REFERENCES Inventario.Categorias(id_categoria)
);
GO

-- TABLA: Proveedores
CREATE TABLE Inventario.Proveedores (
    id_proveedor INT IDENTITY PRIMARY KEY,
    ruc VARCHAR(11) NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    telefono VARCHAR(20),
    direccion VARCHAR(200),
    activo BIT NOT NULL DEFAULT 1
);
GO

-- TABLA: Compras
CREATE TABLE Inventario.Compras (
    id_compra INT IDENTITY PRIMARY KEY,
    id_proveedor INT NOT NULL,
    id_usuario INT NOT NULL,
    total DECIMAL(10,2) NOT NULL,
    fecha DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (id_proveedor) REFERENCES Inventario.Proveedores(id_proveedor)
);
GO

-- TABLA: DetalleCompra
CREATE TABLE Inventario.DetalleCompra (
    id_detalle INT IDENTITY PRIMARY KEY,
    id_compra INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad DECIMAL(10,2) NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (id_compra) REFERENCES Inventario.Compras(id_compra),
    FOREIGN KEY (id_producto) REFERENCES Inventario.Productos(id_producto)
);
GO

-- TABLA: Ventas
CREATE TABLE Ventas.Ventas (
    id_venta INT IDENTITY PRIMARY KEY,
    id_cliente INT,
    id_usuario INT NOT NULL,
    total DECIMAL(10,2) NOT NULL,
    fecha DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (id_cliente) REFERENCES Ventas.Clientes(id_cliente)
);
GO

-- TABLA: DetalleVenta
CREATE TABLE Ventas.DetalleVenta (
    id_detalle INT IDENTITY PRIMARY KEY,
    id_venta INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad DECIMAL(10,2) NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (id_venta) REFERENCES Ventas.Ventas(id_venta),
    FOREIGN KEY (id_producto) REFERENCES Inventario.Productos(id_producto)
);
GO

-- TABLA: Pedidos
CREATE TABLE Pedidos.Pedidos (
    id_pedido INT IDENTITY PRIMARY KEY,
    id_cliente INT,
    id_usuario INT NOT NULL,
    tipo VARCHAR(20) NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    direccion_entrega VARCHAR(200),
    telefono_contacto VARCHAR(20),
    total DECIMAL(10,2) NOT NULL,
    fecha DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (id_cliente) REFERENCES Ventas.Clientes(id_cliente)
);
GO

-- TABLA: DetallePedido
CREATE TABLE Pedidos.DetallePedido (
    id_detalle INT IDENTITY PRIMARY KEY,
    id_pedido INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad DECIMAL(10,2) NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (id_pedido) REFERENCES Pedidos.Pedidos(id_pedido),
    FOREIGN KEY (id_producto) REFERENCES Inventario.Productos(id_producto)
);
GO

-- TABLA: MetodosPago
CREATE TABLE Finanzas.MetodosPago (
    id_metodo INT IDENTITY PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL
);
GO

-- TABLA: Pagos
CREATE TABLE Finanzas.Pagos (
    id_pago INT IDENTITY PRIMARY KEY,
    id_venta INT,
    id_pedido INT,
    id_metodo INT NOT NULL,
    monto DECIMAL(10,2) NOT NULL,
    referencia VARCHAR(100),
    fecha DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (id_venta) REFERENCES Ventas.Ventas(id_venta),
    FOREIGN KEY (id_pedido) REFERENCES Pedidos.Pedidos(id_pedido),
    FOREIGN KEY (id_metodo) REFERENCES Finanzas.MetodosPago(id_metodo)
);
GO

-- TABLA: Roles
CREATE TABLE Seguridad.Roles (
    id_rol INT IDENTITY PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL
);
GO

-- TABLA: Usuarios
CREATE TABLE Seguridad.Usuarios (
    id_usuario INT IDENTITY PRIMARY KEY,
    id_rol INT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    usuario VARCHAR(50) NOT NULL,
    clave VARCHAR(255) NOT NULL,
    activo BIT NOT NULL DEFAULT 1,
    FOREIGN KEY (id_rol) REFERENCES Seguridad.Roles(id_rol)
);
GO

-- DATOS INICIALES
INSERT INTO Seguridad.Roles (nombre) VALUES
('ADMINISTRADOR'),
('CAJERO'),
('COCINA'),
('REPARTIDOR');
GO

INSERT INTO Seguridad.Usuarios (id_rol, nombre, usuario, clave) VALUES
(1, 'Administrador', 'admin', 'admin123'),
(2, 'Cajero Principal', 'cajero', 'cajero123');
GO

INSERT INTO Finanzas.MetodosPago (nombre) VALUES
('EFECTIVO'),
('YAPE'),
('PLIN'),
('TARJETA'),
('TRANSFERENCIA');
GO

INSERT INTO Ventas.Clientes (dni, nombre, telefono) VALUES
('00000000', 'Cliente General', ''),
('12345678', 'Juan Perez Garcia', '987654321'),
('87654321', 'Maria Lopez Rojas', '987654322'),
('45678912', 'Carlos Torres', '987654323');
GO

INSERT INTO Inventario.Proveedores (ruc, nombre, telefono, direccion) VALUES
('20123456789', 'Mercado Mayorista SJL', '987000001', 'Av. Central San Juan de Lurigancho'),
('20123456788', 'Distribuidora San Juan EIRL', '987000002', 'Jr. Las Flores 123 SJL'),
('20123456787', 'Avicola El Pollon SAC', '987000003', 'Av. Peru 456 SJL'),
('20123456786', 'Carnes del Norte SAC', '987000004', 'Jr. Los Olivos 789 SJL');
GO

INSERT INTO Inventario.Categorias (nombre) VALUES
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

-- VERDURAS (INSUMOS)
INSERT INTO Inventario.Productos (id_categoria, nombre, tipo, precio_venta, costo_unitario, stock_actual, stock_minimo) VALUES
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

-- CARNES (INSUMOS)
INSERT INTO Inventario.Productos (id_categoria, nombre, tipo, precio_venta, costo_unitario, stock_actual, stock_minimo) VALUES
(2, 'Pollo Entero', 'INSUMO', 0, 8.00, 10, 3),
(2, 'Pollo Pierna', 'INSUMO', 0, 9.00, 8, 3),
(2, 'Pollo Pechuga', 'INSUMO', 0, 12.00, 8, 3),
(2, 'Pollo Ala', 'INSUMO', 0, 7.00, 6, 2),
(2, 'Carne Molida de Res', 'INSUMO', 0, 15.00, 5, 2),
(2, 'Lomo de Res', 'INSUMO', 0, 22.00, 4, 1),
(2, 'Carne de Cerdo', 'INSUMO', 0, 14.00, 4, 1),
(2, 'Pescado Merluza', 'INSUMO', 0, 10.00, 5, 2),
(2, 'Pescado Bonito', 'INSUMO', 0, 12.00, 4, 1),
(2, 'Huevos (und)', 'INSUMO', 0, 1.50, 30, 10);
GO

-- ABARROTES (INSUMOS)
INSERT INTO Inventario.Productos (id_categoria, nombre, tipo, precio_venta, costo_unitario, stock_actual, stock_minimo) VALUES
(3, 'Arroz', 'INSUMO', 0, 3.50, 25, 10),
(3, 'Fideo Tallarin', 'INSUMO', 0, 2.50, 15, 5),
(3, 'Aceite Vegetal', 'INSUMO', 0, 7.00, 10, 3),
(3, 'Sal', 'INSUMO', 0, 1.00, 10, 3),
(3, 'Azucar', 'INSUMO', 0, 3.00, 10, 3),
(3, 'Vinagre', 'INSUMO', 0, 2.50, 5, 2),
(3, 'Sillao', 'INSUMO', 0, 3.50, 5, 2),
(3, 'Comino', 'INSUMO', 0, 1.50, 4, 1),
(3, 'Pimienta', 'INSUMO', 0, 1.50, 4, 1),
(3, 'Caldo de Pollo', 'INSUMO', 0, 2.00, 8, 3),
(3, 'Leche Evaporada', 'INSUMO', 0, 3.50, 10, 3),
(3, 'Harina', 'INSUMO', 0, 2.50, 8, 3),
(3, 'Mayonesa', 'INSUMO', 0, 5.00, 5, 2),
(3, 'Mostaza', 'INSUMO', 0, 3.00, 3, 1),
(3, 'Ketchup', 'INSUMO', 0, 3.00, 3, 1),
(3, 'Conserva de Pescado', 'INSUMO', 0, 4.00, 5, 2);
GO

-- BEBIDAS (PRODUCTOS DE VENTA)
INSERT INTO Inventario.Productos (id_categoria, nombre, tipo, precio_venta, costo_unitario, stock_actual, stock_minimo) VALUES
(5, 'Coca Cola 500ml', 'VENTA', 3.50, 2.00, 30, 10),
(5, 'Inca Kola 500ml', 'VENTA', 3.50, 2.00, 30, 10),
(5, 'Sprite 500ml', 'VENTA', 3.50, 2.00, 20, 8),
(5, 'Agua Mineral 500ml', 'VENTA', 2.00, 1.00, 25, 10),
(5, 'Jugo de Naranja', 'VENTA', 5.00, 2.00, 10, 3),
(5, 'Chicha Morada', 'VENTA', 4.00, 1.50, 10, 4),
(5, 'Limonada Natural', 'VENTA', 4.00, 1.50, 10, 4),
(5, 'Cafe Americano', 'VENTA', 4.00, 1.50, 15, 5),
(5, 'Cafe con Leche', 'VENTA', 5.00, 2.00, 10, 4);
GO

-- PLATOS DE FONDO (PRODUCTOS DE VENTA)
INSERT INTO Inventario.Productos (id_categoria, nombre, tipo, precio_venta, costo_unitario, stock_actual, stock_minimo) VALUES
(6, 'Pollo a la Brasa 1/4', 'VENTA', 12.00, 6.00, 20, 5),
(6, 'Pollo a la Brasa 1/2', 'VENTA', 22.00, 11.00, 15, 4),
(6, 'Pollo a la Brasa Entero', 'VENTA', 40.00, 20.00, 10, 3),
(6, 'Ceviche Mixto', 'VENTA', 18.00, 8.00, 10, 3),
(6, 'Ceviche de Pescado', 'VENTA', 15.00, 7.00, 10, 3),
(6, 'Lomo Saltado', 'VENTA', 16.00, 8.00, 15, 4),
(6, 'Aji de Gallina', 'VENTA', 14.00, 6.00, 12, 4),
(6, 'Tallarin Verde', 'VENTA', 13.00, 5.00, 10, 3),
(6, 'Tallarin Saltado', 'VENTA', 15.00, 7.00, 10, 3),
(6, 'Arroz con Pollo', 'VENTA', 14.00, 6.00, 12, 4),
(6, 'Seco de Res', 'VENTA', 16.00, 8.00, 10, 3),
(6, 'Estofado de Pollo', 'VENTA', 13.00, 6.00, 10, 3),
(6, 'Bisteck a lo Pobre', 'VENTA', 18.00, 9.00, 8, 3),
(6, 'Pescado Frito', 'VENTA', 15.00, 7.00, 10, 3),
(6, 'Milanesa de Pollo', 'VENTA', 14.00, 6.50, 10, 3);
GO

-- ENTRADAS Y SOPAS (PRODUCTOS DE VENTA)
INSERT INTO Inventario.Productos (id_categoria, nombre, tipo, precio_venta, costo_unitario, stock_actual, stock_minimo) VALUES
(7, 'Sopa del Dia', 'VENTA', 6.00, 2.50, 15, 5),
(7, 'Caldo de Gallina', 'VENTA', 10.00, 5.00, 10, 3),
(7, 'Papa Rellena', 'VENTA', 5.00, 2.00, 15, 5),
(7, 'Causa Rellena', 'VENTA', 6.00, 2.50, 10, 3),
(7, 'Tequeños (6 und)', 'VENTA', 8.00, 3.00, 10, 3),
(7, 'Salchipapa', 'VENTA', 7.00, 2.50, 15, 5);
GO

-- COMBOS (PRODUCTOS DE VENTA)
INSERT INTO Inventario.Productos (id_categoria, nombre, tipo, precio_venta, costo_unitario, stock_actual, stock_minimo) VALUES
(8, 'Combo Pollo + Gaseosa', 'VENTA', 15.00, 7.00, 10, 3),
(8, 'Combo Lomo + Gaseosa', 'VENTA', 18.00, 9.00, 8, 3),
(8, 'Combo Familiar (2 pollos + 4 bebidas)', 'VENTA', 55.00, 28.00, 5, 2);
GO

-- POSTRES (PRODUCTOS DE VENTA)
INSERT INTO Inventario.Productos (id_categoria, nombre, tipo, precio_venta, costo_unitario, stock_actual, stock_minimo) VALUES
(9, 'Arroz con Leche', 'VENTA', 5.00, 1.50, 12, 4),
(9, 'Mazamorra Morada', 'VENTA', 5.00, 1.50, 10, 3),
(9, 'Picarones (4 und)', 'VENTA', 6.00, 2.00, 8, 3),
(9, 'Flan Casero', 'VENTA', 5.00, 2.00, 8, 3),
(9, 'Helado de Lucuma', 'VENTA', 4.00, 1.50, 15, 5);
GO

PRINT '';
PRINT '==================================================';
PRINT 'BD_TESIS_SJL_2026';
PRINT '==================================================';
PRINT 'Sistema de Gestion de Ventas, Inventario y Pedidos';
PRINT 'San Juan de Lurigancho - 2026';
PRINT '==================================================';
PRINT 'Tablas creadas:';
PRINT '- Ventas: Clientes, Ventas, DetalleVenta';
PRINT '- Inventario: Categorias, Productos, Proveedores, Compras, DetalleCompra';
PRINT '- Pedidos: Pedidos, DetallePedido';
PRINT '- Seguridad: Roles, Usuarios';
PRINT '- Finanzas: MetodosPago, Pagos';
PRINT '==================================================';
PRINT 'Total productos registrados: INSUMOS + VENTA';
PRINT '==================================================';
GO

SELECT COUNT(*) AS TotalProductos FROM Inventario.Productos;
SELECT nombre, tipo, precio_venta FROM Inventario.Productos WHERE activo = 1 ORDER BY id_categoria, nombre;
GO
