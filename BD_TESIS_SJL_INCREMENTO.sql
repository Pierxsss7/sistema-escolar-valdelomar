USE BD_TESIS_SJL_2026;
GO

-- ============================================= 1. KARDEX
CREATE TABLE Inventario.Kardex (
    id_kardex BIGINT IDENTITY PRIMARY KEY,
    id_producto INT NOT NULL,
    tipo_movimiento VARCHAR(20) NOT NULL,
    cantidad DECIMAL(10,2) NOT NULL,
    stock_anterior DECIMAL(10,2) NOT NULL,
    stock_nuevo DECIMAL(10,2) NOT NULL,
    referencia_tabla VARCHAR(50),
    referencia_id INT,
    motivo VARCHAR(200),
    id_usuario INT,
    fecha DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (id_producto) REFERENCES Inventario.Productos(id_producto),
    FOREIGN KEY (id_usuario) REFERENCES Seguridad.Usuarios(id_usuario)
);
GO

CREATE INDEX ix_kardex_producto ON Inventario.Kardex(id_producto, fecha DESC);
GO

CREATE VIEW Inventario.vwKardexCompleto AS
SELECT
    k.id_kardex, p.nombre AS producto, cat.nombre AS categoria,
    k.tipo_movimiento, k.cantidad, k.stock_anterior, k.stock_nuevo,
    (k.stock_nuevo - k.stock_anterior) AS diferencia,
    k.referencia_tabla, k.referencia_id, k.motivo,
    u.nombre AS usuario, k.fecha
FROM Inventario.Kardex k
JOIN Inventario.Productos p ON p.id_producto = k.id_producto
JOIN Inventario.Categorias cat ON cat.id_categoria = p.id_categoria
LEFT JOIN Seguridad.Usuarios u ON u.id_usuario = k.id_usuario;
GO

-- ============================================= 2. TRIGGERS

-- 2.1 Price Change -> HistorialPrecios
GO
CREATE TRIGGER trg_Productos_PriceChange
ON Inventario.Productos
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(precio_venta) OR UPDATE(costo_unitario)
    BEGIN
        INSERT INTO Inventario.HistorialPrecios (id_producto, precio_anterior, precio_nuevo, costo_anterior, costo_nuevo, id_usuario)
        SELECT i.id_producto, i.precio_venta, d.precio_venta, i.costo_unitario, d.costo_unitario, 1
        FROM deleted i
        JOIN inserted d ON d.id_producto = i.id_producto
        WHERE (i.precio_venta != d.precio_venta OR i.costo_unitario != d.costo_unitario);
    END;
END;
GO

-- 2.2 Venta INSERT -> Puntos Cliente
GO
CREATE TRIGGER trg_Ventas_AddPuntos
ON Ventas.Ventas
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE c
    SET puntos = c.puntos + i.puntos_generados
    FROM Ventas.Clientes c
    INNER JOIN inserted i ON i.id_cliente = c.id_cliente
    WHERE i.id_cliente IS NOT NULL
      AND i.id_cliente != (SELECT id_cliente FROM Ventas.Clientes WHERE dni = '00000000');
END;
GO

