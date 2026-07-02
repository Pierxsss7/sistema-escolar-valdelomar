-- ============================================================
-- BD_NEGOCIO_ALIMENTOS v2.0
-- Sistema Profesional para Negocio de Comida
-- Mercado de Lima - Perú
-- ============================================================

-- ============================================================
-- 1. CREACION DE LA BASE DE DATOS
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = 'BD_NEGOCIO_ALIMENTOS')
BEGIN
    CREATE DATABASE BD_NEGOCIO_ALIMENTOS;
END
GO

USE BD_NEGOCIO_ALIMENTOS;
GO

-- ============================================================
-- 2. ESQUEMAS (organizacion por modulos)
-- ============================================================
CREATE SCHEMA seg;        -- Seguridad (usuarios, roles, permisos)
GO
CREATE SCHEMA negocio;    -- Datos del negocio (proveedores, clientes)
GO
CREATE SCHEMA producto;   -- Productos, categorias, recetas
GO
CREATE SCHEMA venta;      -- Ventas, pedidos, pagos
GO
CREATE SCHEMA compra;     -- Compras a proveedores
GO
CREATE SCHEMA inventario; -- Stock, movimientos, lotes
GO
CREATE SCHEMA financiero; -- Caja, metodos de pago
GO
CREATE SCHEMA produccion; -- Recetario y produccion en cocina
GO
CREATE SCHEMA auditoria;  -- Logs de cambios
GO
CREATE SCHEMA reporte;    -- Vistas y reportes
GO

-- ============================================================
-- 3. TABLAS - SEGURIDAD (seg)
-- ============================================================

CREATE TABLE seg.roles (
    id_rol          INT IDENTITY(1,1) PRIMARY KEY,
    nombre          VARCHAR(50) NOT NULL,
    descripcion     VARCHAR(200) NULL,
    es_sistema      BIT NOT NULL DEFAULT 0,
    activo          BIT NOT NULL DEFAULT 1,
    created_at      DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    updated_at      DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT uq_roles_nombre UNIQUE (nombre)
);

CREATE TABLE seg.permisos (
    id_permiso      INT IDENTITY(1,1) PRIMARY KEY,
    codigo          VARCHAR(30) NOT NULL,
    nombre          VARCHAR(80) NOT NULL,
    descripcion     VARCHAR(200) NULL,
    modulo          VARCHAR(30) NOT NULL,
    activo          BIT NOT NULL DEFAULT 1,

    CONSTRAINT uq_permisos_codigo UNIQUE (codigo)
);

CREATE TABLE seg.rol_permiso (
    id_rol          INT NOT NULL,
    id_permiso      INT NOT NULL,
    created_at      DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT pk_rol_permiso PRIMARY KEY (id_rol, id_permiso),
    CONSTRAINT fk_rolpermiso_rol FOREIGN KEY (id_rol) REFERENCES seg.roles(id_rol),
    CONSTRAINT fk_rolpermiso_permiso FOREIGN KEY (id_permiso) REFERENCES seg.permisos(id_permiso)
);

CREATE TABLE seg.usuarios (
    id_usuario      INT IDENTITY(1,1) PRIMARY KEY,
    id_rol          INT NOT NULL,
    nombre          VARCHAR(100) NOT NULL,
    apellido        VARCHAR(100) NULL,
    usuario         VARCHAR(50) NOT NULL,
    email           VARCHAR(100) NULL,
    clave_hash      VARCHAR(255) NOT NULL,  -- Almacenar hash, NO texto plano
    telefono        VARCHAR(20) NULL,
    activo          BIT NOT NULL DEFAULT 1,
    ultimo_acceso   DATETIME2 NULL,
    created_at      DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    updated_at      DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT uq_usuarios_usuario UNIQUE (usuario),
    CONSTRAINT uq_usuarios_email UNIQUE (email),
    CONSTRAINT fk_usuarios_rol FOREIGN KEY (id_rol) REFERENCES seg.roles(id_rol)
);

CREATE INDEX ix_usuarios_activo ON seg.usuarios(activo) WHERE activo = 1;
GO

-- ============================================================
-- 4. TABLAS - NEGOCIO
-- ============================================================

CREATE TABLE negocio.proveedores (
    id_proveedor    INT IDENTITY(1,1) PRIMARY KEY,
    tipo_documento  VARCHAR(5) NOT NULL DEFAULT 'RUC',
    numero_documento VARCHAR(20) NOT NULL,
    nombre          VARCHAR(150) NOT NULL,
    nombre_comercial VARCHAR(150) NULL,
    telefono        VARCHAR(20) NULL,
    email           VARCHAR(100) NULL,
    direccion       VARCHAR(200) NULL,
    activo          BIT NOT NULL DEFAULT 1,
    created_at      DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    updated_at      DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT uq_proveedores_documento UNIQUE (tipo_documento, numero_documento),
    CONSTRAINT ck_proveedor_tipo_doc CHECK (tipo_documento IN ('RUC', 'DNI', 'CE'))
);

CREATE TABLE negocio.clientes (
    id_cliente      INT IDENTITY(1,1) PRIMARY KEY,
    tipo_documento  VARCHAR(5) NOT NULL DEFAULT 'DNI',
    numero_documento VARCHAR(20) NOT NULL,
    nombre          VARCHAR(120) NOT NULL,
    telefono        VARCHAR(20) NULL,
    email           VARCHAR(100) NULL,
    direccion       VARCHAR(200) NULL,
    fecha_registro  DATE NOT NULL DEFAULT CAST(SYSDATETIME() AS DATE),
    activo          BIT NOT NULL DEFAULT 1,
    created_at      DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    updated_at      DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT uq_clientes_documento UNIQUE (tipo_documento, numero_documento),
    CONSTRAINT ck_cliente_tipo_doc CHECK (tipo_documento IN ('DNI', 'CE', 'RUC', 'Pasaporte'))
);

CREATE INDEX ix_clientes_telefono ON negocio.clientes(telefono) WHERE telefono IS NOT NULL;
GO

-- ============================================================
-- 5. TABLAS - PRODUCTOS
-- ============================================================

