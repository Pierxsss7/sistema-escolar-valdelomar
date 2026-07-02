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
CREATE SCHEMA reportes;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- SEGURIDAD
CREATE TABLE seg.roles (
    id_rol INT IDENTITY PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    descripcion VARCHAR(200) NULL
);
GO

CREATE TABLE seg.permisos (
    id_permiso INT IDENTITY PRIMARY KEY,
    codigo VARCHAR(30) NOT NULL,
    nombre VARCHAR(80) NOT NULL,
    modulo VARCHAR(30) NOT NULL
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
    apellido VARCHAR(100) NULL,
    usuario VARCHAR(50) NOT NULL,
    clave_hash VARCHAR(255) NOT NULL,
    telefono VARCHAR(20) NULL,
    activo BIT NOT NULL DEFAULT 1,
    ultimo_acceso DATETIME2 NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (id_rol) REFERENCES seg.roles(id_rol)
);
GO

CREATE UNIQUE INDEX uq_usuario ON seg.usuarios(usuario);
GO

-- NEGOCIO
CREATE TABLE negocio.proveedores (
    id_proveedor INT IDENTITY PRIMARY KEY,
    ruc VARCHAR(11) NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    telefono VARCHAR(20) NULL,
    email VARCHAR(100) NULL,
    direccion VARCHAR(200) NULL,
    activo BIT NOT NULL DEFAULT 1,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

CREATE UNIQUE INDEX uq_proveedor_ruc ON negocio.proveedores(ruc);
GO

CREATE TABLE negocio.clientes (
    id_cliente INT IDENTITY PRIMARY KEY,
    dni VARCHAR(8) NOT NULL,
    nombre VARCHAR(120) NOT NULL,
    telefono VARCHAR(20) NULL,
    direccion VARCHAR(200) NULL,
    puntos INT NOT NULL DEFAULT 0,
    activo BIT NOT NULL DEFAULT 1,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

CREATE UNIQUE INDEX uq_cliente_dni ON negocio.clientes(dni);
GO

-- PRODUCTOS
CREATE TABLE producto.categorias (
    id_categoria INT IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    activo BIT NOT NULL DEFAULT 1
);
GO

CREATE TABLE producto.subcategorias (
    id_subcategoria INT IDENTITY PRIMARY KEY,
    id_categoria INT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    FOREIGN KEY (id_categoria) REFERENCES producto.categorias(id_categoria)
);
GO

CREATE TABLE producto.unidades (
    id_unidad INT IDENTITY PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    abreviatura VARCHAR(10) NOT NULL
);
GO

CREATE TABLE producto.productos (
    id_producto INT IDENTITY PRIMARY KEY,
    id_categoria INT NOT NULL,
    id_subcategoria INT NULL,
    id_unidad INT NOT NULL,
    nombre VARCHAR(120) NOT NULL,
    descripcion VARCHAR(250) NULL,
    tipo VARCHAR(15) NOT NULL,
    activo BIT NOT NULL DEFAULT 1,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (id_categoria) REFERENCES producto.categorias(id_categoria),
    FOREIGN KEY (id_subcategoria) REFERENCES producto.subcategorias(id_subcategoria),
    FOREIGN KEY (id_unidad) REFERENCES producto.unidades(id_unidad)
);
GO

CREATE INDEX ix_producto_nombre ON producto.productos(nombre);
GO

CREATE TABLE producto.precios (
    id_precio INT IDENTITY PRIMARY KEY,
    id_producto INT NOT NULL,
    precio_venta DECIMAL(10,2) NOT NULL DEFAULT 0,
    costo DECIMAL(10,2) NOT NULL DEFAULT 0,
    activo BIT NOT NULL DEFAULT 1,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (id_producto) REFERENCES producto.productos(id_producto)
);
GO

CREATE INDEX ix_precios_activo ON producto.precios(id_producto, activo);
GO

-- RECETAS
CREATE TABLE produccion.recetas (
    id_receta INT IDENTITY PRIMARY KEY,
    id_producto INT NOT NULL,
    nombre VARCHAR(120) NOT NULL,
    rendimiento DECIMAL(10,2) NOT NULL DEFAULT 1,
    activo BIT NOT NULL DEFAULT 1,
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

-- INVENTARIO
CREATE TABLE inventario.stock (
    id_stock INT IDENTITY PRIMARY KEY,
    id_producto INT NOT NULL,
    cantidad DECIMAL(10,2) NOT NULL DEFAULT 0,
    stock_minimo DECIMAL(10,2) NOT NULL DEFAULT 0,
    FOREIGN KEY (id_producto) REFERENCES producto.productos(id_producto)
);
GO

CREATE UNIQUE INDEX uq_stock_producto ON inventario.stock(id_producto);
GO

CREATE TABLE inventario.kardex (
    id_kardex BIGINT IDENTITY PRIMARY KEY,
    id_producto INT NOT NULL,
    fecha DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    tipo_movimiento VARCHAR(20) NOT NULL,
    cantidad_entrada DECIMAL(10,2) NOT NULL DEFAULT 0,
    cantidad_salida DECIMAL(10,2) NOT NULL DEFAULT 0,
    saldo DECIMAL(10,2) NOT NULL,
    costo_unitario DECIMAL(10,2) NOT NULL DEFAULT 0,
    costo_total DECIMAL(10,2) NOT NULL DEFAULT 0,
    documento_tipo VARCHAR(20) NULL,
    documento_id INT NULL,
    usuario_id INT NULL,
    FOREIGN KEY (id_producto) REFERENCES producto.productos(id_producto),
    FOREIGN KEY (usuario_id) REFERENCES seg.usuarios(id_usuario)
);
GO

CREATE INDEX ix_kardex_producto ON inventario.kardex(id_producto, fecha DESC);
GO

-- COMPRAS
CREATE TABLE compra.compras (
    id_compra INT IDENTITY PRIMARY KEY,
    id_proveedor INT NOT NULL,
    id_usuario INT NOT NULL,
    tipo_documento VARCHAR(20) NOT NULL DEFAULT 'FACTURA',
    serie VARCHAR(10) NULL,
    numero VARCHAR(20) NULL,
    subtotal DECIMAL(10,2) NOT NULL DEFAULT 0,
    igv DECIMAL(10,2) NOT NULL DEFAULT 0,
    total DECIMAL(10,2) NOT NULL DEFAULT 0,
    fecha_emision DATE NOT NULL DEFAULT CAST(SYSDATETIME() AS DATE),
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (id_proveedor) REFERENCES negocio.proveedores(id_proveedor),
    FOREIGN KEY (id_usuario) REFERENCES seg.usuarios(id_usuario)
);
GO

CREATE TABLE compra.detalle (
    id_detalle INT IDENTITY PRIMARY KEY,
    id_compra INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad DECIMAL(10,2) NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (id_compra) REFERENCES compra.compras(id_compra),
    FOREIGN KEY (id_producto) REFERENCES producto.productos(id_producto)
);
GO

CREATE INDEX ix_detalle_compra ON compra.detalle(id_compra);
GO

-- VENTAS
CREATE TABLE venta.mesas (
    id_mesa INT IDENTITY PRIMARY KEY,
    numero INT NOT NULL,
    capacidad INT NOT NULL DEFAULT 4,
    estado VARCHAR(20) NOT NULL DEFAULT 'LIBRE'
);
GO

CREATE TABLE venta.tipos_venta (
    id_tipo INT IDENTITY PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL
);
GO

CREATE TABLE venta.ventas (
    id_venta INT IDENTITY PRIMARY KEY,
    id_cliente INT NULL,
    id_usuario INT NOT NULL,
    id_mesa INT NULL,
    id_tipo_venta INT NOT NULL DEFAULT 1,
    tipo_comprobante VARCHAR(10) NOT NULL DEFAULT 'BOLETA',
    serie VARCHAR(10) NULL,
    numero VARCHAR(20) NULL,
    subtotal DECIMAL(10,2) NOT NULL DEFAULT 0,
    descuento DECIMAL(10,2) NOT NULL DEFAULT 0,
    igv DECIMAL(10,2) NOT NULL DEFAULT 0,
    total DECIMAL(10,2) NOT NULL DEFAULT 0,
    estado VARCHAR(20) NOT NULL DEFAULT 'PAGADO',
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (id_cliente) REFERENCES negocio.clientes(id_cliente),
    FOREIGN KEY (id_usuario) REFERENCES seg.usuarios(id_usuario),
    FOREIGN KEY (id_mesa) REFERENCES venta.mesas(id_mesa),
    FOREIGN KEY (id_tipo_venta) REFERENCES venta.tipos_venta(id_tipo)
);
GO

CREATE INDEX ix_ventas_fecha ON venta.ventas(created_at DESC);
GO

CREATE TABLE venta.detalle_venta (
    id_detalle INT IDENTITY PRIMARY KEY,
    id_venta INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad DECIMAL(10,2) NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    descuento DECIMAL(10,2) NOT NULL DEFAULT 0,
    subtotal DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (id_venta) REFERENCES venta.ventas(id_venta),
    FOREIGN KEY (id_producto) REFERENCES producto.productos(id_producto)
);
GO

CREATE INDEX ix_detalle_venta ON venta.detalle_venta(id_venta);
GO

-- PEDIDOS
CREATE TABLE venta.pedidos (
    id_pedido INT IDENTITY PRIMARY KEY,
    id_cliente INT NULL,
    id_usuario INT NOT NULL,
    tipo VARCHAR(20) NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    direccion VARCHAR(200) NULL,
    telefono VARCHAR(20) NULL,
    total DECIMAL(10,2) NOT NULL DEFAULT 0,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (id_cliente) REFERENCES negocio.clientes(id_cliente),
    FOREIGN KEY (id_usuario) REFERENCES seg.usuarios(id_usuario)
);
GO

CREATE TABLE venta.detalle_pedido (
    id_detalle INT IDENTITY PRIMARY KEY,
    id_pedido INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad DECIMAL(10,2) NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (id_pedido) REFERENCES venta.pedidos(id_pedido),
    FOREIGN KEY (id_producto) REFERENCES producto.productos(id_producto)
);
GO

-- PAGOS
CREATE TABLE financiero.metodos_pago (
    id_metodo INT IDENTITY PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    codigo VARCHAR(10) NOT NULL
);
GO

CREATE TABLE venta.pagos (
    id_pago INT IDENTITY PRIMARY KEY,
    id_venta INT NULL,
    id_pedido INT NULL,
    id_metodo INT NOT NULL,
    monto DECIMAL(10,2) NOT NULL,
    referencia VARCHAR(100) NULL,
    fecha DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (id_venta) REFERENCES venta.ventas(id_venta),
    FOREIGN KEY (id_pedido) REFERENCES venta.pedidos(id_pedido),
    FOREIGN KEY (id_metodo) REFERENCES financiero.metodos_pago(id_metodo)
);
GO

-- CAJA
CREATE TABLE financiero.cajas (
    id_caja INT IDENTITY PRIMARY KEY,
    id_usuario INT NOT NULL,
    fecha_apertura DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    fecha_cierre DATETIME2 NULL,
    monto_inicial DECIMAL(10,2) NOT NULL DEFAULT 0,
    monto_final DECIMAL(10,2) NULL,
    total_efectivo DECIMAL(10,2) NOT NULL DEFAULT 0,
    total_yape DECIMAL(10,2) NOT NULL DEFAULT 0,
    total_plin DECIMAL(10,2) NOT NULL DEFAULT 0,
    total_tarjeta DECIMAL(10,2) NOT NULL DEFAULT 0,
    diferencia DECIMAL(10,2) NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'ABIERTO',
    FOREIGN KEY (id_usuario) REFERENCES seg.usuarios(id_usuario)
);
GO

-- PRODUCCION
CREATE TABLE produccion.ordenes (
    id_orden INT IDENTITY PRIMARY KEY,
    id_receta INT NOT NULL,
    id_usuario INT NOT NULL,
    cantidad DECIMAL(10,2) NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (id_receta) REFERENCES produccion.recetas(id_receta),
    FOREIGN KEY (id_usuario) REFERENCES seg.usuarios(id_usuario)
);
GO

CREATE TABLE produccion.mermas (
    id_merma INT IDENTITY PRIMARY KEY,
    id_producto INT NOT NULL,
    id_usuario INT NOT NULL,
    cantidad DECIMAL(10,2) NOT NULL,
    motivo VARCHAR(200) NOT NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (id_producto) REFERENCES producto.productos(id_producto),
    FOREIGN KEY (id_usuario) REFERENCES seg.usuarios(id_usuario)
);
GO

-- AUDITORIA
CREATE TABLE auditoria.log (
    id_log BIGINT IDENTITY PRIMARY KEY,
    id_usuario INT NULL,
    tabla VARCHAR(100) NOT NULL,
    operacion VARCHAR(20) NOT NULL,
    detalle VARCHAR(MAX) NULL,
    fecha DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

-- VISTAS REPORTES
GO
CREATE VIEW reportes.ventas_diarias AS
SELECT
    v.id_venta,
    v.created_at AS hora,
    u.nombre AS usuario,
    ISNULL(c.nombre, 'GENERAL') AS cliente,
    v.total,
    v.estado
FROM venta.ventas v
INNER JOIN seg.usuarios u ON u.id_usuario = v.id_usuario
LEFT JOIN negocio.clientes c ON c.id_cliente = v.id_cliente
WHERE CAST(v.created_at AS DATE) = CAST(SYSDATETIME() AS DATE);
GO

CREATE VIEW reportes.productos_mas_vendidos AS
SELECT TOP 20
    p.id_producto,
    p.nombre,
    cat.nombre AS categoria,
    SUM(dv.cantidad) AS cantidad,
    SUM(dv.subtotal) AS total
FROM venta.detalle_venta dv
INNER JOIN venta.ventas v ON v.id_venta = dv.id_venta AND v.estado = 'PAGADO'
INNER JOIN producto.productos p ON p.id_producto = dv.id_producto
INNER JOIN producto.categorias cat ON cat.id_categoria = p.id_categoria
GROUP BY p.id_producto, p.nombre, cat.nombre
ORDER BY SUM(dv.cantidad) DESC;
GO

CREATE VIEW reportes.inventario_bajo AS
SELECT
    p.nombre,
    cat.nombre AS categoria,
    ISNULL(s.cantidad, 0) AS stock,
    s.stock_minimo
FROM producto.productos p
INNER JOIN producto.categorias cat ON cat.id_categoria = p.id_categoria
INNER JOIN inventario.stock s ON s.id_producto = p.id_producto
WHERE p.activo = 1 AND ISNULL(s.cantidad, 0) <= s.stock_minimo;
GO

CREATE VIEW reportes.rentabilidad AS
SELECT
    p.nombre,
    pr.precio_venta,
    pr.costo,
    (pr.precio_venta - pr.costo) AS ganancia,
    CASE
        WHEN pr.precio_venta > 0 THEN ((pr.precio_venta - pr.costo) / pr.precio_venta) * 100
        ELSE 0
    END AS margen_porcentaje
FROM producto.productos p
INNER JOIN producto.precios pr ON pr.id_producto = p.id_producto AND pr.activo = 1
WHERE p.activo = 1;
GO

-- STORED PROCEDURES
GO
CREATE PROCEDURE venta.registrar_venta
    @id_cliente INT = NULL,
    @id_usuario INT,
    @id_mesa INT = NULL,
    @id_tipo_venta INT = 1,
    @productos_xml XML,
    @pagos_xml XML
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @id_venta INT;
    DECLARE @subtotal DECIMAL(10,2);
    DECLARE @igv DECIMAL(10,2);
    DECLARE @total DECIMAL(10,2);
    DECLARE @serie VARCHAR(10);
    DECLARE @numero VARCHAR(20);

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @serie = 'B001', @numero = RIGHT('000000' + CAST(ISNULL(MAX(CAST(numero AS INT)), 0) + 1 AS VARCHAR), 6)
        FROM venta.ventas WHERE serie = 'B001';

        INSERT INTO venta.ventas (id_cliente, id_usuario, id_mesa, id_tipo_venta, serie, numero)
        VALUES (@id_cliente, @id_usuario, @id_mesa, @id_tipo_venta, @serie, @numero);

        SET @id_venta = SCOPE_IDENTITY();

        INSERT INTO venta.detalle_venta (id_venta, id_producto, cantidad, precio_unitario, subtotal)
        SELECT
            @id_venta,
            T.c.value('@id_producto', 'INT'),
            T.c.value('@cantidad', 'DECIMAL(10,2)'),
            T.c.value('@precio', 'DECIMAL(10,2)'),
            T.c.value('@cantidad', 'DECIMAL(10,2)') * T.c.value('@precio', 'DECIMAL(10,2)')
        FROM @productos_xml.nodes('/productos/producto') AS T(c);

        SELECT @subtotal = ISNULL(SUM(subtotal), 0) FROM venta.detalle_venta WHERE id_venta = @id_venta;
        SET @igv = @subtotal * 0.18;
        SET @total = @subtotal + @igv;

        UPDATE venta.ventas
        SET subtotal = @subtotal, igv = @igv, total = @total
        WHERE id_venta = @id_venta;

        INSERT INTO venta.pagos (id_venta, id_metodo, monto, referencia)
        SELECT @id_venta, T.c.value('@id_metodo', 'INT'), T.c.value('@monto', 'DECIMAL(10,2)'), T.c.value('@ref', 'VARCHAR(100)')
        FROM @pagos_xml.nodes('/pagos/pago') AS T(c);

        UPDATE s
        SET s.cantidad = s.cantidad - dv.cantidad
        FROM inventario.stock s
        INNER JOIN venta.detalle_venta dv ON dv.id_producto = s.id_producto AND dv.id_venta = @id_venta
        INNER JOIN producto.productos p ON p.id_producto = s.id_producto
        WHERE p.tipo IN ('VENTA', 'PRODUCIDO');

        IF @id_mesa IS NOT NULL
        BEGIN
            UPDATE venta.mesas SET estado = 'LIBRE' WHERE id_mesa = @id_mesa;
        END;

        INSERT INTO auditoria.log (id_usuario, tabla, operacion, detalle)
        VALUES (@id_usuario, 'VENTAS', 'INSERT', 'Venta ' + @serie + '-' + @numero + ' Total: S/' + CAST(@total AS VARCHAR));

        COMMIT TRANSACTION;

        SELECT @id_venta AS id_venta, @total AS total;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT ERROR_MESSAGE() AS error;
    END CATCH;
END;
GO

CREATE PROCEDURE compra.registrar_compra
    @id_proveedor INT,
    @id_usuario INT,
    @tipo_documento VARCHAR(20) = 'FACTURA',
    @productos_xml XML
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @id_compra INT;
    DECLARE @subtotal DECIMAL(10,2);
    DECLARE @igv DECIMAL(10,2);
    DECLARE @total DECIMAL(10,2);

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO compra.compras (id_proveedor, id_usuario, tipo_documento)
        VALUES (@id_proveedor, @id_usuario, @tipo_documento);

        SET @id_compra = SCOPE_IDENTITY();

        INSERT INTO compra.detalle (id_compra, id_producto, cantidad, precio_unitario, subtotal)
        SELECT
            @id_compra,
            T.c.value('@id_producto', 'INT'),
            T.c.value('@cantidad', 'DECIMAL(10,2)'),
            T.c.value('@precio', 'DECIMAL(10,2)'),
            T.c.value('@cantidad', 'DECIMAL(10,2)') * T.c.value('@precio', 'DECIMAL(10,2)')
        FROM @productos_xml.nodes('/productos/producto') AS T(c);

        SELECT @subtotal = ISNULL(SUM(subtotal), 0) FROM compra.detalle WHERE id_compra = @id_compra;
        SET @igv = @subtotal * 0.18;
        SET @total = @subtotal + @igv;

        UPDATE compra.compras SET subtotal = @subtotal, igv = @igv, total = @total WHERE id_compra = @id_compra;

        INSERT INTO inventario.kardex (id_producto, tipo_movimiento, cantidad_entrada, saldo, costo_unitario, costo_total, documento_tipo, documento_id, usuario_id)
        SELECT
            d.id_producto,
            'COMPRA',
            d.cantidad,
            ISNULL(s.cantidad, 0) + d.cantidad,
            d.precio_unitario,
            d.subtotal,
            'COMPRA',
            @id_compra,
            @id_usuario
        FROM compra.detalle d
        INNER JOIN producto.productos p ON p.id_producto = d.id_producto
        LEFT JOIN inventario.stock s ON s.id_producto = d.id_producto;

        MERGE inventario.stock AS destino
        USING (SELECT id_producto, cantidad FROM compra.detalle WHERE id_compra = @id_compra) AS origen
        ON (destino.id_producto = origen.id_producto)
        WHEN MATCHED THEN UPDATE SET destino.cantidad = destino.cantidad + origen.cantidad
        WHEN NOT MATCHED THEN INSERT (id_producto, cantidad) VALUES (origen.id_producto, origen.cantidad);

        INSERT INTO auditoria.log (id_usuario, tabla, operacion, detalle)
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

CREATE PROCEDURE produccion.producir
    @id_receta INT,
    @id_usuario INT,
    @cantidad DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @id_producto INT;
    DECLARE @costo_total DECIMAL(10,2);

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @id_producto = id_producto FROM produccion.recetas WHERE id_receta = @id_receta;

        INSERT INTO produccion.ordenes (id_receta, id_usuario, cantidad, estado)
        VALUES (@id_receta, @id_usuario, @cantidad, 'COMPLETADO');

        SELECT @costo_total = ISNULL(SUM(
            (dr.cantidad * @cantidad / r.rendimiento) * pr.costo
        ), 0)
        FROM produccion.detalle_receta dr
        INNER JOIN produccion.recetas r ON r.id_receta = dr.id_receta
        INNER JOIN producto.precios pr ON pr.id_producto = dr.id_producto AND pr.activo = 1
        WHERE dr.id_receta = @id_receta;

        UPDATE s
        SET s.cantidad = s.cantidad - (dr.cantidad * @cantidad / r.rendimiento)
        FROM inventario.stock s
        INNER JOIN produccion.detalle_receta dr ON dr.id_producto = s.id_producto
        INNER JOIN produccion.recetas r ON r.id_receta = dr.id_receta
        WHERE dr.id_receta = @id_receta;

        IF EXISTS (SELECT 1 FROM inventario.stock WHERE id_producto = @id_producto)
        BEGIN
            UPDATE inventario.stock SET cantidad = cantidad + @cantidad WHERE id_producto = @id_producto;
        END
        ELSE
        BEGIN
            INSERT INTO inventario.stock (id_producto, cantidad) VALUES (@id_producto, @cantidad);
        END;

        INSERT INTO inventario.kardex (id_producto, tipo_movimiento, cantidad_entrada, saldo, costo_unitario, costo_total, documento_tipo, documento_id, usuario_id)
        SELECT @id_producto, 'PRODUCCION', @cantidad, s.cantidad, @costo_total / @cantidad, @costo_total, 'RECETA', @id_receta, @id_usuario
        FROM inventario.stock s WHERE s.id_producto = @id_producto;

        COMMIT TRANSACTION;

        SELECT 1 AS resultado;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT ERROR_MESSAGE() AS error;
    END CATCH;
END;
GO

CREATE PROCEDURE financiero.cerrar_caja
    @id_caja INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @inicial DECIMAL(10,2);
    DECLARE @efectivo DECIMAL(10,2);
    DECLARE @yape DECIMAL(10,2);
    DECLARE @plin DECIMAL(10,2);
    DECLARE @tarjeta DECIMAL(10,2);
    DECLARE @total DECIMAL(10,2);
    DECLARE @diferencia DECIMAL(10,2);

    BEGIN TRY
        SELECT @inicial = monto_inicial FROM financiero.cajas WHERE id_caja = @id_caja;

        SELECT @efectivo = ISNULL(SUM(p.monto), 0)
        FROM venta.pagos p
        INNER JOIN financiero.metodos_pago m ON m.id_metodo = p.id_metodo
        WHERE m.codigo = 'EFE' AND CAST(p.fecha AS DATE) = CAST(SYSDATETIME() AS DATE);

        SELECT @yape = ISNULL(SUM(p.monto), 0)
        FROM venta.pagos p
        INNER JOIN financiero.metodos_pago m ON m.id_metodo = p.id_metodo
        WHERE m.codigo = 'YAP' AND CAST(p.fecha AS DATE) = CAST(SYSDATETIME() AS DATE);

        SELECT @plin = ISNULL(SUM(p.monto), 0)
        FROM venta.pagos p
        INNER JOIN financiero.metodos_pago m ON m.id_metodo = p.id_metodo
        WHERE m.codigo = 'PLN' AND CAST(p.fecha AS DATE) = CAST(SYSDATETIME() AS DATE);

        SELECT @tarjeta = ISNULL(SUM(p.monto), 0)
        FROM venta.pagos p
        INNER JOIN financiero.metodos_pago m ON m.id_metodo = p.id_metodo
        WHERE m.codigo = 'TAR' AND CAST(p.fecha AS DATE) = CAST(SYSDATETIME() AS DATE);

        SET @total = @inicial + @efectivo + @yape + @plin + @tarjeta;
        SET @diferencia = 0;

        UPDATE financiero.cajas
        SET fecha_cierre = SYSDATETIME(),
            monto_final = @total,
            total_efectivo = @efectivo,
            total_yape = @yape,
            total_plin = @plin,
            total_tarjeta = @tarjeta,
            diferencia = @diferencia,
            estado = 'CERRADO'
        WHERE id_caja = @id_caja;

        SELECT @inicial AS monto_inicial, @efectivo AS efectivo, @yape AS yape,
               @plin AS plin, @tarjeta AS tarjeta, @total AS total_final;
    END TRY
    BEGIN CATCH
        SELECT ERROR_MESSAGE() AS error;
    END CATCH;
END;
GO

-- DATOS INICIALES
INSERT INTO seg.roles (nombre, descripcion) VALUES
('ADMINISTRADOR', 'Acceso total al sistema'),
('CAJERO', 'Ventas y caja'),
('COCINA', 'Preparacion de platos'),
('ALMACENERO', 'Inventario y compras'),
('REPARTIDOR', 'Delivery');
GO

INSERT INTO seg.permisos (codigo, nombre, modulo) VALUES
('USUARIOS', 'Gestionar usuarios', 'SEGURIDAD'),
('PRODUCTOS', 'Gestionar productos', 'PRODUCTOS'),
('VENTAS', 'Registrar ventas', 'VENTAS'),
('PEDIDOS', 'Gestionar pedidos', 'VENTAS'),
('COMPRAS', 'Registrar compras', 'COMPRAS'),
('INVENTARIO', 'Ver inventario', 'INVENTARIO'),
('CAJA', 'Manejar caja', 'FINANZAS'),
('REPORTES', 'Ver reportes', 'REPORTES'),
('RECETAS', 'Gestionar recetas', 'PRODUCCION'),
('CLIENTES', 'Gestionar clientes', 'NEGOCIO'),
('PROVEEDORES', 'Gestionar proveedores', 'NEGOCIO');
GO

INSERT INTO seg.rol_permiso (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso FROM seg.roles r CROSS JOIN seg.permisos p WHERE r.nombre = 'ADMINISTRADOR';
GO

INSERT INTO seg.rol_permiso (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso FROM seg.roles r, seg.permisos p
WHERE r.nombre = 'CAJERO' AND p.codigo IN ('VENTAS', 'PEDIDOS', 'CAJA', 'REPORTES', 'CLIENTES');
GO

INSERT INTO seg.rol_permiso (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso FROM seg.roles r, seg.permisos p
WHERE r.nombre = 'COCINA' AND p.codigo IN ('PEDIDOS', 'RECETAS', 'INVENTARIO', 'PRODUCTOS');
GO

INSERT INTO seg.rol_permiso (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso FROM seg.roles r, seg.permisos p
WHERE r.nombre = 'ALMACENERO' AND p.codigo IN ('PRODUCTOS', 'COMPRAS', 'INVENTARIO', 'PROVEEDORES');
GO

INSERT INTO seg.usuarios (id_rol, nombre, usuario, clave_hash) VALUES
(1, 'Admin', 'admin', 'admin123'),
(2, 'Cajero', 'cajero', 'cajero123'),
(3, 'Cocina', 'cocina', 'cocina123');
GO

INSERT INTO producto.unidades (nombre, abreviatura) VALUES
('Unidad', 'und'),
('Kilogramo', 'kg'),
('Gramo', 'g'),
('Litro', 'L'),
('Mililitro', 'ml'),
('Docena', 'doc'),
('Paquete', 'paq'),
('Porcion', 'por'),
('Bolsa', 'bol');
GO

INSERT INTO producto.categorias (nombre) VALUES
('Verduras'), ('Carnes y Aves'), ('Abarrotes'),
('Lacteos'), ('Bebidas'), ('Platos de Fondo'),
('Entradas'), ('Combos'), ('Postres'), ('Piqueos');
GO

INSERT INTO producto.subcategorias (id_categoria, nombre) VALUES
(1, 'Tuberculos'), (1, 'Hojas Verdes'), (1, 'Legumbres'),
(2, 'Pollo'), (2, 'Carne de Res'), (2, 'Pescado'),
(3, 'Arroz'), (3, 'Fideos'), (3, 'Condimentos'), (3, 'Enlatados'),
(4, 'Huevos'), (4, 'Quesos'),
(5, 'Gaseosas'), (5, 'Jugos'), (5, 'Aguas'),
(6, 'Pollo'), (6, 'Pescado'), (6, 'Carnes'),
(9, 'Caseros');
GO

INSERT INTO financiero.metodos_pago (nombre, codigo) VALUES
('EFECTIVO', 'EFE'),
('YAPE', 'YAP'),
('PLIN', 'PLN'),
('TARJETA', 'TAR'),
('TRANSFERENCIA', 'TRA');
GO

INSERT INTO venta.tipos_venta (nombre) VALUES
('MESA'), ('PARA LLEVAR'), ('DELIVERY');
GO

INSERT INTO venta.mesas (numero, capacidad) VALUES
(1,4), (2,4), (3,4), (4,2), (5,4),
(6,4), (7,6), (8,2), (9,4), (10,4);
GO

INSERT INTO negocio.proveedores (ruc, nombre, telefono, direccion) VALUES
('20123456789', 'Mercado Mayorista SJL', '987000001', 'Av. Central SJL'),
('20123456788', 'Distribuidora San Juan', '987000002', 'Jr. Las Flores 123'),
('20123456787', 'Avicola El Pollon', '987000003', 'Av. Peru 456'),
('20123456786', 'Carnes del Norte', '987000004', 'Jr. Los Olivos 789');
GO

INSERT INTO negocio.clientes (dni, nombre, telefono) VALUES
('00000000', 'Cliente General', ''),
('12345678', 'Juan Perez Garcia', '987654321'),
('87654321', 'Maria Lopez Rojas', '987654322'),
('45678912', 'Carlos Torres', '987654323'),
('32165498', 'Rosa Mamani', '987654324');
GO

PRINT 'BD_SJL creada exitosamente. Todo en orden.';
GO