-- 2.3 DetalleVenta INSERT -> Descontar stock (recetas o directo) + Kardex
GO
CREATE TRIGGER trg_DetalleVenta_DescontarStock
ON Ventas.DetalleVenta
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Productos CON receta: descontar insumos
    UPDATE p
    SET stock_actual = p.stock_actual - (dr.cantidad * dv.cantidad)
    FROM Inventario.Productos p
    INNER JOIN Produccion.DetalleReceta dr ON dr.id_producto = p.id_producto
    INNER JOIN Produccion.Recetas r ON r.id_receta = dr.id_receta AND r.activo = 1
    INNER JOIN inserted dv ON dv.id_producto = r.id_producto;

    INSERT INTO Inventario.Kardex (id_producto, tipo_movimiento, cantidad, stock_anterior, stock_nuevo, referencia_tabla, referencia_id, id_usuario)
    SELECT
        dr.id_producto, 'SALIDA', dr.cantidad * dv.cantidad,
        p.stock_actual + (dr.cantidad * dv.cantidad),
        p.stock_actual,
        'DETALLE_VENTA', dv.id_venta, v.id_usuario
    FROM inserted dv
    INNER JOIN Ventas.Ventas v ON v.id_venta = dv.id_venta
    INNER JOIN Produccion.Recetas r ON r.id_producto = dv.id_producto AND r.activo = 1
    INNER JOIN Produccion.DetalleReceta dr ON dr.id_receta = r.id_receta
    INNER JOIN Inventario.Productos p ON p.id_producto = dr.id_producto;

    -- Productos SIN receta: descontar directamente
    UPDATE p
    SET stock_actual = p.stock_actual - dv.cantidad
    FROM Inventario.Productos p
    INNER JOIN inserted dv ON dv.id_producto = p.id_producto
    WHERE NOT EXISTS (SELECT 1 FROM Produccion.Recetas r WHERE r.id_producto = dv.id_producto AND r.activo = 1);

    INSERT INTO Inventario.Kardex (id_producto, tipo_movimiento, cantidad, stock_anterior, stock_nuevo, referencia_tabla, referencia_id, id_usuario)
    SELECT
        dv.id_producto, 'SALIDA', dv.cantidad,
        p.stock_actual + dv.cantidad,
        p.stock_actual,
        'DETALLE_VENTA', dv.id_venta, v.id_usuario
    FROM inserted dv
    INNER JOIN Ventas.Ventas v ON v.id_venta = dv.id_venta
    INNER JOIN Inventario.Productos p ON p.id_producto = dv.id_producto
    WHERE NOT EXISTS (SELECT 1 FROM Produccion.Recetas r WHERE r.id_producto = dv.id_producto AND r.activo = 1);
END;
GO

-- 2.4 DetalleCompra INSERT -> Ingresar stock + Kardex
GO
CREATE TRIGGER trg_DetalleCompra_IngresarStock
ON Inventario.DetalleCompra
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE p
    SET stock_actual = p.stock_actual + dc.cantidad,
        costo_unitario = dc.precio_unitario
    FROM Inventario.Productos p
    INNER JOIN inserted dc ON dc.id_producto = p.id_producto;

    INSERT INTO Inventario.Kardex (id_producto, tipo_movimiento, cantidad, stock_anterior, stock_nuevo, referencia_tabla, referencia_id, id_usuario)
    SELECT
        dc.id_producto, 'ENTRADA', dc.cantidad,
        p.stock_actual - dc.cantidad,
        p.stock_actual,
        'DETALLE_COMPRA', dc.id_compra, c.id_usuario
    FROM inserted dc
    INNER JOIN Inventario.Compras c ON c.id_compra = dc.id_compra
    INNER JOIN Inventario.Productos p ON p.id_producto = dc.id_producto;
END;
GO

-- 2.5 Trigger CHECK constraints (prevents invalid data)
GO
ALTER TABLE Ventas.Ventas ADD CONSTRAINT ck_ventas_estado CHECK (estado IN ('PAGADO','ANULADO','PENDIENTE'));
GO
ALTER TABLE Ventas.Mesas ADD CONSTRAINT ck_mesas_estado CHECK (estado IN ('LIBRE','OCUPADO','RESERVADO'));
GO
ALTER TABLE Inventario.Productos ADD CONSTRAINT ck_productos_precio CHECK (precio_venta >= 0 AND costo_unitario >= 0);
GO
ALTER TABLE Ventas.Promociones ADD CONSTRAINT ck_promociones_tipo CHECK (tipo IN ('DESCUENTO','2X1','COMBO','PORCENTAJE'));
GO

-- ============================================= 3. NUEVOS PROCEDIMIENTOS

-- 3.1 Ajuste manual de stock (con Kardex)
GO
CREATE PROCEDURE Inventario.spAjustarStock
    @id_producto INT, @nuevo_stock DECIMAL(10,2), @motivo VARCHAR(200), @id_usuario INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @stock_actual DECIMAL(10,2);

    SELECT @stock_actual = stock_actual FROM Inventario.Productos WHERE id_producto = @id_producto;

    UPDATE Inventario.Productos SET stock_actual = @nuevo_stock WHERE id_producto = @id_producto;

    INSERT INTO Inventario.Kardex (id_producto, tipo_movimiento, cantidad, stock_anterior, stock_nuevo, referencia_tabla, motivo, id_usuario)
    VALUES (@id_producto, 'AJUSTE', @nuevo_stock - @stock_actual, @stock_actual, @nuevo_stock, 'AJUSTE_MANUAL', @motivo, @id_usuario);

    SELECT 1 AS resultado;
END;
GO

