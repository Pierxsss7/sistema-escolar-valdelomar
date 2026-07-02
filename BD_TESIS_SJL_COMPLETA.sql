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
CREATE SCHEMA Produccion;
GO
CREATE SCHEMA Auditoria;
GO

-- ============================================= SEGURIDAD
CREATE TABLE Seguridad.Roles (
    id_rol INT IDENTITY PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL
);
GO

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

CREATE UNIQUE INDEX uq_usuario ON Seguridad.Usuarios(usuario);
GO

-- ============================================= CLIENTES Y PROVEEDORES
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

CREATE UNIQUE INDEX uq_cliente_dni ON Ventas.Clientes(dni);
GO

CREATE TABLE Inventario.Proveedores (
    id_proveedor INT IDENTITY PRIMARY KEY,
    ruc VARCHAR(11) NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    telefono VARCHAR(20),
    direccion VARCHAR(200),
    activo BIT NOT NULL DEFAULT 1
);
GO

CREATE UNIQUE INDEX uq_proveedor_ruc ON Inventario.Proveedores(ruc);
GO

-- ============================================= PRODUCTOS
CREATE TABLE Inventario.Categorias (
    id_categoria INT IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL
);
GO

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

CREATE INDEX ix_productos_nombre ON Inventario.Productos(nombre);
CREATE INDEX ix_productos_tipo ON Inventario.Productos(tipo);
GO

-- ============================================= RECETAS (para negocio de comida)
CREATE TABLE Produccion.Recetas (
    id_receta INT IDENTITY PRIMARY KEY,
    id_producto INT NOT NULL,
    nombre VARCHAR(120) NOT NULL,
    rendimiento DECIMAL(10,2) NOT NULL DEFAULT 1,
    activo BIT NOT NULL DEFAULT 1,
    FOREIGN KEY (id_producto) REFERENCES Inventario.Productos(id_producto)
);
GO

CREATE TABLE Produccion.DetalleReceta (
    id_detalle INT IDENTITY PRIMARY KEY,
    id_receta INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (id_receta) REFERENCES Produccion.Recetas(id_receta),
    FOREIGN KEY (id_producto) REFERENCES Inventario.Productos(id_producto)
);
GO

-- ============================================= COMPRAS
CREATE TABLE Inventario.Compras (
    id_compra INT IDENTITY PRIMARY KEY,
    id_proveedor INT NOT NULL,
    id_usuario INT NOT NULL,
    total DECIMAL(10,2) NOT NULL,
    fecha DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (id_proveedor) REFERENCES Inventario.Proveedores(id_proveedor),
    FOREIGN KEY (id_usuario) REFERENCES Seguridad.Usuarios(id_usuario)
);
GO

CREATE TABLE Inventario.DetalleCompra (
    id_detalle INT IDENTITY PRIMARY KEY,
    id_compra INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad DECIMAL(10,2) NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (id_compra) REFERENCES Inventario.Compras(id_compra),
    FOREIGN KEY (id_producto) REFERENCES Inventario.Productos(id_producto)
);
GO

-- ============================================= VENTAS
CREATE TABLE Ventas.Ventas (
    id_venta INT IDENTITY PRIMARY KEY,
    id_cliente INT,
    id_usuario INT NOT NULL,
    serie VARCHAR(4) NOT NULL DEFAULT 'B001',
    numero INT NOT NULL DEFAULT 1,
    subtotal DECIMAL(10,2) NOT NULL DEFAULT 0,
    descuento DECIMAL(10,2) NOT NULL DEFAULT 0,
    total DECIMAL(10,2) NOT NULL,
    fecha DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (id_cliente) REFERENCES Ventas.Clientes(id_cliente),
    FOREIGN KEY (id_usuario) REFERENCES Seguridad.Usuarios(id_usuario)
);
GO

CREATE INDEX ix_ventas_fecha ON Ventas.Ventas(fecha DESC);
GO

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