CREATE TABLE producto.categorias (
    id_categoria    INT IDENTITY(1,1) PRIMARY KEY,
    nombre          VARCHAR(100) NOT NULL,
    descripcion     VARCHAR(200) NULL,
    activo          BIT NOT NULL DEFAULT 1,
    created_at      DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    updated_at      DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT uq_categorias_nombre UNIQUE (nombre)
);

-- Subcategorias para mejor organizacion
CREATE TABLE producto.subcategorias (
    id_subcategoria INT IDENTITY(1,1) PRIMARY KEY,
    id_categoria    INT NOT NULL,
    nombre          VARCHAR(100) NOT NULL,
    activo          BIT NOT NULL DEFAULT 1,

    CONSTRAINT fk_subcategoria_categoria FOREIGN KEY (id_categoria) REFERENCES producto.categorias(id_categoria),
    CONSTRAINT uq_subcategoria_nombre UNIQUE (id_categoria, nombre)
);

CREATE TABLE producto.unidades_medida (
    id_unidad       INT IDENTITY(1,1) PRIMARY KEY,
    nombre          VARCHAR(50) NOT NULL,
    abreviatura     VARCHAR(10) NOT NULL,
    tipo            VARCHAR(10) NOT NULL DEFAULT 'UNIDAD', -- UNIDAD, PESO, VOLUMEN

    CONSTRAINT uq_unidad_nombre UNIQUE (nombre),
    CONSTRAINT ck_unidad_tipo CHECK (tipo IN ('UNIDAD', 'PESO', 'VOLUMEN'))
);

-- Conversion entre unidades (ej: 1 kg = 1000 g)
CREATE TABLE producto.conversion_unidades (
    id_unidad_origen  INT NOT NULL,
    id_unidad_destino INT NOT NULL,
    factor            DECIMAL(10,4) NOT NULL,

    CONSTRAINT pk_conversion PRIMARY KEY (id_unidad_origen, id_unidad_destino),
    CONSTRAINT fk_conversion_origen FOREIGN KEY (id_unidad_origen) REFERENCES producto.unidades_medida(id_unidad),
    CONSTRAINT fk_conversion_destino FOREIGN KEY (id_unidad_destino) REFERENCES producto.unidades_medida(id_unidad),
    CONSTRAINT ck_conversion_factor CHECK (factor > 0)
);

CREATE TABLE producto.productos (
    id_producto     INT IDENTITY(1,1) PRIMARY KEY,
    id_categoria    INT NOT NULL,
    id_subcategoria INT NULL,
    id_unidad       INT NOT NULL,
    codigo_barras   VARCHAR(50) NULL,
    nombre          VARCHAR(120) NOT NULL,
    descripcion     VARCHAR(250) NULL,
    tipo            VARCHAR(10) NOT NULL,  -- INSUMO, VENTA, PRODUCIDO
    activo          BIT NOT NULL DEFAULT 1,
    created_at      DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    updated_at      DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT fk_productos_categoria FOREIGN KEY (id_categoria) REFERENCES producto.categorias(id_categoria),
    CONSTRAINT fk_productos_subcategoria FOREIGN KEY (id_subcategoria) REFERENCES producto.subcategorias(id_subcategoria),
    CONSTRAINT fk_productos_unidad FOREIGN KEY (id_unidad) REFERENCES producto.unidades_medida(id_unidad),
    CONSTRAINT ck_productos_tipo CHECK (tipo IN ('INSUMO', 'VENTA', 'PRODUCIDO')),
    CONSTRAINT uq_productos_codigo_barras UNIQUE (codigo_barras)
);

CREATE INDEX ix_productos_nombre ON producto.productos(nombre);
CREATE INDEX ix_productos_tipo ON producto.productos(tipo, activo);
GO

-- ============================================================
-- 6. TABLAS - RECETARIO (CORAZON DEL NEGOCIO DE COMIDA)
-- ============================================================
-- Convierte INSUMOS en PRODUCTOS VENTA/PRODUCIDO

CREATE TABLE produccion.recetas (
    id_receta       INT IDENTITY(1,1) PRIMARY KEY,
    id_producto     INT NOT NULL,          -- El producto final (plato/bebida)
    nombre          VARCHAR(120) NOT NULL,
    descripcion     VARCHAR(300) NULL,
    rendimiento     DECIMAL(10,2) NOT NULL DEFAULT 1, -- Ej: 1 plato, 10 porciones
    id_unidad       INT NOT NULL,          -- Unidad del rendimiento
    tiempo_prep_min INT NULL,              -- Tiempo de preparacion en minutos
    costo_total     DECIMAL(10,2) NOT NULL DEFAULT 0,
    activo          BIT NOT NULL DEFAULT 1,
    created_at      DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    updated_at      DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT fk_recetas_producto FOREIGN KEY (id_producto) REFERENCES producto.productos(id_producto),
    CONSTRAINT fk_recetas_unidad FOREIGN KEY (id_unidad) REFERENCES producto.unidades_medida(id_unidad),
    CONSTRAINT uq_recetas_producto UNIQUE (id_producto)
);

CREATE TABLE produccion.detalle_receta (
    id_detalle_receta INT IDENTITY(1,1) PRIMARY KEY,
    id_receta       INT NOT NULL,
    id_producto     INT NOT NULL,          -- El INSUMO que se usa
    cantidad        DECIMAL(10,2) NOT NULL,
    id_unidad       INT NOT NULL,          -- Unidad del insumo
    merma_porcentaje DECIMAL(5,2) NOT NULL DEFAULT 0, -- % que se pierde al cocinar
    costo_estimado  DECIMAL(10,2) NOT NULL DEFAULT 0,

    CONSTRAINT fk_detreceta_receta FOREIGN KEY (id_receta) REFERENCES produccion.recetas(id_receta),
    CONSTRAINT fk_detreceta_producto FOREIGN KEY (id_producto) REFERENCES producto.productos(id_producto),
    CONSTRAINT fk_detreceta_unidad FOREIGN KEY (id_unidad) REFERENCES producto.unidades_medida(id_unidad),
    CONSTRAINT ck_detreceta_cantidad CHECK (cantidad > 0),
    CONSTRAINT ck_detreceta_merma CHECK (merma_porcentaje >= 0 AND merma_porcentaje < 100)
);

CREATE INDEX ix_detreceta_receta ON produccion.detalle_receta(id_receta);
GO