-- 3.2 Reporte mensual
GO
CREATE PROCEDURE Finanzas.spReporteMensual
    @anio INT, @mes INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 'VENTAS' AS tipo, COUNT(*) AS cantidad, ISNULL(SUM(total), 0) AS total, ISNULL(AVG(total), 0) AS promedio
    FROM Ventas.Ventas
    WHERE YEAR(fecha) = @anio AND MONTH(fecha) = @mes;

    SELECT 'GASTOS' AS tipo, COUNT(*) AS cantidad, ISNULL(SUM(monto), 0) AS total
    FROM Finanzas.Gastos
    WHERE YEAR(fecha) = @anio AND MONTH(fecha) = @mes;

    SELECT p.nombre, SUM(dv.cantidad) AS vendido, SUM(dv.subtotal) AS total
    FROM Ventas.DetalleVenta dv
    JOIN Ventas.Ventas v ON v.id_venta = dv.id_venta
    JOIN Inventario.Productos p ON p.id_producto = dv.id_producto
    WHERE YEAR(v.fecha) = @anio AND MONTH(v.fecha) = @mes
    GROUP BY p.nombre
    ORDER BY SUM(dv.cantidad) DESC;

    SELECT
        (SELECT ISNULL(SUM(total), 0) FROM Ventas.Ventas WHERE YEAR(fecha) = @anio AND MONTH(fecha) = @mes) AS total_ventas,
        (SELECT ISNULL(SUM(monto), 0) FROM Finanzas.Gastos WHERE YEAR(fecha) = @anio AND MONTH(fecha) = @mes) AS total_gastos,
        (SELECT ISNULL(SUM(total), 0) FROM Ventas.Ventas WHERE YEAR(fecha) = @anio AND MONTH(fecha) = @mes) -
        (SELECT ISNULL(SUM(monto), 0) FROM Finanzas.Gastos WHERE YEAR(fecha) = @anio AND MONTH(fecha) = @mes) AS utilidad_neta;
END;
GO

-- 3.3 Obtener Kardex de un producto
GO
CREATE PROCEDURE Inventario.spConsultarKardex
    @id_producto INT = NULL, @fecha_inicio DATE = NULL, @fecha_fin DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM Inventario.vwKardexCompleto
    WHERE (@id_producto IS NULL OR id_producto = @id_producto)
      AND (@fecha_inicio IS NULL OR fecha >= @fecha_inicio)
      AND (@fecha_fin IS NULL OR fecha <= @fecha_fin)
    ORDER BY fecha DESC;
END;
GO

-- ============================================= 4. CORREGIR SPs EXISTENTES
-- Eliminar el UPDATE manual de stock de los SPs (ahora lo hacen los triggers)