-- ============================================= PEDIDOS
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
    FOREIGN KEY (id_cliente) REFERENCES Ventas.Clientes(id_cliente),
    FOREIGN KEY (id_usuario) REFERENCES Seguridad.Usuarios(id_usuario)
);
GO

CREATE INDEX ix_pedidos_estado ON Pedidos.Pedidos(estado, fecha);
GO

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

-- ============================================= PAGOS
CREATE TABLE Finanzas.MetodosPago (
    id_metodo INT IDENTITY PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL
);
GO

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

-- ============================================= AUDITORIA
CREATE TABLE Auditoria.Log (
    id_log BIGINT IDENTITY PRIMARY KEY,
    id_usuario INT,
    tabla VARCHAR(100) NOT NULL,
    operacion VARCHAR(20) NOT NULL,
    detalle VARCHAR(MAX),
    fecha DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

CREATE INDEX ix_log_fecha ON Auditoria.Log(fecha DESC);
GO

-- ============================================= VISTAS DE REPORTES
GO
CREATE VIEW Ventas.vwVentasDelDia AS
SELECT
    v.id_venta,
    v.serie + '-' + RIGHT('000000' + CAST(v.numero AS VARCHAR), 6) AS comprobante,
    v.fecha,
    u.nombre AS usuario,
    ISNULL(c.nombre, 'GENERAL') AS cliente,
    v.subtotal,
    v.descuento,
    v.total
FROM Ventas.Ventas v
JOIN Seguridad.Usuarios u ON u.id_usuario = v.id_usuario
LEFT JOIN Ventas.Clientes c ON c.id_cliente = v.id_cliente
WHERE CAST(v.fecha AS DATE) = CAST(SYSDATETIME() AS DATE);
GO

CREATE VIEW Inventario.vwProductosBajoStock AS
SELECT
    p.id_producto,
    p.nombre,
    cat.nombre AS categoria,
    p.stock_actual,
    p.stock_minimo,
    CASE
        WHEN p.stock_actual <= 0 THEN 'SIN STOCK'
        WHEN p.stock_actual <= p.stock_minimo THEN 'BAJO'
        ELSE 'NORMAL'
    END AS nivel
FROM Inventario.Productos p
JOIN Inventario.Categorias cat ON cat.id_categoria = p.id_categoria
WHERE p.activo = 1 AND p.stock_actual <= p.stock_minimo;
GO

CREATE VIEW Ventas.vwProductosMasVendidos AS
SELECT TOP 20
    p.id_producto,
    p.nombre,
    cat.nombre AS categoria,
    SUM(dv.cantidad) AS cantidad_vendida,
    SUM(dv.subtotal) AS total_vendido
FROM Ventas.DetalleVenta dv
JOIN Ventas.Ventas v ON v.id_venta = dv.id_venta
JOIN Inventario.Productos p ON p.id_producto = dv.id_producto
JOIN Inventario.Categorias cat ON cat.id_categoria = p.id_categoria
GROUP BY p.id_producto, p.nombre, cat.nombre
ORDER BY SUM(dv.cantidad) DESC;
GO

CREATE VIEW Inventario.vwRentabilidad AS
SELECT
    p.nombre,
    cat.nombre AS categoria,
    p.precio_venta,
    p.costo_unitario,
    (p.precio_venta - p.costo_unitario) AS ganancia,
    CASE
        WHEN p.precio_venta > 0 THEN ((p.precio_venta - p.costo_unitario) / p.precio_venta) * 100
        ELSE 0
    END AS margen
FROM Inventario.Productos p
JOIN Inventario.Categorias cat ON cat.id_categoria = p.id_categoria
WHERE p.activo = 1 AND p.tipo = 'VENTA';
GO

-- ============================================= PROCEDIMIENTOS ALMACENADOS
GO
CREATE PROCEDURE Ventas.spRegistrarVenta
    @id_cliente INT,
    @id_usuario INT,
    @id_producto1 INT, @cantidad1 DECIMAL(10,2), @precio1 DECIMAL(10,2),
    @id_producto2 INT = NULL, @cantidad2 DECIMAL(10,2) = 0, @precio2 DECIMAL(10,2) = 0,
    @id_producto3 INT = NULL, @cantidad3 DECIMAL(10,2) = 0, @precio3 DECIMAL(10,2) = 0,
    @id_metodo_pago INT,
    @monto_pago DECIMAL(10,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @id_venta INT;
    DECLARE @subtotal DECIMAL(10,2) = 0;
    DECLARE @total DECIMAL(10,2) = 0;
    DECLARE @serie VARCHAR(4) = 'B001';
    DECLARE @numero INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @numero = ISNULL(MAX(numero), 0) + 1 FROM Ventas.Ventas WHERE serie = @serie;

        INSERT INTO Ventas.Ventas (id_cliente, id_usuario, serie, numero, subtotal, total)
        VALUES (@id_cliente, @id_usuario, @serie, @numero, 0, 0);

        SET @id_venta = SCOPE_IDENTITY();

        IF @id_producto1 IS NOT NULL
        BEGIN
            INSERT INTO Ventas.DetalleVenta (id_venta, id_producto, cantidad, precio_unitario, subtotal)
            VALUES (@id_venta, @id_producto1, @cantidad1, @precio1, @cantidad1 * @precio1);
            SET @subtotal = @subtotal + (@cantidad1 * @precio1);
        END;

        IF @id_producto2 IS NOT NULL
        BEGIN
            INSERT INTO Ventas.DetalleVenta (id_venta, id_producto, cantidad, precio_unitario, subtotal)
            VALUES (@id_venta, @id_producto2, @cantidad2, @precio2, @cantidad2 * @precio2);
            SET @subtotal = @subtotal + (@cantidad2 * @precio2);
        END;

        IF @id_producto3 IS NOT NULL
        BEGIN
            INSERT INTO Ventas.DetalleVenta (id_venta, id_producto, cantidad, precio_unitario, subtotal)
            VALUES (@id_venta, @id_producto3, @cantidad3, @precio3, @cantidad3 * @precio3);
            SET @subtotal = @subtotal + (@cantidad3 * @precio3);
        END;

        SET @total = @subtotal;

        UPDATE Ventas.Ventas SET subtotal = @subtotal, total = @total WHERE id_venta = @id_venta;

        INSERT INTO Finanzas.Pagos (id_venta, id_metodo, monto)
        VALUES (@id_venta, @id_metodo_pago, ISNULL(@monto_pago, @total));

        UPDATE Inv SET stock_actual = Inv.stock_actual - dv.cantidad
        FROM Inventario.Productos Inv
        INNER JOIN Ventas.DetalleVenta dv ON dv.id_producto = Inv.id_producto AND dv.id_venta = @id_venta
        WHERE Inv.tipo IN ('VENTA', 'PRODUCIDO');

        INSERT INTO Auditoria.Log (id_usuario, tabla, operacion, detalle)
        VALUES (@id_usuario, 'VENTAS', 'INSERT', 'Venta ' + @serie + '-' + RIGHT('000000' + CAST(@numero AS VARCHAR), 6) + ' S/' + CAST(@total AS VARCHAR));

        COMMIT TRANSACTION;

        SELECT @id_venta AS id_venta, @serie + '-' + RIGHT('000000' + CAST(@numero AS VARCHAR), 6) AS comprobante, @total AS total;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT ERROR_MESSAGE() AS error;
    END CATCH;
END;
GO

CREATE PROCEDURE Inventario.spRegistrarCompra
    @id_proveedor INT,
    @id_usuario INT,
    @id_producto1 INT, @cantidad1 DECIMAL(10,2), @precio1 DECIMAL(10,2),
    @id_producto2 INT = NULL, @cantidad2 DECIMAL(10,2) = 0, @precio2 DECIMAL(10,2) = 0,
    @id_producto3 INT = NULL, @cantidad3 DECIMAL(10,2) = 0, @precio3 DECIMAL(10,2) = 0
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @id_compra INT;
    DECLARE @total DECIMAL(10,2) = 0;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO Inventario.Compras (id_proveedor, id_usuario, total)
        VALUES (@id_proveedor, @id_usuario, 0);

        SET @id_compra = SCOPE_IDENTITY();

        IF @id_producto1 IS NOT NULL
        BEGIN
            INSERT INTO Inventario.DetalleCompra (id_compra, id_producto, cantidad, precio_unitario, subtotal)
            VALUES (@id_compra, @id_producto1, @cantidad1, @precio1, @cantidad1 * @precio1);
            SET @total = @total + (@cantidad1 * @precio1);
        END;

        IF @id_producto2 IS NOT NULL
        BEGIN
            INSERT INTO Inventario.DetalleCompra (id_compra, id_producto, cantidad, precio_unitario, subtotal)
            VALUES (@id_compra, @id_producto2, @cantidad2, @precio2, @cantidad2 * @precio2);
            SET @total = @total + (@cantidad2 * @precio2);
        END;

        IF @id_producto3 IS NOT NULL
        BEGIN
            INSERT INTO Inventario.DetalleCompra (id_compra, id_producto, cantidad, precio_unitario, subtotal)
            VALUES (@id_compra, @id_producto3, @cantidad3, @precio3, @cantidad3 * @precio3);
            SET @total = @total + (@cantidad3 * @precio3);
        END;

        UPDATE Inventario.Compras SET total = @total WHERE id_compra = @id_compra;

        UPDATE Inv SET stock_actual = Inv.stock_actual + dc.cantidad,
                       costo_unitario = dc.precio_unitario
        FROM Inventario.Productos Inv
        INNER JOIN Inventario.DetalleCompra dc ON dc.id_producto = Inv.id_producto AND dc.id_compra = @id_compra;

        INSERT INTO Auditoria.Log (id_usuario, tabla, operacion, detalle)
        VALUES (@id_usuario, 'COMPRAS', 'INSERT', 'Compra #' + CAST(@id_compra AS VARCHAR) + ' S/' + CAST(@total AS VARCHAR));

        COMMIT TRANSACTION;

        SELECT @id_compra AS id_compra, @total AS total;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT ERROR_MESSAGE() AS error;
    END CATCH;
END;
GO

CREATE PROCEDURE Finanzas.spCerrarCaja
    @id_caja INT,
    @id_usuario INT,
    @monto_inicial DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @efectivo DECIMAL(10,2) = 0;
    DECLARE @digital DECIMAL(10,2) = 0;
    DECLARE @total DECIMAL(10,2) = 0;

    SELECT @efectivo = ISNULL(SUM(p.monto), 0)
    FROM Finanzas.Pagos p
    JOIN Finanzas.MetodosPago m ON m.id_metodo = p.id_metodo
    WHERE m.nombre = 'EFECTIVO' AND CAST(p.fecha AS DATE) = CAST(SYSDATETIME() AS DATE);

    SELECT @digital = ISNULL(SUM(p.monto), 0)
    FROM Finanzas.Pagos p
    JOIN Finanzas.MetodosPago m ON m.id_metodo = p.id_metodo
    WHERE m.nombre IN ('YAPE', 'PLIN', 'TARJETA', 'TRANSFERENCIA')
    AND CAST(p.fecha AS DATE) = CAST(SYSDATETIME() AS DATE);

    SET @total = @efectivo + @digital;

    SELECT
        @monto_inicial AS monto_inicial,
        @efectivo AS total_efectivo,
        @digital AS total_digital,
        @total AS total_general;
END;
GO

-- ============================================= DATOS INICIALES
INSERT INTO Seguridad.Roles (nombre) VALUES
('ADMINISTRADOR'), ('CAJERO'), ('COCINA'), ('REPARTIDOR');
GO

INSERT INTO Seguridad.Usuarios (id_rol, nombre, usuario, clave) VALUES
(1, 'Administrador', 'admin', 'admin123'),
(2, 'Cajero Principal', 'cajero', 'cajero123');
GO

INSERT INTO Finanzas.MetodosPago (nombre) VALUES
('EFECTIVO'), ('YAPE'), ('PLIN'), ('TARJETA'), ('TRANSFERENCIA');
GO

INSERT INTO Ventas.Clientes (dni, nombre, telefono) VALUES
('00000000', 'Cliente General', ''),
('12345678', 'Juan Perez Garcia', '987654321'),
('87654321', 'Maria Lopez Rojas', '987654322');
GO

INSERT INTO Inventario.Proveedores (ruc, nombre, telefono, direccion) VALUES
('20123456789', 'Mercado Mayorista SJL', '987000001', 'Av. Central SJL'),
('20123456788', 'Distribuidora San Juan', '987000002', 'Jr. Las Flores 123'),
('20123456787', 'Avicola El Pollon', '987000003', 'Av. Peru 456'),
('20123456786', 'Carnes del Norte', '987000004', 'Jr. Los Olivos 789');
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

-- INSUMOS: VERDURAS
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
(1, 'Lechuga', 'INSUMO', 0, 1.50, 8, 3),
(1, 'Culantro', 'INSUMO', 0, 1.00, 10, 4),
(1, 'Aji Amarillo', 'INSUMO', 0, 4.00, 5, 2),
(1, 'Zapallo', 'INSUMO', 0, 2.00, 8, 2),
(1, 'Choclo', 'INSUMO', 0, 2.00, 10, 3),
(1, 'Palta', 'INSUMO', 0, 5.00, 6, 2),
(1, 'Limon', 'INSUMO', 0, 2.00, 15, 5);
GO

-- INSUMOS: CARNES
INSERT INTO Inventario.Productos (id_categoria, nombre, tipo, precio_venta, costo_unitario, stock_actual, stock_minimo) VALUES
(2, 'Pollo Entero', 'INSUMO', 0, 8.00, 10, 3),
(2, 'Pollo Pechuga', 'INSUMO', 0, 12.00, 8, 3),
(2, 'Pollo Pierna', 'INSUMO', 0, 9.00, 8, 3),
(2, 'Carne Molida de Res', 'INSUMO', 0, 15.00, 5, 2),
(2, 'Lomo de Res', 'INSUMO', 0, 22.00, 4, 1),
(2, 'Carne de Cerdo', 'INSUMO', 0, 14.00, 4, 1),
(2, 'Pescado Merluza', 'INSUMO', 0, 10.00, 5, 2),
(2, 'Huevos (und)', 'INSUMO', 0, 1.50, 30, 10);
GO

-- INSUMOS: ABARROTES
INSERT INTO Inventario.Productos (id_categoria, nombre, tipo, precio_venta, costo_unitario, stock_actual, stock_minimo) VALUES
(3, 'Arroz', 'INSUMO', 0, 3.50, 25, 10),
(3, 'Fideo Tallarin', 'INSUMO', 0, 2.50, 15, 5),
(3, 'Aceite Vegetal', 'INSUMO', 0, 7.00, 10, 3),
(3, 'Sal', 'INSUMO', 0, 1.00, 10, 3),
(3, 'Azucar', 'INSUMO', 0, 3.00, 10, 3),
(3, 'Sillao', 'INSUMO', 0, 3.50, 5, 2),
(3, 'Comino', 'INSUMO', 0, 1.50, 4, 1),
(3, 'Pimienta', 'INSUMO', 0, 1.50, 4, 1),
(3, 'Caldo de Pollo', 'INSUMO', 0, 2.00, 8, 3),
(3, 'Leche Evaporada', 'INSUMO', 0, 3.50, 10, 3),
(3, 'Mayonesa', 'INSUMO', 0, 5.00, 5, 2),
(3, 'Harina', 'INSUMO', 0, 2.50, 8, 3);
GO

-- VENTA: BEBIDAS
INSERT INTO Inventario.Productos (id_categoria, nombre, tipo, precio_venta, costo_unitario, stock_actual, stock_minimo) VALUES
(5, 'Coca Cola 500ml', 'VENTA', 3.50, 2.00, 30, 10),
(5, 'Inca Kola 500ml', 'VENTA', 3.50, 2.00, 30, 10),
(5, 'Agua Mineral 500ml', 'VENTA', 2.00, 1.00, 25, 10),
(5, 'Jugo de Naranja', 'VENTA', 5.00, 2.00, 10, 3),
(5, 'Chicha Morada', 'VENTA', 4.00, 1.50, 10, 4),
(5, 'Cafe Americano', 'VENTA', 4.00, 1.50, 15, 5);
GO

-- VENTA: PLATOS DE FONDO
INSERT INTO Inventario.Productos (id_categoria, nombre, tipo, precio_venta, costo_unitario, stock_actual, stock_minimo) VALUES
(6, 'Pollo a la Brasa 1/4', 'VENTA', 12.00, 6.00, 20, 5),
(6, 'Pollo a la Brasa 1/2', 'VENTA', 22.00, 11.00, 15, 4),
(6, 'Ceviche Mixto', 'VENTA', 18.00, 8.00, 10, 3),
(6, 'Lomo Saltado', 'VENTA', 16.00, 8.00, 15, 4),
(6, 'Aji de Gallina', 'VENTA', 14.00, 6.00, 12, 4),
(6, 'Tallarin Saltado', 'VENTA', 15.00, 7.00, 10, 3),
(6, 'Arroz con Pollo', 'VENTA', 14.00, 6.00, 12, 4),
(6, 'Seco de Res', 'VENTA', 16.00, 8.00, 10, 3),
(6, 'Milanesa de Pollo', 'VENTA', 14.00, 6.50, 10, 3),
(6, 'Pescado Frito', 'VENTA', 15.00, 7.00, 10, 3);
GO

-- VENTA: ENTRADAS
INSERT INTO Inventario.Productos (id_categoria, nombre, tipo, precio_venta, costo_unitario, stock_actual, stock_minimo) VALUES
(7, 'Caldo de Gallina', 'VENTA', 10.00, 5.00, 10, 3),
(7, 'Papa Rellena', 'VENTA', 5.00, 2.00, 15, 5),
(7, 'Causa Rellena', 'VENTA', 6.00, 2.50, 10, 3),
(7, 'Tequeños (6 und)', 'VENTA', 8.00, 3.00, 10, 3);
GO

-- VENTA: COMBOS
INSERT INTO Inventario.Productos (id_categoria, nombre, tipo, precio_venta, costo_unitario, stock_actual, stock_minimo) VALUES
(8, 'Combo Pollo + Gaseosa', 'VENTA', 15.00, 7.00, 10, 3),
(8, 'Combo Lomo + Gaseosa', 'VENTA', 18.00, 9.00, 8, 3),
(8, 'Combo Familiar (2 pollos + 4 bebidas)', 'VENTA', 55.00, 28.00, 5, 2);
GO

-- VENTA: POSTRES
INSERT INTO Inventario.Productos (id_categoria, nombre, tipo, precio_venta, costo_unitario, stock_actual, stock_minimo) VALUES
(9, 'Arroz con Leche', 'VENTA', 5.00, 1.50, 12, 4),
(9, 'Mazamorra Morada', 'VENTA', 5.00, 1.50, 10, 3),
(9, 'Picarones (4 und)', 'VENTA', 6.00, 2.00, 8, 3),
(9, 'Helado de Lucuma', 'VENTA', 4.00, 1.50, 15, 5);
GO

PRINT '';
PRINT '==================================================';
PRINT ' BD_TESIS_SJL_2026';
PRINT '==================================================';
PRINT ' Sistema de Gestion de Ventas, Inventario y Pedidos';
PRINT ' San Juan de Lurigancho - 2026';
PRINT '==================================================';
PRINT ' Esquemas: 7';
PRINT ' Tablas:   16';
PRINT ' Vistas:   4';
PRINT ' Procedimientos: 3';
PRINT '==================================================';
GO