-- ============================================================
-- 7. TABLAS - PRECIOS E HISTORIAL
-- ============================================================

CREATE TABLE producto.precios (
    id_precio       INT IDENTITY(1,1) PRIMARY KEY,
    id_producto     INT NOT NULL,
    precio_venta    DECIMAL(10,2) NOT NULL DEFAULT 0,
    costo_promedio  DECIMAL(10,2) NOT NULL DEFAULT 0,
    fecha_inicio    DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    fecha_fin       DATETIME2 NULL,
    activo          BIT NOT NULL DEFAULT 1,

    CONSTRAINT fk_precios_producto FOREIGN KEY (id_producto) REFERENCES producto.productos(id_producto),
    CONSTRAINT ck_precio_venta CHECK (precio_venta >= 0),
    CONSTRAINT ck_precio_costo CHECK (costo_promedio >= 0)
);

CREATE INDEX ix_precios_producto ON producto.precios(id_producto, activo) WHERE activo = 1;
GO

-- ============================================================
-- 8. TABLAS - INVENTARIO Y STOCK
-- ============================================================

-- Lotes para control FIFO
CREATE TABLE inventario.lotes (
    id_lote         INT IDENTITY(1,1) PRIMARY KEY,
    id_producto     INT NOT NULL,
    codigo_lote     VARCHAR(50) NOT NULL,
    cantidad_inicial DECIMAL(10,2) NOT NULL,
    cantidad_actual DECIMAL(10,2) NOT NULL,
    costo_unitario  DECIMAL(10,2) NOT NULL DEFAULT 0,
    fecha_produccion DATE NULL,
    fecha_vencimiento DATE NULL,
    activo          BIT NOT NULL DEFAULT 1,
    created_at      DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT fk_lotes_producto FOREIGN KEY (id_producto) REFERENCES producto.productos(id_producto),
    CONSTRAINT uq_lotes_codigo UNIQUE (codigo_lote),
    CONSTRAINT ck_lote_cantidad CHECK (cantidad_actual >= 0)
);

CREATE INDEX ix_lotes_producto ON inventario.lotes(id_producto, activo);
CREATE INDEX ix_lotes_vencimiento ON inventario.lotes(fecha_vencimiento) WHERE fecha_vencimiento IS NOT NULL;
GO

CREATE TABLE inventario.stock (
    id_stock        INT IDENTITY(1,1) PRIMARY KEY,
    id_producto     INT NOT NULL,
    id_lote         INT NULL,
    cantidad        DECIMAL(10,2) NOT NULL DEFAULT 0,
    stock_minimo    DECIMAL(10,2) NOT NULL DEFAULT 0,
    ubicacion       VARCHAR(50) NULL,      -- Ej: "Congelador 1", "Estante A3"

    CONSTRAINT fk_stock_producto FOREIGN KEY (id_producto) REFERENCES producto.productos(id_producto),
    CONSTRAINT fk_stock_lote FOREIGN KEY (id_lote) REFERENCES inventario.lotes(id_lote),
    CONSTRAINT uq_stock_producto UNIQUE (id_producto),
    CONSTRAINT ck_stock_cantidad CHECK (cantidad >= 0),
    CONSTRAINT ck_stock_minimo CHECK (stock_minimo >= 0)
);

CREATE TABLE inventario.movimientos (
    id_movimiento   INT IDENTITY(1,1) PRIMARY KEY,
    id_producto     INT NOT NULL,
    id_lote         INT NULL,
    id_usuario      INT NOT NULL,
    tipo_movimiento VARCHAR(20) NOT NULL,
    motivo          VARCHAR(100) NOT NULL,
    cantidad        DECIMAL(10,2) NOT NULL,
    stock_anterior  DECIMAL(10,2) NOT NULL,
    stock_nuevo     DECIMAL(10,2) NOT NULL,
    costo_unitario  DECIMAL(10,2) NULL,
    id_referencia   INT NULL,              -- ID de compra/venta/produccion
    tipo_referencia VARCHAR(20) NULL,      -- COMPRA, VENTA, PRODUCCION, AJUSTE
    observacion     VARCHAR(300) NULL,
    fecha           DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT fk_movimientos_producto FOREIGN KEY (id_producto) REFERENCES producto.productos(id_producto),
    CONSTRAINT fk_movimientos_lote FOREIGN KEY (id_lote) REFERENCES inventario.lotes(id_lote),
    CONSTRAINT fk_movimientos_usuario FOREIGN KEY (id_usuario) REFERENCES seg.usuarios(id_usuario),
    CONSTRAINT ck_movimiento_tipo CHECK (tipo_movimiento IN ('ENTRADA', 'SALIDA', 'AJUSTE'))
);

CREATE INDEX ix_movimientos_producto ON inventario.movimientos(id_producto, fecha DESC);
CREATE INDEX ix_movimientos_fecha ON inventario.movimientos(fecha DESC);
CREATE INDEX ix_movimientos_referencia ON inventario.movimientos(tipo_referencia, id_referencia);
GO

-- ============================================================
-- 9. TABLAS - COMPRAS
-- ============================================================

CREATE TABLE compra.compras (
    id_compra       INT IDENTITY(1,1) PRIMARY KEY,
    id_proveedor    INT NOT NULL,
    id_usuario      INT NOT NULL,
    tipo_comprobante VARCHAR(20) NOT NULL DEFAULT 'FACTURA',
    serie_comprobante VARCHAR(10) NULL,
    numero_comprobante VARCHAR(20) NULL,
    fecha_emision   DATE NOT NULL DEFAULT CAST(SYSDATETIME() AS DATE),
    fecha_recepcion DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    subtotal        DECIMAL(10,2) NOT NULL,
    impuesto        DECIMAL(10,2) NOT NULL DEFAULT 0,
    total           DECIMAL(10,2) NOT NULL,
    observacion     VARCHAR(300) NULL,
    estado          VARCHAR(20) NOT NULL DEFAULT 'REGISTRADA',
    created_at      DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    updated_at      DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT fk_compras_proveedor FOREIGN KEY (id_proveedor) REFERENCES negocio.proveedores(id_proveedor),
    CONSTRAINT fk_compras_usuario FOREIGN KEY (id_usuario) REFERENCES seg.usuarios(id_usuario),
    CONSTRAINT ck_compra_estado CHECK (estado IN ('REGISTRADA', 'COMPLETADA', 'ANULADA')),
    CONSTRAINT ck_compra_total CHECK (total >= 0)
);