GO
ALTER PROCEDURE Ventas.spRegistrarVenta
    @id_cliente INT, @id_usuario INT, @id_mesa INT = NULL, @id_promocion INT = NULL,
    @id_producto1 INT, @cantidad1 DECIMAL(10,2), @precio1 DECIMAL(10,2),
    @id_producto2 INT = NULL, @cantidad2 DECIMAL(10,2) = 0, @precio2 DECIMAL(10,2) = 0,
    @id_producto3 INT = NULL, @cantidad3 DECIMAL(10,2) = 0, @precio3 DECIMAL(10,2) = 0,
    @id_metodo_pago INT, @monto_pago DECIMAL(10,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @id_venta INT, @subtotal DECIMAL(10,2) = 0, @total DECIMAL(10,2) = 0;
    DECLARE @serie VARCHAR(4) = 'B001', @numero INT;
    DECLARE @puntos INT = 0;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @numero = ISNULL(MAX(numero), 0) + 1 FROM Ventas.Ventas WHERE serie = @serie;

        INSERT INTO Ventas.Ventas (id_cliente, id_usuario, id_mesa, id_promocion, serie, numero, subtotal, total, puntos_generados)
        VALUES (@id_cliente, @id_usuario, @id_mesa, @id_promocion, @serie, @numero, 0, 0, 0);
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
        SET @puntos = CAST(@total / 10 AS INT);

        UPDATE Ventas.Ventas SET subtotal = @subtotal, total = @total, puntos_generados = @puntos
        WHERE id_venta = @id_venta;

        INSERT INTO Finanzas.Pagos (id_venta, id_metodo, monto)
        VALUES (@id_venta, @id_metodo_pago, ISNULL(@monto_pago, @total));

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

GO
ALTER PROCEDURE Inventario.spRegistrarCompra
    @id_proveedor INT, @id_usuario INT,
    @id_producto1 INT, @cantidad1 DECIMAL(10,2), @precio1 DECIMAL(10,2),
    @id_producto2 INT = NULL, @cantidad2 DECIMAL(10,2) = 0, @precio2 DECIMAL(10,2) = 0,
    @id_producto3 INT = NULL, @cantidad3 DECIMAL(10,2) = 0, @precio3 DECIMAL(10,2) = 0
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @id_compra INT, @total DECIMAL(10,2) = 0;

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

-- ============================================= 5. RECETAS REALES DE COMIDA PERUANA
INSERT INTO Produccion.Recetas (id_producto, nombre, rendimiento) VALUES
(26, 'Receta Pollo Brasa 1/4', 1),
(27, 'Receta Pollo Brasa 1/2', 2),
(28, 'Receta Ceviche Mixto', 1),
(29, 'Receta Lomo Saltado', 1),
(30, 'Receta Aji de Gallina', 1),
(31, 'Receta Arroz con Pollo', 1),
(32, 'Receta Seco de Res', 1);
GO

-- id_producto: 26(Pollo Brasa 1/4),27(Pollo Brasa 1/2),28(Ceviche),29(Lomo Saltado)
-- 30(Aji Gallina),31(Arroz Pollo),32(Seco Res)

-- Pollo Brasa 1/4 -> 1/4 pollo, papas, sal, ensalada
INSERT INTO Produccion.DetalleReceta (id_receta, id_producto, cantidad) VALUES
(1, 12, 0.25), (1, 1, 0.50), (1, 7, 0.10), (1, 19, 0.05);
GO
-- Pollo Brasa 1/2 -> 1/2 pollo, papas, sal, ensalada
INSERT INTO Produccion.DetalleReceta (id_receta, id_producto, cantidad) VALUES
(2, 12, 0.50), (2, 1, 0.80), (2, 7, 0.15), (2, 19, 0.05);
GO
-- Ceviche Mixto -> pescado, limon, cebolla, culantro, lechuga
INSERT INTO Produccion.DetalleReceta (id_receta, id_producto, cantidad) VALUES
(3, 16, 0.30), (3, 9, 0.30), (3, 4, 0.20), (3, 8, 0.10), (3, 7, 0.10);
GO
-- Lomo Saltado -> lomo, cebolla, tomate, papa, arroz, aceite, sillao
INSERT INTO Produccion.DetalleReceta (id_receta, id_producto, cantidad) VALUES
(4, 14, 0.25), (4, 4, 0.15), (4, 5, 0.15), (4, 1, 0.30),
(4, 17, 0.20), (4, 19, 0.05), (4, 21, 0.05);
GO
-- Aji de Gallina -> pollo, pan, leche, arroz, cebolla, aji
INSERT INTO Produccion.DetalleReceta (id_receta, id_producto, cantidad) VALUES
(5, 11, 0.25), (5, 22, 0.10), (5, 4, 0.10), (5, 17, 0.20), (5, 6, 0.05);
GO
-- Arroz con Pollo -> pollo, arroz, zanahoria, cebolla, ajo, culantro
INSERT INTO Produccion.DetalleReceta (id_receta, id_producto, cantidad) VALUES
(6, 11, 0.25), (6, 17, 0.20), (6, 2, 0.15),
(6, 4, 0.10), (6, 6, 0.05), (6, 8, 0.10);
GO
-- Seco de Res -> res, zapallo, arroz, frijoles, culantro, ajo, cebolla
INSERT INTO Produccion.DetalleReceta (id_receta, id_producto, cantidad) VALUES
(7, 14, 0.25), (7, 17, 0.20), (7, 4, 0.10), (7, 6, 0.05), (7, 8, 0.10);
GO

PRINT '==================================================';
PRINT ' INCREMENTO APLICADO CORRECTAMENTE';
PRINT '==================================================';
PRINT ' + Tabla Kardex con vista y procedimiento';
PRINT ' + 5 Triggers (precios, puntos, stock, compras, checks)';
PRINT ' + 3 Nuevos Procedimientos (ajuste, reporte, kardex)';
PRINT ' + SPs corregidos (stock ahora via triggers)';
PRINT ' + 7 Recetas reales de comida peruana';
PRINT '==================================================';
GO
