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
CREATE SCHEMA Configuracion;
GO

-- ============================================= CONFIGURACION DEL NEGOCIO
CREATE TABLE Configuracion.Negocio (
    id_negocio INT PRIMARY KEY DEFAULT 1,
    nombre VARCHAR(200) NOT NULL,
    ruc VARCHAR(11) NOT NULL,
    direccion VARCHAR(200),
    telefono VARCHAR(20),
    email VARCHAR(100),
    logo_url VARCHAR(500),
    horario_atencion VARCHAR(200),
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

CREATE TABLE Configuracion.Turnos (
    id_turno INT IDENTITY PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL
);
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
    id_turno INT,
    nombre VARCHAR(100) NOT NULL,
    usuario VARCHAR(50) NOT NULL,
    clave VARCHAR(255) NOT NULL,
    telefono VARCHAR(20),
    activo BIT NOT NULL DEFAULT 1,
    ultimo_acceso DATETIME2,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (id_rol) REFERENCES Seguridad.Roles(id_rol),
    FOREIGN KEY (id_turno) REFERENCES Configuracion.Turnos(id_turno)
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
    puntos INT NOT NULL DEFAULT 0,
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
    contacto VARCHAR(100),
    telefono VARCHAR(20),
    direccion VARCHAR(200),
    dias_entrega VARCHAR(100),
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
    codigo_barras VARCHAR(50),
    precio_venta DECIMAL(10,2) NOT NULL DEFAULT 0,
    costo_unitario DECIMAL(10,2) NOT NULL DEFAULT 0,
    stock_actual DECIMAL(10,2) NOT NULL DEFAULT 0,
    stock_minimo DECIMAL(10,2) NOT NULL DEFAULT 0,
    activo BIT NOT NULL DEFAULT 1,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (id_categoria) REFERENCES Inventario.Categorias(id_categoria)
);
GO

CREATE INDEX ix_productos_nombre ON Inventario.Productos(nombre);
CREATE INDEX ix_productos_tipo ON Inventario.Productos(tipo);
GO

CREATE TABLE Inventario.HistorialPrecios (
    id_historial INT IDENTITY PRIMARY KEY,
    id_producto INT NOT NULL,
    precio_anterior DECIMAL(10,2) NOT NULL,
    precio_nuevo DECIMAL(10,2) NOT NULL,
    costo_anterior DECIMAL(10,2) NOT NULL,
    costo_nuevo DECIMAL(10,2) NOT NULL,
    id_usuario INT NOT NULL,
    fecha DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (id_producto) REFERENCES Inventario.Productos(id_producto),
    FOREIGN KEY (id_usuario) REFERENCES Seguridad.Usuarios(id_usuario)
);
GO

-- ============================================= RECETAS
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
    serie VARCHAR(10),
    numero VARCHAR(20),
    subtotal DECIMAL(10,2) NOT NULL DEFAULT 0,
    igv DECIMAL(10,2) NOT NULL DEFAULT 0,
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

-- ============================================= PROMOCIONES
CREATE TABLE Ventas.Promociones (
    id_promocion INT IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    tipo VARCHAR(30) NOT NULL,
    valor DECIMAL(10,2) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    activo BIT NOT NULL DEFAULT 1
);
GO

CREATE TABLE Ventas.PromocionProducto (
    id_promocion INT NOT NULL,
    id_producto INT NOT NULL,
    PRIMARY KEY (id_promocion, id_producto),
    FOREIGN KEY (id_promocion) REFERENCES Ventas.Promociones(id_promocion),
    FOREIGN KEY (id_producto) REFERENCES Inventario.Productos(id_producto)
);
GO

-- ============================================= VENTAS
CREATE TABLE Ventas.Mesas (
    id_mesa INT IDENTITY PRIMARY KEY,
    numero INT NOT NULL,
    capacidad INT NOT NULL DEFAULT 4,
    ubicacion VARCHAR(50),
    estado VARCHAR(20) NOT NULL DEFAULT 'LIBRE'
);
GO