CREATE TABLE compra.detalle_compra (
    id_detalle_compra INT IDENTITY(1,1) PRIMARY KEY,
    id_compra       INT NOT NULL,
    id_producto     INT NOT NULL,
    id_lote         INT NULL,
    cantidad        DECIMAL(10,2) NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    subtotal        DECIMAL(10,2) NOT NULL,

    CONSTRAINT fk_detcompra_compra FOREIGN KEY (id_compra) REFERENCES compra.compras(id_compra),
    CONSTRAINT fk_detcompra_producto FOREIGN KEY (id_producto) REFERENCES producto.productos(id_producto),
    CONSTRAINT fk_detcompra_lote FOREIGN KEY (id_lote) REFERENCES inventario.lotes(id_lote),
    CONSTRAINT ck_detcompra_cantidad CHECK (cantidad > 0)
);

CREATE INDEX ix_detcompra_compra ON compra.detalle_compra(id_compra);
GO

-- ============================================================
-- 10. TABLAS - VENTAS Y PEDIDOS
-- ============================================================

-- Mesas para atencion en el mercado
CREATE TABLE venta.mesas (
    id_mesa         INT IDENTITY(1,1) PRIMARY KEY,
    numero          INT NOT NULL,
    capacidad       INT NOT NULL DEFAULT 4,
    ubicacion       VARCHAR(50) NULL,
    estado          VARCHAR(20) NOT NULL DEFAULT 'DISPONIBLE',
    activo          BIT NOT NULL DEFAULT 1,

    CONSTRAINT uq_mesa_numero UNIQUE (numero),
    CONSTRAINT ck_mesa_estado CHECK (estado IN ('DISPONIBLE', 'OCUPADA', 'RESERVADA'))
);

CREATE TABLE venta.ventas (
    id_venta        INT IDENTITY(1,1) PRIMARY KEY,
    id_cliente      INT NULL,
    id_usuario      INT NOT NULL,
    id_mesa         INT NULL,
    tipo_comprobante VARCHAR(20) NOT NULL DEFAULT 'BOLETA',
    serie_comprobante VARCHAR(10) NULL,
    numero_comprobante VARCHAR(20) NULL,
    fecha           DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    subtotal        DECIMAL(10,2) NOT NULL,
    impuesto        DECIMAL(10,2) NOT NULL DEFAULT 0,
    descuento       DECIMAL(10,2) NOT NULL DEFAULT 0,
    total           DECIMAL(10,2) NOT NULL,
    estado          VARCHAR(20) NOT NULL DEFAULT 'PAGADA',
    created_at      DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    updated_at      DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT fk_ventas_cliente FOREIGN KEY (id_cliente) REFERENCES negocio.clientes(id_cliente),
    CONSTRAINT fk_ventas_usuario FOREIGN KEY (id_usuario) REFERENCES seg.usuarios(id_usuario),
    CONSTRAINT fk_ventas_mesa FOREIGN KEY (id_mesa) REFERENCES venta.mesas(id_mesa),
    CONSTRAINT ck_venta_estado CHECK (estado IN ('PENDIENTE', 'PAGADA', 'ANULADA', 'FACTURADA')),
    CONSTRAINT ck_venta_total CHECK (total >= 0)
);

CREATE INDEX ix_ventas_fecha ON venta.ventas(fecha DESC);
CREATE INDEX ix_ventas_cliente ON venta.ventas(id_cliente);
GO

CREATE TABLE venta.detalle_venta (
    id_detalle_venta INT IDENTITY(1,1) PRIMARY KEY,
    id_venta        INT NOT NULL,
    id_producto     INT NOT NULL,
    cantidad        DECIMAL(10,2) NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    subtotal        DECIMAL(10,2) NOT NULL,
    observacion     VARCHAR(200) NULL,     -- Ej: "sin sal", "bien cocido"

    CONSTRAINT fk_detventa_venta FOREIGN KEY (id_venta) REFERENCES venta.ventas(id_venta),
    CONSTRAINT fk_detventa_producto FOREIGN KEY (id_producto) REFERENCES producto.productos(id_producto),
    CONSTRAINT ck_detventa_cantidad CHECK (cantidad > 0)
);

CREATE INDEX ix_detventa_venta ON venta.detalle_venta(id_venta);
GO

-- ============================================================
-- 11. TABLAS - PEDIDOS (DELIVERY / RECOJO)
-- ============================================================

CREATE TABLE venta.tipo_pedido (
    id_tipo_pedido  INT IDENTITY(1,1) PRIMARY KEY,
    nombre          VARCHAR(30) NOT NULL,
    activo          BIT NOT NULL DEFAULT 1,

    CONSTRAINT uq_tipopedido_nombre UNIQUE (nombre)
);

CREATE TABLE venta.pedidos (
    id_pedido       INT IDENTITY(1,1) PRIMARY KEY,
    id_cliente      INT NULL,
    id_usuario      INT NOT NULL,
    id_tipo_pedido  INT NOT NULL,
    fecha           DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    estado          VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    direccion_entrega VARCHAR(200) NULL,
    telefono_contacto VARCHAR(20) NULL,
    hora_programada TIME NULL,
    subtotal        DECIMAL(10,2) NOT NULL,
    impuesto        DECIMAL(10,2) NOT NULL DEFAULT 0,
    total           DECIMAL(10,2) NOT NULL,
    created_at      DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    updated_at      DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT fk_pedidos_cliente FOREIGN KEY (id_cliente) REFERENCES negocio.clientes(id_cliente),
    CONSTRAINT fk_pedidos_usuario FOREIGN KEY (id_usuario) REFERENCES seg.usuarios(id_usuario),
    CONSTRAINT fk_pedidos_tipo FOREIGN KEY (id_tipo_pedido) REFERENCES venta.tipo_pedido(id_tipo_pedido),
    CONSTRAINT ck_pedido_estado CHECK (estado IN ('PENDIENTE', 'EN_COCINA', 'LISTO', 'ENTREGADO', 'ANULADO')),
    CONSTRAINT ck_pedido_total CHECK (total >= 0)
);

