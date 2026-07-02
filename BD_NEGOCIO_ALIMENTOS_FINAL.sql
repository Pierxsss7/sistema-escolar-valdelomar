CREATE DATABASE BD_NEGOCIO_ALIMENTOS;
GO
USE BD_NEGOCIO_ALIMENTOS;
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
CREATE SCHEMA reporte;
GO
CREATE TABLE seg.roles (
    id_rol INT IDENTITY PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    descripcion VARCHAR(200),
    es_sistema BIT NOT NULL DEFAULT 0,
    activo BIT NOT NULL DEFAULT 1,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    updated_at DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO
CREATE UNIQUE INDEX uq_roles_nombre ON seg.roles(nombre);
GO
CREATE TABLE seg.permisos (
    id_permiso INT IDENTITY PRIMARY KEY,
    codigo VARCHAR(30) NOT NULL,
    nombre VARCHAR(80) NOT NULL,
    descripcion VARCHAR(200),
    modulo VARCHAR(30) NOT NULL,
    activo BIT NOT NULL DEFAULT 1
);
GO
CREATE UNIQUE INDEX uq_permisos_codigo ON seg.permisos(codigo);
GO
CREATE TABLE seg.rol_permiso (
    id_rol INT NOT NULL,
    id_permiso INT NOT NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT pk_rol_permiso PRIMARY KEY (id_rol, id_permiso),
    FOREIGN KEY (id_rol) REFERENCES seg.roles(id_rol),
    FOREIGN KEY (id_permiso) REFERENCES seg.permisos(id_permiso)
);
GO
CREATE TABLE seg.usuarios (
    id_usuario INT IDENTITY PRIMARY KEY,
    id_rol INT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100),
    usuario VARCHAR(50) NOT NULL,
    email VARCHAR(100),
    clave_hash VARCHAR(255) NOT NULL,
    telefono VARCHAR(20),
    activo BIT NOT NULL DEFAULT 1,
    ultimo_acceso DATETIME2,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    updated_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (id_rol) REFERENCES seg.roles(id_rol)
);
GO
CREATE UNIQUE INDEX uq_usuarios_usuario ON seg.usuarios(usuario);
GO
CREATE TABLE negocio.proveedores (
    id_proveedor INT IDENTITY PRIMARY KEY,
    tipo_documento VARCHAR(5) NOT NULL DEFAULT 'RUC',
    numero_documento VARCHAR(20) NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    nombre_comercial VARCHAR(150),
    telefono VARCHAR(20),
    email VARCHAR(100),
    direccion VARCHAR(200),
    activo BIT NOT NULL DEFAULT 1,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    updated_at DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO
CREATE UNIQUE INDEX uq_proveedores_doc ON negocio.proveedores(tipo_documento, numero_documento);
GO
CREATE TABLE negocio.clientes (
    id_cliente INT IDENTITY PRIMARY KEY,
    tipo_documento VARCHAR(5) NOT NULL DEFAULT 'DNI',
    numero_documento VARCHAR(20) NOT NULL,
    nombre VARCHAR(120) NOT NULL,
    telefono VARCHAR(20),
    email VARCHAR(100),
    direccion VARCHAR(200),
    fecha_registro DATE NOT NULL DEFAULT CAST(SYSDATETIME() AS DATE),
    activo BIT NOT NULL DEFAULT 1,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    updated_at DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO
CREATE UNIQUE INDEX uq_clientes_doc ON negocio.clientes(tipo_documento, numero_documento);
GO
CREATE TABLE producto.categorias (
    id_categoria INT IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion VARCHAR(200),
    activo BIT NOT NULL DEFAULT 1,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    updated_at DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO
CREATE UNIQUE INDEX uq_categorias_nombre ON producto.categorias(nombre);
GO
CREATE TABLE producto.subcategorias (
    id_subcategoria INT IDENTITY PRIMARY KEY,
    id_categoria INT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    activo BIT NOT NULL DEFAULT 1,
    FOREIGN KEY (id_categoria) REFERENCES producto.categorias(id_categoria)
);
GO
CREATE UNIQUE INDEX uq_subcategoria ON producto.subcategorias(id_categoria, nombre);
GO
CREATE TABLE producto.unidades_medida (
    id_unidad INT IDENTITY PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    abreviatura VARCHAR(10) NOT NULL,
    tipo VARCHAR(10) NOT NULL DEFAULT 'UNIDAD'
);
GO
CREATE UNIQUE INDEX uq_unidad_nombre ON producto.unidades_medida(nombre);
GO
CREATE TABLE producto.productos (
    id_producto INT IDENTITY PRIMARY KEY,
    id_categoria INT NOT NULL,
    id_subcategoria INT,
    id_unidad INT NOT NULL,
    codigo_barras VARCHAR(50),
    nombre VARCHAR(120) NOT NULL,
    descripcion VARCHAR(250),
    tipo VARCHAR(10) NOT NULL,
    activo BIT NOT NULL DEFAULT 1,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    updated_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (id_categoria) REFERENCES producto.categorias(id_categoria),
    FOREIGN KEY (id_subcategoria) REFERENCES producto.subcategorias(id_subcategoria),
    FOREIGN KEY (id_unidad) REFERENCES producto.unidades_medida(id_unidad)
);
GO
CREATE UNIQUE INDEX uq_productos_barras ON producto.productos(codigo_barras) WHERE codigo_barras IS NOT NULL;
GO
CREATE INDEX ix_productos_nombre ON producto.productos(nombre);
GO
CREATE TABLE produccion.recetas (
    id_receta INT IDENTITY PRIMARY KEY,
    id_producto INT NOT NULL,
    nombre VARCHAR(120) NOT NULL,
    descripcion VARCHAR(300),
    rendimiento DECIMAL(10,2) NOT NULL DEFAULT 1,
    id_unidad INT NOT NULL,
    tiempo_prep_min INT,
    costo_total DECIMAL(10,2) NOT NULL DEFAULT 0,
    activo BIT NOT NULL DEFAULT 1,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    updated_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (id_producto) REFERENCES producto.productos(id_producto),
    FOREIGN KEY (id_unidad) REFERENCES producto.unidades_medida(id_unidad)
);
GO
CREATE UNIQUE INDEX uq_recetas_producto ON produccion.recetas(id_producto);
GO
CREATE TABLE produccion.detalle_receta (
    id_detalle_receta INT IDENTITY PRIMARY KEY,
    id_receta INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad DECIMAL(10,2) NOT NULL,
    id_unidad INT NOT NULL,
    merma_porcentaje DECIMAL(5,2) NOT NULL DEFAULT 0,
    costo_estimado DECIMAL(10,2) NOT NULL DEFAULT 0,
    FOREIGN KEY (id_receta) REFERENCES produccion.recetas(id_receta),
    FOREIGN KEY (id_producto) REFERENCES producto.productos(id_producto),
    FOREIGN KEY (id_unidad) REFERENCES producto.unidades_medida(id_unidad)
);
GO
CREATE TABLE producto.precios (
    id_precio INT IDENTITY PRIMARY KEY,
    id_producto INT NOT NULL,
    precio_venta DECIMAL(10,2) NOT NULL DEFAULT 0,
    costo_promedio DECIMAL(10,2) NOT NULL DEFAULT 0,
    fecha_inicio DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    fecha_fin DATETIME2,
    activo BIT NOT NULL DEFAULT 1,
    FOREIGN KEY (id_producto) REFERENCES producto.productos(id_producto)
);
GO
CREATE INDEX ix_precios_activo ON producto.precios(id_producto, activo) WHERE activo = 1;
GO
CREATE TABLE inventario.lotes (
    id_lote INT IDENTITY PRIMARY KEY,
    id_producto INT NOT NULL,
    codigo_lote VARCHAR(50) NOT NULL,
    cantidad_inicial DECIMAL(10,2) NOT NULL,
    cantidad_actual DECIMAL(10,2) NOT NULL,
    costo_unitario DECIMAL(10,2) NOT NULL DEFAULT 0,
    fecha_produccion DATE,
    fecha_vencimiento DATE,
    activo BIT NOT NULL DEFAULT 1,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (id_producto) REFERENCES producto.productos(id_producto)
);
GO
CREATE UNIQUE INDEX uq_lotes_codigo ON inventario.lotes(codigo_lote);
GO
CREATE INDEX ix_lotes_vencimiento ON inventario.lotes(fecha_vencimiento) WHERE fecha_vencimiento IS NOT NULL;
GO
CREATE TABLE inventario.stock (
    id_stock INT IDENTITY PRIMARY KEY,
    id_producto INT NOT NULL,
    id_lote INT,
    cantidad DECIMAL(10,2) NOT NULL DEFAULT 0,
    stock_minimo DECIMAL(10,2) NOT NULL DEFAULT 0,
    ubicacion VARCHAR(50),
    FOREIGN KEY (id_producto) REFERENCES producto.productos(id_producto),
    FOREIGN KEY (id_lote) REFERENCES inventario.lotes(id_lote)
);
GO
CREATE UNIQUE INDEX uq_stock_producto ON inventario.stock(id_producto);
GO
CREATE TABLE inventario.movimientos (
    id_movimiento INT IDENTITY PRIMARY KEY,
    id_producto INT NOT NULL,
    id_lote INT,
    id_usuario INT NOT NULL,
    tipo_movimiento VARCHAR(20) NOT NULL,
    motivo VARCHAR(100) NOT NULL,
    cantidad DECIMAL(10,2) NOT NULL,
    stock_anterior DECIMAL(10,2) NOT NULL,
    stock_nuevo DECIMAL(10,2) NOT NULL,
    costo_unitario DECIMAL(10,2),
    id_referencia INT,
    tipo_referencia VARCHAR(20),
    observacion VARCHAR(300),
    fecha DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (id_producto) REFERENCES producto.productos(id_producto),
    FOREIGN KEY (id_usuario) REFERENCES seg.usuarios(id_usuario)
);
GO
CREATE INDEX ix_movimientos_fecha ON inventario.movimientos(fecha DESC);
GO
CREATE TABLE compra.compras (
    id_compra INT IDENTITY PRIMARY KEY,
    id_proveedor INT NOT NULL,
    id_usuario INT NOT NULL,
    tipo_comprobante VARCHAR(20) NOT NULL DEFAULT 'FACTURA',
    serie_comprobante VARCHAR(10),
    numero_comprobante VARCHAR(20),
    fecha_emision DATE NOT NULL DEFAULT CAST(SYSDATETIME() AS DATE),
    fecha_recepcion DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    subtotal DECIMAL(10,2) NOT NULL,
    impuesto DECIMAL(10,2) NOT NULL DEFAULT 0,
    total DECIMAL(10,2) NOT NULL,
    observacion VARCHAR(300),
    estado VARCHAR(20) NOT NULL DEFAULT 'REGISTRADA',
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    updated_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (id_proveedor) REFERENCES negocio.proveedores(id_proveedor),
    FOREIGN KEY (id_usuario) REFERENCES seg.usuarios(id_usuario)
);
GO
CREATE TABLE compra.detalle_compra (
    id_detalle_compra INT IDENTITY PRIMARY KEY,
    id_compra INT NOT NULL,
    id_producto INT NOT NULL,
    id_lote INT,
    cantidad DECIMAL(10,2) NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (id_compra) REFERENCES compra.compras(id_compra),
    FOREIGN KEY (id_producto) REFERENCES producto.productos(id_producto),
    FOREIGN KEY (id_lote) REFERENCES inventario.lotes(id_lote)
);
GO
CREATE TABLE venta.mesas (
    id_mesa INT IDENTITY PRIMARY KEY,
    numero INT NOT NULL,
    capacidad INT NOT NULL DEFAULT 4,
    ubicacion VARCHAR(50),
    estado VARCHAR(20) NOT NULL DEFAULT 'DISPONIBLE',
    activo BIT NOT NULL DEFAULT 1
);
GO
CREATE UNIQUE INDEX uq_mesa_numero ON venta.mesas(numero);
GO
CREATE TABLE venta.ventas (
    id_venta INT IDENTITY PRIMARY KEY,
    id_cliente INT,
    id_usuario INT NOT NULL,
    id_mesa INT,
    tipo_comprobante VARCHAR(20) NOT NULL DEFAULT 'BOLETA',
    serie_comprobante VARCHAR(10),
    numero_comprobante VARCHAR(20),
    fecha DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    subtotal DECIMAL(10,2) NOT NULL,
    impuesto DECIMAL(10,2) NOT NULL DEFAULT 0,
    descuento DECIMAL(10,2) NOT NULL DEFAULT 0,
    total DECIMAL(10,2) NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'PAGADA',
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    updated_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (id_cliente) REFERENCES negocio.clientes(id_cliente),
    FOREIGN KEY (id_usuario) REFERENCES seg.usuarios(id_usuario),
    FOREIGN KEY (id_mesa) REFERENCES venta.mesas(id_mesa)
);
GO
CREATE INDEX ix_ventas_fecha ON venta.ventas(fecha DESC);
GO
CREATE TABLE venta.detalle_venta (
    id_detalle_venta INT IDENTITY PRIMARY KEY,
    id_venta INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad DECIMAL(10,2) NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    observacion VARCHAR(200),
    FOREIGN KEY (id_venta) REFERENCES venta.ventas(id_venta),
    FOREIGN KEY (id_producto) REFERENCES producto.productos(id_producto)
);
GO
CREATE INDEX ix_detventa_venta ON venta.detalle_venta(id_venta);
GO
CREATE TABLE venta.tipo_pedido (
    id_tipo_pedido INT IDENTITY PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL,
    activo BIT NOT NULL DEFAULT 1
);
GO
CREATE UNIQUE INDEX uq_tipopedido_nombre ON venta.tipo_pedido(nombre);
GO
CREATE TABLE venta.pedidos (
    id_pedido INT IDENTITY PRIMARY KEY,
    id_cliente INT,
    id_usuario INT NOT NULL,
    id_tipo_pedido INT NOT NULL,
    fecha DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    estado VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    direccion_entrega VARCHAR(200),
    telefono_contacto VARCHAR(20),
    hora_programada TIME,
    subtotal DECIMAL(10,2) NOT NULL,
    impuesto DECIMAL(10,2) NOT NULL DEFAULT 0,
    total DECIMAL(10,2) NOT NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    updated_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (id_cliente) REFERENCES negocio.clientes(id_cliente),
    FOREIGN KEY (id_usuario) REFERENCES seg.usuarios(id_usuario),
    FOREIGN KEY (id_tipo_pedido) REFERENCES venta.tipo_pedido(id_tipo_pedido)
);
GO
CREATE INDEX ix_pedidos_estado ON venta.pedidos(estado, fecha);
GO
CREATE TABLE venta.detalle_pedido (
    id_detalle_pedido INT IDENTITY PRIMARY KEY,
    id_pedido INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad DECIMAL(10,2) NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    observacion VARCHAR(200),
    FOREIGN KEY (id_pedido) REFERENCES venta.pedidos(id_pedido),
    FOREIGN KEY (id_producto) REFERENCES producto.productos(id_producto)
);
GO
CREATE INDEX ix_detpedido_pedido ON venta.detalle_pedido(id_pedido);
GO
CREATE TABLE financiero.metodos_pago (
    id_metodo_pago INT IDENTITY PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    requiere_referencia BIT NOT NULL DEFAULT 0,
    activo BIT NOT NULL DEFAULT 1
);
GO
CREATE UNIQUE INDEX uq_metodopago_nombre ON financiero.metodos_pago(nombre);
GO
CREATE TABLE venta.pagos_venta (
    id_pago_venta INT IDENTITY PRIMARY KEY,
    id_venta INT NOT NULL,
    id_metodo_pago INT NOT NULL,
    monto DECIMAL(10,2) NOT NULL,
    referencia VARCHAR(100),
    fecha DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (id_venta) REFERENCES venta.ventas(id_venta),
    FOREIGN KEY (id_metodo_pago) REFERENCES financiero.metodos_pago(id_metodo_pago)
);
GO
CREATE TABLE venta.pagos_pedido (
    id_pago_pedido INT IDENTITY PRIMARY KEY,
    id_pedido INT NOT NULL,
    id_metodo_pago INT NOT NULL,
    monto DECIMAL(10,2) NOT NULL,
    referencia VARCHAR(100),
    fecha DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (id_pedido) REFERENCES venta.pedidos(id_pedido),
    FOREIGN KEY (id_metodo_pago) REFERENCES financiero.metodos_pago(id_metodo_pago)
);
GO
CREATE TABLE financiero.cajas (
    id_caja INT IDENTITY PRIMARY KEY,
    id_usuario INT NOT NULL,
    fecha_apertura DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    fecha_cierre DATETIME2,
    monto_inicial DECIMAL(10,2) NOT NULL DEFAULT 0,
    monto_final DECIMAL(10,2),
    total_ventas DECIMAL(10,2) NOT NULL DEFAULT 0,
    total_efectivo DECIMAL(10,2) NOT NULL DEFAULT 0,
    total_tarjeta DECIMAL(10,2) NOT NULL DEFAULT 0,
    total_digital DECIMAL(10,2) NOT NULL DEFAULT 0,
    diferencia DECIMAL(10,2),
    estado VARCHAR(20) NOT NULL DEFAULT 'ABIERTA',
    observacion_cierre VARCHAR(300),
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (id_usuario) REFERENCES seg.usuarios(id_usuario)
);
GO
CREATE TABLE produccion.ordenes_produccion (
    id_orden INT IDENTITY PRIMARY KEY,
    id_receta INT NOT NULL,
    id_usuario INT NOT NULL,
    cantidad_producir DECIMAL(10,2) NOT NULL,
    cantidad_real DECIMAL(10,2),
    estado VARCHAR(20) NOT NULL DEFAULT 'PLANIFICADA',
    fecha_inicio DATETIME2,
    fecha_fin DATETIME2,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (id_receta) REFERENCES produccion.recetas(id_receta),
    FOREIGN KEY (id_usuario) REFERENCES seg.usuarios(id_usuario)
);
GO
CREATE TABLE produccion.detalle_orden_produccion (
    id_detalle_orden INT IDENTITY PRIMARY KEY,
    id_orden INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad_requerida DECIMAL(10,2) NOT NULL,
    cantidad_usada DECIMAL(10,2),
    id_lote INT,
    FOREIGN KEY (id_orden) REFERENCES produccion.ordenes_produccion(id_orden),
    FOREIGN KEY (id_producto) REFERENCES producto.productos(id_producto),
    FOREIGN KEY (id_lote) REFERENCES inventario.lotes(id_lote)
);
GO
CREATE TABLE auditoria.log_cambios (
    id_log BIGINT IDENTITY PRIMARY KEY,
    id_usuario INT,
    tabla VARCHAR(100) NOT NULL,
    id_registro INT NOT NULL,
    accion VARCHAR(20) NOT NULL,
    valores_anteriores VARCHAR(MAX),
    valores_nuevos VARCHAR(MAX),
    ip_address VARCHAR(45),
    fecha DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO
CREATE INDEX ix_log_fecha ON auditoria.log_cambios(fecha DESC);
GO
-- VISTAS
CREATE VIEW reporte.vw_inventario_actual AS
SELECT p.id_producto, p.nombre AS producto, c.nombre AS categoria,
       sc.nombre AS subcategoria, u.abreviatura AS unidad,
       ISNULL(s.cantidad, 0) AS stock_actual, s.stock_minimo,
       CASE WHEN ISNULL(s.cantidad, 0) <= 0 THEN 'SIN_STOCK'
            WHEN ISNULL(s.cantidad, 0) <= s.stock_minimo THEN 'BAJO'
            ELSE 'NORMAL' END AS nivel_stock,
       p.tipo, pr.precio_venta, pr.costo_promedio
FROM producto.productos p
JOIN producto.categorias c ON c.id_categoria = p.id_categoria
LEFT JOIN producto.subcategorias sc ON sc.id_subcategoria = p.id_subcategoria
JOIN producto.unidades_medida u ON u.id_unidad = p.id_unidad
LEFT JOIN inventario.stock s ON s.id_producto = p.id_producto
LEFT JOIN producto.precios pr ON pr.id_producto = p.id_producto AND pr.activo = 1
WHERE p.activo = 1;
GO
CREATE VIEW reporte.vw_costos_recetas AS
SELECT r.id_receta, r.nombre AS receta, p.nombre AS producto_final,
       r.rendimiento, u.abreviatura AS unidad_rendimiento, r.costo_total,
       (r.costo_total / NULLIF(r.rendimiento, 0)) AS costo_unitario,
       pr.precio_venta,
       (pr.precio_venta - (r.costo_total / NULLIF(r.rendimiento, 0))) AS margen_ganancia,
       CASE WHEN pr.precio_venta > 0
            THEN ((pr.precio_venta - (r.costo_total / NULLIF(r.rendimiento, 0))) / pr.precio_venta) * 100
            ELSE 0 END AS margen_porcentaje
FROM produccion.recetas r
JOIN producto.productos p ON p.id_producto = r.id_producto
JOIN producto.unidades_medida u ON u.id_unidad = r.id_unidad
LEFT JOIN producto.precios pr ON pr.id_producto = p.id_producto AND pr.activo = 1;
GO
CREATE VIEW reporte.vw_ventas_diarias AS
SELECT CAST(fecha AS DATE) AS fecha, COUNT(*) AS total_ventas,
       SUM(total) AS monto_total, AVG(total) AS ticket_promedio
FROM venta.ventas WHERE estado NOT IN ('ANULADA')
GROUP BY CAST(fecha AS DATE);
GO
CREATE VIEW reporte.vw_productos_top AS
SELECT p.id_producto, p.nombre AS producto, c.nombre AS categoria,
       SUM(dv.cantidad) AS cantidad_vendida, SUM(dv.subtotal) AS total_vendido,
       COUNT(DISTINCT dv.id_venta) AS veces_vendido
FROM venta.detalle_venta dv
JOIN producto.productos p ON p.id_producto = dv.id_producto
JOIN producto.categorias c ON c.id_categoria = p.id_categoria
JOIN venta.ventas v ON v.id_venta = dv.id_venta AND v.estado NOT IN ('ANULADA')
GROUP BY p.id_producto, p.nombre, c.nombre;
GO
-- DATOS INICIALES
INSERT INTO seg.roles (nombre, descripcion, es_sistema) VALUES
('ADMINISTRADOR', 'Acceso total al sistema', 1),
('CAJERO', 'Ventas, pedidos y caja', 0),
('ALMACENERO', 'Compras e inventario', 0),
('COCINA', 'Gestion de pedidos y produccion', 0);
GO
INSERT INTO seg.permisos (codigo, nombre, descripcion, modulo) VALUES
('USR_VIEW','Ver usuarios','Visualizar usuarios','SEGURIDAD'),
('USR_EDIT','Editar usuarios','Crear y modificar usuarios','SEGURIDAD'),
('PROD_VIEW','Ver productos','Visualizar catalogo','PRODUCTOS'),
('PROD_EDIT','Editar productos','Crear y modificar productos','PRODUCTOS'),
('COMP_VIEW','Ver compras','Visualizar compras','COMPRAS'),
('COMP_EDIT','Registrar compras','Crear compras','COMPRAS'),
('VENT_VIEW','Ver ventas','Ver reportes de ventas','VENTAS'),
('VENT_EDIT','Registrar ventas','Crear ventas','VENTAS'),
('PED_VIEW','Ver pedidos','Visualizar pedidos','PEDIDOS'),
('PED_EDIT','Gestionar pedidos','Cambiar estado pedidos','PEDIDOS'),
('INV_VIEW','Ver inventario','Visualizar stock','INVENTARIO'),
('INV_EDIT','Ajustar stock','Realizar ajustes','INVENTARIO'),
('RPT_VIEW','Ver reportes','Acceder a reportes','REPORTES'),
('CAJA_VIEW','Ver caja','Movimientos de caja','CAJA'),
('CAJA_EDIT','Abrir/cerrar caja','Gestionar caja','CAJA'),
('REC_VIEW','Ver recetas','Visualizar recetario','PRODUCCION'),
('REC_EDIT','Editar recetas','Crear y modificar recetas','PRODUCCION');
GO
INSERT INTO seg.rol_permiso (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso FROM seg.roles r, seg.permisos p WHERE r.nombre = 'ADMINISTRADOR';
GO
INSERT INTO seg.rol_permiso (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso FROM seg.roles r, seg.permisos p
WHERE r.nombre = 'CAJERO' AND p.codigo IN ('PROD_VIEW','VENT_VIEW','VENT_EDIT','PED_VIEW','PED_EDIT','CAJA_VIEW','CAJA_EDIT','RPT_VIEW');
GO
INSERT INTO seg.rol_permiso (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso FROM seg.roles r, seg.permisos p
WHERE r.nombre = 'ALMACENERO' AND p.codigo IN ('PROD_VIEW','PROD_EDIT','COMP_VIEW','COMP_EDIT','INV_VIEW','INV_EDIT','RPT_VIEW');
GO
INSERT INTO seg.rol_permiso (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso FROM seg.roles r, seg.permisos p
WHERE r.nombre = 'COCINA' AND p.codigo IN ('PED_VIEW','PED_EDIT','REC_VIEW','REC_EDIT');
GO
INSERT INTO seg.usuarios (id_rol, nombre, apellido, usuario, clave_hash, telefono)
VALUES (1, 'Admin', 'Principal', 'admin', 'admin123', '999999999');
GO
INSERT INTO producto.unidades_medida (nombre, abreviatura, tipo) VALUES
('Unidad','und','UNIDAD'),('Kilogramo','kg','PESO'),('Gramo','g','PESO'),
('Litro','lt','VOLUMEN'),('Mililitro','ml','VOLUMEN'),('Paquete','paq','UNIDAD'),
('Docena','doc','UNIDAD'),('Porcion','porc','UNIDAD');
GO
INSERT INTO producto.categorias (nombre) VALUES
('Verduras'),('Carnes'),('Abarrotes'),('Lacteos'),('Bebidas'),('Platos'),('Entradas'),('Combos'),('Postres');
GO
INSERT INTO producto.subcategorias (id_categoria, nombre) VALUES
(1,'Tuberculos'),(1,'Hojas'),(2,'Pollo'),(2,'Res'),(3,'Arroz'),(3,'Fideos'),(3,'Condimentos'),
(5,'Gaseosas'),(5,'Jugos'),(6,'Pollo'),(6,'Pescado'),(9,'Caseros');
GO
INSERT INTO financiero.metodos_pago (nombre) VALUES
('EFECTIVO'),('TARJETA'),('TRANSFERENCIA'),('YAPE'),('PLIN');
GO
INSERT INTO venta.tipo_pedido (nombre) VALUES ('LOCAL'),('DELIVERY'),('RECOJO');
GO
INSERT INTO venta.mesas (numero, capacidad, ubicacion) VALUES
(1,4,'Interior'),(2,4,'Interior'),(3,4,'Interior'),(4,2,'Interior'),
(5,4,'Interior'),(6,4,'Ventana'),(7,2,'Ventana'),(8,6,'Terraza');
GO
INSERT INTO negocio.proveedores (tipo_documento, numero_documento, nombre, telefono, direccion)
VALUES ('RUC','00000000000','Proveedor General','900000000','Mercado Central');
GO
INSERT INTO negocio.clientes (tipo_documento, numero_documento, nombre, telefono)
VALUES ('DNI','00000000','Cliente General','');
GO
PRINT 'BD_NEGOCIO_ALIMENTOS creada correctamente.';
GO