CREATE TABLE Ventas.Ventas (
    id_venta INT IDENTITY PRIMARY KEY,
    id_cliente INT,
    id_usuario INT NOT NULL,
    id_mesa INT,
    id_promocion INT,
    serie VARCHAR(4) NOT NULL DEFAULT 'B001',
    numero INT NOT NULL DEFAULT 1,
    subtotal DECIMAL(10,2) NOT NULL DEFAULT 0,
    descuento DECIMAL(10,2) NOT NULL DEFAULT 0,
    total DECIMAL(10,2) NOT NULL,
    puntos_generados INT NOT NULL DEFAULT 0,
    estado VARCHAR(20) NOT NULL DEFAULT 'PAGADO',
    fecha DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (id_cliente) REFERENCES Ventas.Clientes(id_cliente),
    FOREIGN KEY (id_usuario) REFERENCES Seguridad.Usuarios(id_usuario),
    FOREIGN KEY (id_mesa) REFERENCES Ventas.Mesas(id_mesa),
    FOREIGN KEY (id_promocion) REFERENCES Ventas.Promociones(id_promocion)
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
    descuento_item DECIMAL(10,2) NOT NULL DEFAULT 0,
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
    subtotal DECIMAL(10,2) NOT NULL DEFAULT 0,
    costo_envio DECIMAL(10,2) NOT NULL DEFAULT 0,
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
    nombre VARCHAR(50) NOT NULL,
    codigo VARCHAR(10) NOT NULL
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

-- ============================================= GASTOS
CREATE TABLE Finanzas.Gastos (
    id_gasto INT IDENTITY PRIMARY KEY,
    id_usuario INT NOT NULL,
    categoria VARCHAR(50) NOT NULL,
    descripcion VARCHAR(200) NOT NULL,
    monto DECIMAL(10,2) NOT NULL,
    fecha DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (id_usuario) REFERENCES Seguridad.Usuarios(id_usuario)
);
GO

CREATE INDEX ix_gastos_fecha ON Finanzas.Gastos(fecha DESC);
GO

-- ============================================= AUDITORIA
CREATE TABLE Auditoria.Log (
    id_log BIGINT IDENTITY PRIMARY KEY,
    id_usuario INT,
    tabla VARCHAR(100) NOT NULL,
    operacion VARCHAR(20) NOT NULL,
    detalle VARCHAR(MAX),
    ip_address VARCHAR(45),
    fecha DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

CREATE INDEX ix_log_fecha ON Auditoria.Log(fecha DESC);
GO

-- ============================================= VISTAS DASHBOARD
GO
CREATE VIEW Ventas.vwDashboardVentasDia AS
SELECT
    COUNT(*) AS cantidad_ventas,
    ISNULL(SUM(total), 0) AS total_ventas,
    ISNULL(AVG(total), 0) AS ticket_promedio,
    ISNULL(SUM(descuento), 0) AS total_descuentos
FROM Ventas.Ventas
WHERE CAST(fecha AS DATE) = CAST(SYSDATETIME() AS DATE);
GO

CREATE VIEW Ventas.vwVentasDelDia AS
SELECT
    v.id_venta,
    v.serie + '-' + RIGHT('000000' + CAST(v.numero AS VARCHAR), 6) AS comprobante,
    v.fecha,
    u.nombre AS usuario,
    ISNULL(c.nombre, 'GENERAL') AS cliente,
    m.numero AS mesa,
    v.subtotal,
    v.descuento,
    v.total
FROM Ventas.Ventas v
JOIN Seguridad.Usuarios u ON u.id_usuario = v.id_usuario
LEFT JOIN Ventas.Clientes c ON c.id_cliente = v.id_cliente
LEFT JOIN Ventas.Mesas m ON m.id_mesa = v.id_mesa
WHERE CAST(v.fecha AS DATE) = CAST(SYSDATETIME() AS DATE);
GO

CREATE VIEW Inventario.vwProductosBajoStock AS
SELECT
    p.id_producto, p.nombre, cat.nombre AS categoria,
    p.stock_actual, p.stock_minimo,
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
    p.id_producto, p.nombre, cat.nombre AS categoria,
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
    p.nombre, cat.nombre AS categoria,
    p.precio_venta, p.costo_unitario,
    (p.precio_venta - p.costo_unitario) AS ganancia,
    CASE WHEN p.precio_venta > 0
        THEN ((p.precio_venta - p.costo_unitario) / p.precio_venta) * 100
        ELSE 0 END AS margen
FROM Inventario.Productos p
JOIN Inventario.Categorias cat ON cat.id_categoria = p.id_categoria
WHERE p.activo = 1 AND p.tipo = 'VENTA';
GO

CREATE VIEW Ventas.vwClientesFrecuentes AS
SELECT TOP 10
    c.id_cliente, c.nombre, c.telefono,
    COUNT(v.id_venta) AS compras,
    ISNULL(SUM(v.total), 0) AS total_gastado,
    c.puntos
FROM Ventas.Clientes c
LEFT JOIN Ventas.Ventas v ON v.id_cliente = c.id_cliente
WHERE c.activo = 1 AND c.dni != '00000000'
GROUP BY c.id_cliente, c.nombre, c.telefono, c.puntos
ORDER BY COUNT(v.id_venta) DESC;
GO

CREATE VIEW Finanzas.vwReporteDiario AS
SELECT
    CAST(SYSDATETIME() AS DATE) AS fecha,
    (SELECT ISNULL(SUM(total), 0) FROM Ventas.Ventas WHERE CAST(fecha AS DATE) = CAST(SYSDATETIME() AS DATE)) AS total_ventas,
    (SELECT ISNULL(SUM(monto), 0) FROM Finanzas.Gastos WHERE CAST(fecha AS DATE) = CAST(SYSDATETIME() AS DATE)) AS total_gastos,
    (SELECT ISNULL(SUM(d.cantidad), 0) FROM Ventas.DetalleVenta d JOIN Ventas.Ventas v ON v.id_venta = d.id_venta WHERE CAST(v.fecha AS DATE) = CAST(SYSDATETIME() AS DATE)) AS productos_vendidos,
    (SELECT COUNT(*) FROM Pedidos.Pedidos WHERE CAST(fecha AS DATE) = CAST(SYSDATETIME() AS DATE)) AS pedidos_realizados;
GO

-- ============================================= PROCEDIMIENTOS
GO
CREATE PROCEDURE Ventas.spRegistrarVenta
    @id_cliente INT,
    @id_usuario INT,
    @id_mesa INT = NULL,
    @id_promocion INT = NULL,
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

        INSERT INTO Ventas.Ventas (id_cliente, id_usuario, id_mesa, id_promocion, serie, numero, subtotal, total)
        VALUES (@id_cliente, @id_usuario, @id_mesa, @id_promocion, @serie, @numero, 0, 0);

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
        INNER JOIN Ventas.DetalleVenta dv ON dv.id_producto = Inv.id_producto AND dv.id_venta = @id_venta;

        IF @id_mesa IS NOT NULL
            UPDATE Ventas.Mesas SET estado = 'LIBRE' WHERE id_mesa = @id_mesa;

        INSERT INTO Auditoria.Log (id_usuario, tabla, operacion, detalle)
        VALUES (@id_usuario, 'VENTAS', 'INSERT', 'Venta ' + @serie + '-' + RIGHT('000000' + CAST(@numero AS VARCHAR), 6));

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
    @id_proveedor INT, @id_usuario INT,
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
        VALUES (@id_usuario, 'COMPRAS', 'INSERT', 'Compra #' + CAST(@id_compra AS VARCHAR));

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
    @monto_inicial DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @efectivo DECIMAL(10,2), @yape DECIMAL(10,2), @plin DECIMAL(10,2);
    DECLARE @tarjeta DECIMAL(10,2), @digital DECIMAL(10,2), @total DECIMAL(10,2);
    DECLARE @gastos DECIMAL(10,2);

    SELECT @efectivo = ISNULL(SUM(p.monto), 0)
    FROM Finanzas.Pagos p JOIN Finanzas.MetodosPago m ON m.id_metodo = p.id_metodo
    WHERE m.codigo = 'EFE' AND CAST(p.fecha AS DATE) = CAST(SYSDATETIME() AS DATE);

    SELECT @yape = ISNULL(SUM(p.monto), 0)
    FROM Finanzas.Pagos p JOIN Finanzas.MetodosPago m ON m.id_metodo = p.id_metodo
    WHERE m.codigo = 'YAP' AND CAST(p.fecha AS DATE) = CAST(SYSDATETIME() AS DATE);

    SELECT @plin = ISNULL(SUM(p.monto), 0)
    FROM Finanzas.Pagos p JOIN Finanzas.MetodosPago m ON m.id_metodo = p.id_metodo
    WHERE m.codigo = 'PLN' AND CAST(p.fecha AS DATE) = CAST(SYSDATETIME() AS DATE);

    SELECT @tarjeta = ISNULL(SUM(p.monto), 0)
    FROM Finanzas.Pagos p JOIN Finanzas.MetodosPago m ON m.id_metodo = p.id_metodo
    WHERE m.codigo = 'TAR' AND CAST(p.fecha AS DATE) = CAST(SYSDATETIME() AS DATE);

    SET @digital = @yape + @plin + @tarjeta;
    SET @total = @efectivo + @digital;

    SELECT @gastos = ISNULL(SUM(monto), 0) FROM Finanzas.Gastos WHERE CAST(fecha AS DATE) = CAST(SYSDATETIME() AS DATE);

    SELECT
        @monto_inicial AS monto_inicial,
        @efectivo AS efectivo, @yape AS yape, @plin AS plin, @tarjeta AS tarjeta,
        @digital AS total_digital, @total AS ingreso_total,
        @gastos AS total_gastos, (@total - @gastos) AS ganancia_neta;
END;
GO

CREATE PROCEDURE Finanzas.spRegistrarGasto
    @id_usuario INT, @categoria VARCHAR(50), @descripcion VARCHAR(200), @monto DECIMAL(10,2)
AS
BEGIN
    INSERT INTO Finanzas.Gastos (id_usuario, categoria, descripcion, monto)
    VALUES (@id_usuario, @categoria, @descripcion, @monto);

    INSERT INTO Auditoria.Log (id_usuario, tabla, operacion, detalle)
    VALUES (@id_usuario, 'GASTOS', 'INSERT', @categoria + ': S/' + CAST(@monto AS VARCHAR));

    SELECT SCOPE_IDENTITY() AS id_gasto;
END;
GO

CREATE PROCEDURE Ventas.spCanjearPuntos
    @id_cliente INT, @id_usuario INT, @puntos_uso INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @puntos_actuales INT;

    SELECT @puntos_actuales = puntos FROM Ventas.Clientes WHERE id_cliente = @id_cliente;

    IF @puntos_actuales >= @puntos_uso
    BEGIN
        UPDATE Ventas.Clientes SET puntos = puntos - @puntos_uso WHERE id_cliente = @id_cliente;

        INSERT INTO Auditoria.Log (id_usuario, tabla, operacion, detalle)
        VALUES (@id_usuario, 'CLIENTES', 'PUNTOS', 'Cliente ' + CAST(@id_cliente AS VARCHAR) + ' canjeo ' + CAST(@puntos_uso AS VARCHAR) + ' puntos');

        SELECT 1 AS resultado, (@puntos_actuales - @puntos_uso) AS puntos_restantes;
    END
    ELSE
    BEGIN
        SELECT 0 AS resultado, @puntos_actuales AS puntos_actuales;
    END;
END;
GO

-- ============================================= DATOS INICIALES
INSERT INTO Configuracion.Negocio (nombre, ruc, direccion, telefono, horario_atencion) VALUES
('Mi Negocio SJL', '20000000000', 'Av. Central San Juan de Lurigancho', '987654321', 'Lun-Sab 8:00am - 10:00pm');
GO

INSERT INTO Configuracion.Turnos (nombre, hora_inicio, hora_fin) VALUES
('MANANA', '08:00', '14:00'),
('TARDE', '14:00', '18:00'),
('NOCHE', '18:00', '22:00');
GO

INSERT INTO Seguridad.Roles (nombre) VALUES
('ADMINISTRADOR'), ('CAJERO'), ('COCINA'), ('REPARTIDOR');
GO

INSERT INTO Seguridad.Usuarios (id_rol, id_turno, nombre, usuario, clave) VALUES
(1, 1, 'Administrador', 'admin', 'admin123'),
(2, 1, 'Cajero Manana', 'cajero1', 'cajero123'),
(2, 2, 'Cajero Tarde', 'cajero2', 'cajero123');
GO

INSERT INTO Finanzas.MetodosPago (nombre, codigo) VALUES
('EFECTIVO', 'EFE'), ('YAPE', 'YAP'), ('PLIN', 'PLN'),
('TARJETA', 'TAR'), ('TRANSFERENCIA', 'TRA');
GO

INSERT INTO Ventas.Clientes (dni, nombre, telefono, puntos) VALUES
('00000000', 'Cliente General', '', 0),
('12345678', 'Juan Perez Garcia', '987654321', 50),
('87654321', 'Maria Lopez Rojas', '987654322', 30),
('45678912', 'Carlos Torres', '987654323', 10);
GO

INSERT INTO Inventario.Proveedores (ruc, nombre, contacto, telefono, direccion, dias_entrega) VALUES
('20123456789', 'Mercado Mayorista SJL', 'Sr. Rodriguez', '987000001', 'Av. Central SJL', 'Lunes a Sabado'),
('20123456788', 'Distribuidora San Juan', 'Sra. Gutierrez', '987000002', 'Jr. Las Flores 123', 'Martes y Jueves'),
('20123456787', 'Avicola El Pollon', 'Sr. Huaman', '987000003', 'Av. Peru 456', 'Diario'),
('20123456786', 'Carnes del Norte', 'Sr. Quispe', '987000004', 'Jr. Los Olivos 789', 'Lunes, Miercoles, Viernes');
GO

INSERT INTO Ventas.Mesas (numero, capacidad, ubicacion, estado) VALUES
(1,4,'Interior','LIBRE'),(2,4,'Interior','LIBRE'),(3,4,'Interior','LIBRE'),
(4,2,'Interior','LIBRE'),(5,4,'Ventana','LIBRE'),(6,4,'Ventana','LIBRE'),
(7,6,'Terraza','LIBRE'),(8,2,'Terraza','LIBRE');
GO

INSERT INTO Inventario.Categorias (nombre) VALUES
('Verduras y Hortalizas'),('Carnes y Aves'),('Abarrotes y Condimentos'),
('Lacteos y Huevos'),('Bebidas'),('Platos de Fondo'),
('Entradas y Sopas'),('Combos'),('Postres');
GO

INSERT INTO Inventario.Productos (id_categoria, nombre, tipo, precio_venta, costo_unitario, stock_actual, stock_minimo) VALUES
(1,'Papa Amarilla','INSUMO',0,2.50,10,3),(1,'Papa Blanca','INSUMO',0,2.00,15,5),
(1,'Zanahoria','INSUMO',0,2.00,10,3),(1,'Cebolla Roja','INSUMO',0,2.50,12,4),
(1,'Tomate','INSUMO',0,3.00,10,3),(1,'Ajo','INSUMO',0,5.00,5,2),
(1,'Lechuga','INSUMO',0,1.50,8,3),(1,'Culantro','INSUMO',0,1.00,10,4),
(1,'Limon','INSUMO',0,2.00,15,5),(1,'Palta','INSUMO',0,5.00,6,2),
(2,'Pollo Entero','INSUMO',0,8.00,10,3),(2,'Pollo Pechuga','INSUMO',0,12.00,8,3),
(2,'Carne Molida','INSUMO',0,15.00,5,2),(2,'Lomo de Res','INSUMO',0,22.00,4,1),
(2,'Huevos (und)','INSUMO',0,1.50,30,10),(2,'Pescado Merluza','INSUMO',0,10.00,5,2),
(3,'Arroz','INSUMO',0,3.50,25,10),(3,'Fideo Tallarin','INSUMO',0,2.50,15,5),
(3,'Aceite Vegetal','INSUMO',0,7.00,10,3),(3,'Sal','INSUMO',0,1.00,10,3),
(3,'Sillao','INSUMO',0,3.50,5,2),(3,'Leche Evaporada','INSUMO',0,3.50,10,3),
(3,'Mayonesa','INSUMO',0,5.00,5,2),(3,'Caldo de Pollo','INSUMO',0,2.00,8,3);
GO

INSERT INTO Inventario.Productos (id_categoria, nombre, tipo, precio_venta, costo_unitario, stock_actual, stock_minimo) VALUES
(5,'Coca Cola 500ml','VENTA',3.50,2.00,30,10),
(5,'Inca Kola 500ml','VENTA',3.50,2.00,30,10),
(5,'Agua 500ml','VENTA',2.00,1.00,25,10),
(5,'Jugo Naranja','VENTA',5.00,2.00,10,3),
(5,'Chicha Morada','VENTA',4.00,1.50,10,4),
(6,'Pollo Brasa 1/4','VENTA',12.00,6.00,20,5),
(6,'Pollo Brasa 1/2','VENTA',22.00,11.00,15,4),
(6,'Ceviche Mixto','VENTA',18.00,8.00,10,3),
(6,'Lomo Saltado','VENTA',16.00,8.00,15,4),
(6,'Aji de Gallina','VENTA',14.00,6.00,12,4),
(6,'Arroz con Pollo','VENTA',14.00,6.00,12,4),
(6,'Seco de Res','VENTA',16.00,8.00,10,3),
(7,'Caldo de Gallina','VENTA',10.00,5.00,10,3),
(7,'Papa Rellena','VENTA',5.00,2.00,15,5),
(7,'Causa Rellena','VENTA',6.00,2.50,10,3),
(8,'Combo Pollo + Gaseosa','VENTA',15.00,7.00,10,3),
(8,'Combo Lomo + Gaseosa','VENTA',18.00,9.00,8,3),
(9,'Arroz con Leche','VENTA',5.00,1.50,12,4),
(9,'Mazamorra Morada','VENTA',5.00,1.50,10,3),
(9,'Picarones 4 und','VENTA',6.00,2.00,8,3),
(9,'Helado Lucuma','VENTA',4.00,1.50,15,5);
GO

PRINT '';
PRINT '==================================================';
PRINT ' BD_TESIS_SJL_2026 - VERSION COMPLETA';
PRINT '==================================================';
PRINT ' Sistema de Gestion de Ventas, Inventario y Pedidos';
PRINT ' San Juan de Lurigancho - 2026';
PRINT '==================================================';
PRINT ' TOTAL TABLAS: 26';
PRINT ' TOTAL VISTAS: 7';
PRINT ' TOTAL PROCEDIMIENTOS: 5';
PRINT '==================================================';
PRINT ' MODULOS INCLUIDOS:';
PRINT ' 1. Ventas (Mesas, Promociones, Puntos)';
PRINT ' 2. Inventario (Kardex, Historial Precios)';
PRINT ' 3. Pedidos (Delivery, Recojo)';
PRINT ' 4. Finanzas (Pagos, Gastos, Cierre Caja)';
PRINT ' 5. Produccion (Recetas)';
PRINT ' 6. Seguridad (Roles, Usuarios, Turnos)';
PRINT ' 7. Configuracion (Negocio, Horarios)';
PRINT ' 8. Auditoria (Log de Operaciones)';
PRINT '==================================================';
GO