CREATE INDEX ix_pedidos_estado ON venta.pedidos(estado, fecha);
GO

CREATE TABLE venta.detalle_pedido (
    id_detalle_pedido INT IDENTITY(1,1) PRIMARY KEY,
    id_pedido       INT NOT NULL,
    id_producto     INT NOT NULL,
    cantidad        DECIMAL(10,2) NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    subtotal        DECIMAL(10,2) NOT NULL,
    observacion     VARCHAR(200) NULL,

    CONSTRAINT fk_detpedido_pedido FOREIGN KEY (id_pedido) REFERENCES venta.pedidos(id_pedido),
    CONSTRAINT fk_detpedido_producto FOREIGN KEY (id_producto) REFERENCES producto.productos(id_producto),
    CONSTRAINT ck_detpedido_cantidad CHECK (cantidad > 0)
);

CREATE INDEX ix_detpedido_pedido ON venta.detalle_pedido(id_pedido);
GO

-- ============================================================
-- 12. TABLAS - PAGOS
-- ============================================================

CREATE TABLE financiero.metodos_pago (
    id_metodo_pago  INT IDENTITY(1,1) PRIMARY KEY,
    nombre          VARCHAR(50) NOT NULL,
    requiere_referencia BIT NOT NULL DEFAULT 0,
    activo          BIT NOT NULL DEFAULT 1,

    CONSTRAINT uq_metodopago_nombre UNIQUE (nombre)
);

CREATE TABLE venta.pagos_venta (
    id_pago_venta   INT IDENTITY(1,1) PRIMARY KEY,
    id_venta        INT NOT NULL,
    id_metodo_pago  INT NOT NULL,
    monto           DECIMAL(10,2) NOT NULL,
    referencia      VARCHAR(100) NULL,     -- Numero de voucher, YAPE, etc.
    fecha           DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT fk_pagosventa_venta FOREIGN KEY (id_venta) REFERENCES venta.ventas(id_venta),
    CONSTRAINT fk_pagosventa_metodo FOREIGN KEY (id_metodo_pago) REFERENCES financiero.metodos_pago(id_metodo_pago),
    CONSTRAINT ck_pago_venta_monto CHECK (monto > 0)
);

CREATE TABLE venta.pagos_pedido (
    id_pago_pedido  INT IDENTITY(1,1) PRIMARY KEY,
    id_pedido       INT NOT NULL,
    id_metodo_pago  INT NOT NULL,
    monto           DECIMAL(10,2) NOT NULL,
    referencia      VARCHAR(100) NULL,
    fecha           DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT fk_pagospedido_pedido FOREIGN KEY (id_pedido) REFERENCES venta.pedidos(id_pedido),
    CONSTRAINT fk_pagospedido_metodo FOREIGN KEY (id_metodo_pago) REFERENCES financiero.metodos_pago(id_metodo_pago),
    CONSTRAINT ck_pago_pedido_monto CHECK (monto > 0)
);
GO

-- ============================================================
-- 13. TABLAS - PRODUCCION (COCINA)
-- ============================================================

CREATE TABLE produccion.ordenes_produccion (
    id_orden        INT IDENTITY(1,1) PRIMARY KEY,
    id_receta       INT NOT NULL,
    id_usuario      INT NOT NULL,
    cantidad_producir DECIMAL(10,2) NOT NULL,
    cantidad_real   DECIMAL(10,2) NULL,
    estado          VARCHAR(20) NOT NULL DEFAULT 'PLANIFICADA',
    fecha_inicio    DATETIME2 NULL,
    fecha_fin       DATETIME2 NULL,
    created_at      DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT fk_ordenprod_receta FOREIGN KEY (id_receta) REFERENCES produccion.recetas(id_receta),
    CONSTRAINT fk_ordenprod_usuario FOREIGN KEY (id_usuario) REFERENCES seg.usuarios(id_usuario),
    CONSTRAINT ck_ordenprod_estado CHECK (estado IN ('PLANIFICADA', 'EN_PROCESO', 'COMPLETADA', 'CANCELADA')),
    CONSTRAINT ck_ordenprod_cantidad CHECK (cantidad_producir > 0)
);

CREATE TABLE produccion.detalle_orden_produccion (
    id_detalle_orden INT IDENTITY(1,1) PRIMARY KEY,
    id_orden        INT NOT NULL,
    id_producto     INT NOT NULL,
    cantidad_requerida DECIMAL(10,2) NOT NULL,
    cantidad_usada  DECIMAL(10,2) NULL,
    id_lote         INT NULL,

    CONSTRAINT fk_detorden_orden FOREIGN KEY (id_orden) REFERENCES produccion.ordenes_produccion(id_orden),
    CONSTRAINT fk_detorden_producto FOREIGN KEY (id_producto) REFERENCES producto.productos(id_producto),
    CONSTRAINT fk_detorden_lote FOREIGN KEY (id_lote) REFERENCES inventario.lotes(id_lote)
);
GO

-- ============================================================
-- 14. TABLAS - CAJA
-- ============================================================

CREATE TABLE financiero.cajas (
    id_caja         INT IDENTITY(1,1) PRIMARY KEY,
    id_usuario      INT NOT NULL,
    fecha_apertura  DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    fecha_cierre    DATETIME2 NULL,
    monto_inicial   DECIMAL(10,2) NOT NULL DEFAULT 0,
    monto_final     DECIMAL(10,2) NULL,
    total_ventas    DECIMAL(10,2) NOT NULL DEFAULT 0,
    total_efectivo  DECIMAL(10,2) NOT NULL DEFAULT 0,
    total_tarjeta   DECIMAL(10,2) NOT NULL DEFAULT 0,
    total_digital   DECIMAL(10,2) NOT NULL DEFAULT 0,
    diferencia      DECIMAL(10,2) NULL,
    estado          VARCHAR(20) NOT NULL DEFAULT 'ABIERTA',
    observacion_cierre VARCHAR(300) NULL,
    created_at      DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT fk_cajas_usuario FOREIGN KEY (id_usuario) REFERENCES seg.usuarios(id_usuario),
    CONSTRAINT ck_caja_estado CHECK (estado IN ('ABIERTA', 'CERRADA'))
);

CREATE INDEX ix_cajas_usuario ON financiero.cajas(id_usuario, fecha_apertura DESC);
GO

-- ============================================================
-- 15. AUDITORIA
-- ============================================================

CREATE TABLE auditoria.log_cambios (
    id_log          BIGINT IDENTITY(1,1) PRIMARY KEY,
    id_usuario      INT NULL,
    tabla           VARCHAR(100) NOT NULL,
    id_registro     INT NOT NULL,
    accion          VARCHAR(20) NOT NULL,  -- INSERT, UPDATE, DELETE
    valores_anteriores VARCHAR(MAX) NULL,
    valores_nuevos  VARCHAR(MAX) NULL,
    ip_address      VARCHAR(45) NULL,
    fecha           DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);

CREATE INDEX ix_log_fecha ON auditoria.log_cambios(fecha DESC);
CREATE INDEX ix_log_tabla ON auditoria.log_cambios(tabla, id_registro);
GO

-- ============================================================
-- 16. VISTAS - REPORTES
-- ============================================================

-- Vista de inventario actual con alertas
CREATE VIEW reporte.vw_inventario_actual AS
SELECT
    p.id_producto,
    p.nombre AS producto,
    c.nombre AS categoria,
    sc.nombre AS subcategoria,
    u.abreviatura AS unidad,
    ISNULL(s.cantidad, 0) AS stock_actual,
    s.stock_minimo,
    CASE
        WHEN ISNULL(s.cantidad, 0) <= 0 THEN 'SIN_STOCK'
        WHEN ISNULL(s.cantidad, 0) <= s.stock_minimo THEN 'BAJO'
        ELSE 'NORMAL'
    END AS nivel_stock,
    p.tipo,
    pr.precio_venta,
    pr.costo_promedio
FROM producto.productos p
INNER JOIN producto.categorias c ON c.id_categoria = p.id_categoria
LEFT JOIN producto.subcategorias sc ON sc.id_subcategoria = p.id_subcategoria
INNER JOIN producto.unidades_medida u ON u.id_unidad = p.id_unidad
LEFT JOIN inventario.stock s ON s.id_producto = p.id_producto
LEFT JOIN producto.precios pr ON pr.id_producto = p.id_producto AND pr.activo = 1
WHERE p.activo = 1;
GO

-- Vista de costos de recetas
CREATE VIEW reporte.vw_costos_recetas AS
SELECT
    r.id_receta,
    r.nombre AS receta,
    p.nombre AS producto_final,
    r.rendimiento,
    u.abreviatura AS unidad_rendimiento,
    r.costo_total,
    (r.costo_total / NULLIF(r.rendimiento, 0)) AS costo_unitario,
    pr.precio_venta,
    (pr.precio_venta - (r.costo_total / NULLIF(r.rendimiento, 0))) AS margen_ganancia,
    CASE WHEN pr.precio_venta > 0 THEN
        ((pr.precio_venta - (r.costo_total / NULLIF(r.rendimiento, 0))) / pr.precio_venta) * 100
    ELSE 0 END AS margen_porcentaje
FROM produccion.recetas r
INNER JOIN producto.productos p ON p.id_producto = r.id_producto
INNER JOIN producto.unidades_medida u ON u.id_unidad = r.id_unidad
LEFT JOIN producto.precios pr ON pr.id_producto = p.id_producto AND pr.activo = 1;
GO

-- Vista de ventas del dia
CREATE VIEW reporte.vw_ventas_diarias AS
SELECT
    CAST(fecha AS DATE) AS fecha,
    COUNT(*) AS total_ventas,
    SUM(total) AS monto_total,
    AVG(total) AS ticket_promedio,
    SUM(descuento) AS total_descuentos
FROM venta.ventas
WHERE estado NOT IN ('ANULADA')
GROUP BY CAST(fecha AS DATE);
GO

-- Vista de productos mas vendidos
CREATE VIEW reporte.vw_productos_top AS
SELECT
    p.id_producto,
    p.nombre AS producto,
    c.nombre AS categoria,
    SUM(dv.cantidad) AS cantidad_vendida,
    SUM(dv.subtotal) AS total_vendido,
    COUNT(DISTINCT dv.id_venta) AS veces_vendido
FROM venta.detalle_venta dv
INNER JOIN producto.productos p ON p.id_producto = dv.id_producto
INNER JOIN producto.categorias c ON c.id_categoria = p.id_categoria
INNER JOIN venta.ventas v ON v.id_venta = dv.id_venta AND v.estado NOT IN ('ANULADA')
GROUP BY p.id_producto, p.nombre, c.nombre;
GO

-- Vista de rentabilidad por producto
CREATE VIEW reporte.vw_rentabilidad AS
SELECT
    p.id_producto,
    p.nombre,
    p.tipo,
    pr.precio_venta,
    pr.costo_promedio,
    (pr.precio_venta - pr.costo_promedio) AS ganancia_unitaria,
    CASE WHEN pr.precio_venta > 0 THEN
        ((pr.precio_venta - pr.costo_promedio) / pr.precio_venta) * 100
    ELSE 0 END AS margen_porcentaje,
    s.cantidad AS stock_actual
FROM producto.productos p
LEFT JOIN producto.precios pr ON pr.id_producto = p.id_producto AND pr.activo = 1
LEFT JOIN inventario.stock s ON s.id_producto = p.id_producto
WHERE p.activo = 1;
GO

-- ============================================================
-- 17. DATOS INICIALES
-- ============================================================

-- Roles
INSERT INTO seg.roles (nombre, descripcion, es_sistema) VALUES
('ADMINISTRADOR', 'Acceso total al sistema', 1),
('CAJERO', 'Ventas, pedidos y caja', 0),
('ALMACENERO', 'Compras e inventario', 0),
('COCINA', 'Gestion de pedidos y produccion', 0);

-- Permisos
INSERT INTO seg.permisos (codigo, nombre, descripcion, modulo) VALUES
('USR_VIEW',    'Ver usuarios',     'Visualizar lista de usuarios',      'SEGURIDAD'),
('USR_EDIT',    'Editar usuarios',  'Crear y modificar usuarios',        'SEGURIDAD'),
('PROD_VIEW',   'Ver productos',    'Visualizar catalogo',               'PRODUCTOS'),
('PROD_EDIT',   'Editar productos', 'Crear y modificar productos',       'PRODUCTOS'),
('COMP_VIEW',   'Ver compras',      'Visualizar compras',                'COMPRAS'),
('COMP_EDIT',   'Registrar compras','Crear compras',                     'COMPRAS'),
('VENT_VIEW',   'Ver ventas',       'Visualizar ventas',                 'VENTAS'),
('VENT_EDIT',   'Registrar ventas', 'Crear ventas',                      'VENTAS'),
('PED_VIEW',    'Ver pedidos',      'Visualizar pedidos',                'PEDIDOS'),
('PED_EDIT',    'Gestionar pedidos','Crear y cambiar estado pedidos',    'PEDIDOS'),
('INV_VIEW',    'Ver inventario',   'Visualizar stock',                  'INVENTARIO'),
('INV_EDIT',    'Ajustar stock',    'Realizar ajustes de inventario',    'INVENTARIO'),
('RPT_VIEW',    'Ver reportes',     'Acceder a reportes',                'REPORTES'),
('CAJA_VIEW',   'Ver caja',         'Visualizar movimientos de caja',    'CAJA'),
('CAJA_EDIT',   'Abrir/cerrar caja','Gestionar apertura y cierre',       'CAJA'),
('REC_VIEW',    'Ver recetas',      'Visualizar recetario',              'PRODUCCION'),
('REC_EDIT',    'Editar recetas',   'Crear y modificar recetas',         'PRODUCCION');

-- Asignar permisos a roles
-- ADMINISTRADOR (todos)
INSERT INTO seg.rol_permiso (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso FROM seg.roles r CROSS JOIN seg.permisos p WHERE r.nombre = 'ADMINISTRADOR';

-- CAJERO
INSERT INTO seg.rol_permiso (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso FROM seg.roles r INNER JOIN seg.permisos p ON 1=1
WHERE r.nombre = 'CAJERO' AND p.codigo IN ('PROD_VIEW','VENT_VIEW','VENT_EDIT','PED_VIEW','PED_EDIT','CAJA_VIEW','CAJA_EDIT','RPT_VIEW');

-- ALMACENERO
INSERT INTO seg.rol_permiso (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso FROM seg.roles r INNER JOIN seg.permisos p ON 1=1
WHERE r.nombre = 'ALMACENERO' AND p.codigo IN ('PROD_VIEW','PROD_EDIT','COMP_VIEW','COMP_EDIT','INV_VIEW','INV_EDIT','RPT_VIEW');

-- COCINA
INSERT INTO seg.rol_permiso (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso FROM seg.roles r INNER JOIN seg.permisos p ON 1=1
WHERE r.nombre = 'COCINA' AND p.codigo IN ('PED_VIEW','PED_EDIT','REC_VIEW','REC_EDIT');

-- Usuario admin (clave: admin123 - CAMBIAR en produccion)
INSERT INTO seg.usuarios (id_rol, nombre, apellido, usuario, clave_hash, telefono)
VALUES (1, 'Administrador', 'Principal', 'admin',
        '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', -- hash de 'password'
        '999999999');

-- Unidades de medida
INSERT INTO producto.unidades_medida (nombre, abreviatura, tipo) VALUES
('Unidad',       'und',  'UNIDAD'),
('Kilogramo',    'kg',   'PESO'),
('Gramo',        'g',    'PESO'),
('Litro',        'lt',   'VOLUMEN'),
('Mililitro',    'ml',   'VOLUMEN'),
('Paquete',      'paq',  'UNIDAD'),
('Docena',       'doc',  'UNIDAD'),
('Porcion',      'porc', 'UNIDAD');

-- Conversion de unidades
INSERT INTO producto.conversion_unidades (id_unidad_origen, id_unidad_destino, factor) VALUES
(2, 3, 1000.0000),  -- 1 kg = 1000 g
(3, 2, 0.0010),     -- 1 g = 0.001 kg
(4, 5, 1000.0000),  -- 1 lt = 1000 ml
(5, 4, 0.0010);     -- 1 ml = 0.001 lt

-- Categorias
INSERT INTO producto.categorias (nombre, descripcion) VALUES
('Verduras y Hortalizas', 'Insumos vegetales para cocina'),
('Carnes y Aves',         'Carnes rojas, pollo y otros'),
('Abarrotes',             'Productos secos no perecibles'),
('Lacteos y Huevos',      'Lacteos, quesos, huevos'),
('Bebidas',               'Gaseosas, jugos, aguas'),
('Platos de Fondo',       'Platos preparados para venta'),
('Entradas',              'Entradas y sopas'),
('Combos',                'Promociones y combos'),
('Postres',               'Dulces y postres');

-- Subcategorias
INSERT INTO producto.subcategorias (id_categoria, nombre) VALUES
(1, 'Tubérculos'),    (1, 'Hojas Verdes'),  (1, 'Legumbres'),
(2, 'Pollo'),          (2, 'Carne de Res'),  (2, 'Cerdo'),
(3, 'Arroz'),          (3, 'Fideos'),        (3, 'Condimentos'), (3, 'Enlatados'),
(4, 'Huevos'),         (4, 'Quesos'),
(5, 'Gaseosas'),       (5, 'Jugos Naturales'), (5, 'Aguas'), (5, 'Café y Té'),
(6, 'Pollo'),          (6, 'Pescado'),       (6, 'Carnes'),
(9, 'Caseros'),        (9, 'Helados');

-- Metodos de pago
INSERT INTO financiero.metodos_pago (nombre, requiere_referencia) VALUES
('EFECTIVO',    0),
('TARJETA',     1),
('TRANSFERENCIA',1),
('YAPE',        1),
('PLIN',        1);

-- Tipos de pedido
INSERT INTO venta.tipo_pedido (nombre) VALUES
('LOCAL'), ('DELIVERY'), ('RECOJO');

-- Mesas (mercado tipico: 8-12 mesas)
INSERT INTO venta.mesas (numero, capacidad, ubicacion) VALUES
(1, 4, 'Interior 1'),  (2, 4, 'Interior 2'),
(3, 4, 'Interior 3'),  (4, 2, 'Interior 4'),
(5, 4, 'Interior 5'),  (6, 4, 'Ventana 1'),
(7, 2, 'Ventana 2'),   (8, 6, 'Terraza');

-- Proveedor general
INSERT INTO negocio.proveedores (tipo_documento, numero_documento, nombre, telefono, direccion)
VALUES ('RUC', '00000000000', 'Proveedor General', '900000000', 'Mercado Central');

-- Cliente general
INSERT INTO negocio.clientes (tipo_documento, numero_documento, nombre, telefono)
VALUES ('DNI', '00000000', 'Cliente General', '');

GO

-- ============================================================
-- 18. STORED PROCEDURES
-- ============================================================

-- Procedimiento: Registrar venta con descuento automatico de stock
CREATE PROCEDURE venta.sp_registrar_venta
    @id_cliente     INT,
    @id_usuario     INT,
    @id_mesa        INT = NULL,
    @tipo_comprobante VARCHAR(20) = 'BOLETA',
    @productos      NVARCHAR(MAX)  -- JSON: [{id_producto, cantidad, precio_unitario, observacion}]
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @id_venta INT;
        DECLARE @subtotal DECIMAL(10,2) = 0;
        DECLARE @impuesto DECIMAL(10,2) = 0;
        DECLARE @total DECIMAL(10,2) = 0;

        -- Insertar venta
        INSERT INTO venta.ventas (id_cliente, id_usuario, id_mesa, tipo_comprobante, subtotal, impuesto, total)
        VALUES (@id_cliente, @id_usuario, @id_mesa, @tipo_comprobante, 0, 0, 0);

        SET @id_venta = SCOPE_IDENTITY();

        -- Procesar productos (JSON)
        -- NOTA: El parseo JSON requiere SQL Server 2016+
        INSERT INTO venta.detalle_venta (id_venta, id_producto, cantidad, precio_unitario, subtotal, observacion)
        SELECT
            @id_venta,
            JSON_VALUE(p.value, '$.id_producto'),
            JSON_VALUE(p.value, '$.cantidad'),
            JSON_VALUE(p.value, '$.precio_unitario'),
            JSON_VALUE(p.value, '$.cantidad') * JSON_VALUE(p.value, '$.precio_unitario'),
            JSON_VALUE(p.value, '$.observacion')
        FROM OPENJSON(@productos) AS p;

        -- Calcular totales
        SELECT @subtotal = SUM(subtotal) FROM venta.detalle_venta WHERE id_venta = @id_venta;
        SET @impuesto = @subtotal * 0.18;  -- IGV Peru
        SET @total = @subtotal + @impuesto;

        UPDATE venta.ventas
        SET subtotal = @subtotal, impuesto = @impuesto, total = @total
        WHERE id_venta = @id_venta;

        -- Descontar stock de productos VENTA y PRODUCIDO
        -- (los INSUMO se descuentan via receta en produccion)
        UPDATE s
        SET s.cantidad = s.cantidad - dv.cantidad
        FROM inventario.stock s
        INNER JOIN venta.detalle_venta dv ON dv.id_producto = s.id_producto AND dv.id_venta = @id_venta
        INNER JOIN producto.productos p ON p.id_producto = s.id_producto
        WHERE p.tipo IN ('VENTA', 'PRODUCIDO');

        COMMIT TRANSACTION;
        SELECT @id_venta AS id_venta, @total AS total;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- Procedimiento: Registrar produccion (cocina)
CREATE PROCEDURE produccion.sp_registrar_produccion
    @id_receta      INT,
    @id_usuario     INT,
    @cantidad       DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @id_producto INT;
        DECLARE @id_orden INT;
        DECLARE @costo_total DECIMAL(10,2) = 0;
        DECLARE @costo_unitario DECIMAL(10,2);

        -- Obtener el producto de la receta
        SELECT @id_producto = id_producto FROM produccion.recetas WHERE id_receta = @id_receta;

        -- Crear orden de produccion
        INSERT INTO produccion.ordenes_produccion (id_receta, id_usuario, cantidad_producir, estado, fecha_inicio)
        VALUES (@id_receta, @id_usuario, @cantidad, 'EN_PROCESO', SYSDATETIME());

        SET @id_orden = SCOPE_IDENTITY();

        -- Registrar consumo de insumos y descontar stock
        INSERT INTO produccion.detalle_orden_produccion (id_orden, id_producto, cantidad_requerida, cantidad_usada)
        SELECT
            @id_orden,
            dr.id_producto,
            dr.cantidad * @cantidad / r.rendimiento,
            dr.cantidad * @cantidad / r.rendimiento
        FROM produccion.detalle_receta dr
        INNER JOIN produccion.recetas r ON r.id_receta = dr.id_receta
        WHERE dr.id_receta = @id_receta;

        -- Descontar insumos del stock
        UPDATE s
        SET s.cantidad = s.cantidad - dop.cantidad_usada
        FROM inventario.stock s
        INNER JOIN produccion.detalle_orden_produccion dop ON dop.id_producto = s.id_producto AND dop.id_orden = @id_orden;

        -- Calcular costo total
        SELECT @costo_total = SUM(dr.costo_estimado * @cantidad / r.rendimiento)
        FROM produccion.detalle_receta dr
        INNER JOIN produccion.recetas r ON r.id_receta = dr.id_receta
        WHERE dr.id_receta = @id_receta;

        -- Actualizar costo en la receta
        UPDATE produccion.recetas SET costo_total = @costo_total WHERE id_receta = @id_receta;

        -- Sumar stock del producto producido
        MERGE inventario.stock AS target
        USING (SELECT @id_producto AS id_producto) AS source
        ON target.id_producto = source.id_producto
        WHEN MATCHED THEN
            UPDATE SET cantidad = cantidad + @cantidad
        WHEN NOT MATCHED THEN
            INSERT (id_producto, cantidad, stock_minimo) VALUES (@id_producto, @cantidad, 0);

        -- Finalizar orden
        UPDATE produccion.ordenes_produccion
        SET cantidad_real = @cantidad, estado = 'COMPLETADA', fecha_fin = SYSDATETIME()
        WHERE id_orden = @id_orden;

        COMMIT TRANSACTION;
        SELECT @id_orden AS id_orden, @costo_total AS costo_total;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

PRINT 'BD_NEGOCIO_ALIMENTOS v2.0 creada exitosamente.';
GO
