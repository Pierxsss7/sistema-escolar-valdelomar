IF DB_ID('BD_COMERCIAL_SJL') IS NOT NULL
BEGIN
    ALTER DATABASE BD_COMERCIAL_SJL SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BD_COMERCIAL_SJL;
END
GO

CREATE DATABASE BD_COMERCIAL_SJL;
GO

USE BD_COMERCIAL_SJL;
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

CREATE TABLE seg.roles (
    id_rol INT IDENTITY PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    descripcion VARCHAR(200),
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

CREATE TABLE seg.permisos (
    id_permiso INT IDENTITY PRIMARY KEY,
    codigo VARCHAR(30) NOT NULL,
    nombre VARCHAR(80) NOT NULL,
    descripcion VARCHAR(200),
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
    apellido VARCHAR(100),
    usuario VARCHAR(50) NOT NULL,
    clave_hash VARCHAR(255) NOT NULL,
    telefono VARCHAR(20),
    activo BIT NOT NULL DEFAULT 1,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (id_rol) REFERENCES seg.roles(id_rol)
);
GO

CREATE TABLE negocio.proveedores (
    id_proveedor INT IDENTITY PRIMARY KEY,
    ruc VARCHAR(11) NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    telefono VARCHAR(20),
    email VARCHAR(100),
    direccion VARCHAR(200),
    activo BIT NOT NULL DEFAULT 1,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

CREATE TABLE negocio.clientes (
    id_cliente INT IDENTITY PRIMARY KEY,
    dni VARCHAR(8) NOT NULL,
    nombre VARCHAR(120) NOT NULL,
    telefono VARCHAR(20),
    direccion VARCHAR(200),
    activo BIT NOT NULL DEFAULT 1,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

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
    id_subcategoria INT,
    id_unidad INT NOT NULL,
    nombre VARCHAR(120) NOT NULL,
    tipo VARCHAR(10) NOT NULL,
    activo BIT NOT NULL DEFAULT 1,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (id_categoria) REFERENCES producto.categorias(id_categoria),
    FOREIGN KEY (id_subcategoria) REFERENCES producto.subcategorias(id_subcategoria),
    FOREIGN KEY (id_unidad) REFERENCES producto.unidades(id_unidad)
);
GO

CREATE TABLE producto.precios (
    id_precio INT IDENTITY PRIMARY KEY,
    id_producto INT NOT NULL,
    precio_venta DECIMAL(10,2) NOT NULL DEFAULT 0,
    costo DECIMAL(10,2) NOT NULL DEFAULT 0,
    activo BIT NOT NULL DEFAULT 1,
    FOREIGN KEY (id_producto) REFERENCES producto.productos(id_producto)
);
GO

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

CREATE TABLE inventario.stock (
    id_stock INT IDENTITY PRIMARY KEY,
    id_producto INT NOT NULL,
    cantidad DECIMAL(10,2) NOT NULL DEFAULT 0,
    stock_minimo DECIMAL(10,2) NOT NULL DEFAULT 0,
    FOREIGN KEY (id_producto) REFERENCES producto.productos(id_producto)
);
GO

CREATE TABLE inventario.movimientos (
    id_movimiento INT IDENTITY PRIMARY KEY,
    id_producto INT NOT NULL,
    id_usuario INT NOT NULL,
    tipo VARCHAR(20) NOT NULL,
    cantidad DECIMAL(10,2) NOT NULL,
    referencia_id INT,
    referencia_tipo VARCHAR(20),
    observacion VARCHAR(300),
    fecha DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (id_producto) REFERENCES producto.productos(id_producto),
    FOREIGN KEY (id_usuario) REFERENCES seg.usuarios(id_usuario)
);
GO

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

CREATE TABLE venta.mesas (
    id_mesa INT IDENTITY PRIMARY KEY,
    numero INT NOT NULL,
    capacidad INT NOT NULL DEFAULT 4
);
GO

CREATE TABLE venta.ventas (
    id_venta INT IDENTITY PRIMARY KEY,
    id_cliente INT,
    id_usuario INT NOT NULL,
    id_mesa INT,
    total DECIMAL(10,2) NOT NULL,
    fecha DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (id_cliente) REFERENCES negocio.clientes(id_cliente),
    FOREIGN KEY (id_usuario) REFERENCES seg.usuarios(id_usuario),
    FOREIGN KEY (id_mesa) REFERENCES venta.mesas(id_mesa)
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

CREATE TABLE venta.pedidos (
    id_pedido INT IDENTITY PRIMARY KEY,
    id_cliente INT,
    id_usuario INT NOT NULL,
    tipo VARCHAR(20) NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    direccion_entrega VARCHAR(200),
    total DECIMAL(10,2) NOT NULL,
    fecha DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
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
    FOREIGN KEY (id_pedido) REFERENCES venta.pedidos(id_pedido),
    FOREIGN KEY (id_producto) REFERENCES producto.productos(id_producto)
);
GO

CREATE TABLE financiero.metodos_pago (
    id_metodo INT IDENTITY PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL
);
GO

CREATE TABLE venta.pagos (
    id_pago INT IDENTITY PRIMARY KEY,
    id_venta INT,
    id_pedido INT,
    id_metodo INT NOT NULL,
    monto DECIMAL(10,2) NOT NULL,
    referencia VARCHAR(100),
    fecha DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (id_venta) REFERENCES venta.ventas(id_venta),
    FOREIGN KEY (id_pedido) REFERENCES venta.pedidos(id_pedido),
    FOREIGN KEY (id_metodo) REFERENCES financiero.metodos_pago(id_metodo)
);
GO

CREATE TABLE financiero.cajas (
    id_caja INT IDENTITY PRIMARY KEY,
    id_usuario INT NOT NULL,
    apertura DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    cierre DATETIME2,
    monto_inicial DECIMAL(10,2) NOT NULL DEFAULT 0,
    monto_final DECIMAL(10,2),
    estado VARCHAR(20) NOT NULL DEFAULT 'ABIERTA',
    FOREIGN KEY (id_usuario) REFERENCES seg.usuarios(id_usuario)
);
GO

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

CREATE TABLE auditoria.log (
    id_log BIGINT IDENTITY PRIMARY KEY,
    id_usuario INT,
    tabla VARCHAR(100) NOT NULL,
    accion VARCHAR(20) NOT NULL,
    fecha DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

INSERT INTO seg.roles (nombre, descripcion) VALUES
('ADMINISTRADOR', 'Acceso total'),
('CAJERO', 'Ventas y caja'),
('COCINA', 'Cocina y produccion'),
('ALMACENERO', 'Inventario y compras');
GO

INSERT INTO seg.permisos (codigo, nombre, descripcion, modulo) VALUES
('USUARIOS', 'Gestionar usuarios', 'Crear y editar usuarios', 'SEGURIDAD'),
('PRODUCTOS', 'Gestionar productos', 'Crear y editar productos', 'PRODUCTOS'),
('VENTAS', 'Registrar ventas', 'Realizar ventas', 'VENTAS'),
('PEDIDOS', 'Gestionar pedidos', 'Tomar y entregar pedidos', 'VENTAS'),
('COMPRAS', 'Registrar compras', 'Comprar insumos', 'COMPRAS'),
('INVENTARIO', 'Ver inventario', 'Controlar stock', 'INVENTARIO'),
('CAJA', 'Manejar caja', 'Abrir y cerrar caja', 'FINANZAS'),
('REPORTES', 'Ver reportes', 'Ver reportes del dia', 'REPORTES'),
('RECETAS', 'Gestionar recetas', 'Crear recetas de platos', 'PRODUCCION');
GO

INSERT INTO seg.rol_permiso (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso FROM seg.roles r, seg.permisos p WHERE r.nombre = 'ADMINISTRADOR';
GO

INSERT INTO seg.rol_permiso (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso FROM seg.roles r, seg.permisos p
WHERE r.nombre = 'CAJERO' AND p.codigo IN ('VENTAS', 'PEDIDOS', 'CAJA', 'REPORTES');
GO

INSERT INTO seg.rol_permiso (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso FROM seg.roles r, seg.permisos p
WHERE r.nombre = 'COCINA' AND p.codigo IN ('PEDIDOS', 'RECETAS', 'INVENTARIO');
GO

INSERT INTO seg.rol_permiso (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso FROM seg.roles r, seg.permisos p
WHERE r.nombre = 'ALMACENERO' AND p.codigo IN ('PRODUCTOS', 'COMPRAS', 'INVENTARIO');
GO

INSERT INTO seg.usuarios (id_rol, nombre, usuario, clave_hash) VALUES
(1, 'Admin', 'admin', 'admin123');
GO

INSERT INTO producto.unidades (nombre, abreviatura) VALUES
('Unidad', 'und'),
('Kilogramo', 'kg'),
('Gramo', 'g'),
('Litro', 'L'),
('Mililitro', 'ml'),
('Docena', 'doc'),
('Paquete', 'paq'),
('Porcion', 'por');
GO

INSERT INTO producto.categorias (nombre) VALUES
('Verduras'),
('Carnes y Pollo'),
('Abarrotes'),
('Lacteos y Huevos'),
('Bebidas'),
('Platos de Fondo'),
('Entradas y Sopas'),
('Combos'),
('Postres');
GO

INSERT INTO producto.subcategorias (id_categoria, nombre) VALUES
(1, 'Tuberculos'),
(1, 'Hojas Verdes'),
(1, 'Legumbres'),
(2, 'Pollo'),
(2, 'Carne de Res'),
(2, 'Cerdo'),
(2, 'Pescado'),
(3, 'Arroz'),
(3, 'Fideos'),
(3, 'Condimentos'),
(3, 'Enlatados'),
(4, 'Huevos'),
(4, 'Quesos'),
(5, 'Gaseosas'),
(5, 'Jugos'),
(5, 'Aguas'),
(6, 'Pollo'),
(6, 'Pescado'),
(6, 'Carnes'),
(9, 'Caseros');
GO

INSERT INTO financiero.metodos_pago (nombre) VALUES
('EFECTIVO'),
('YAPE'),
('PLIN'),
('TARJETA'),
('TRANSFERENCIA');
GO

INSERT INTO venta.mesas (numero, capacidad) VALUES
(1,4),(2,4),(3,4),(4,2),(5,4),(6,4),(7,6),(8,2);
GO

INSERT INTO negocio.proveedores (ruc, nombre, telefono, direccion) VALUES
('00000000001', 'Mercado Central SJL', '987654321', 'Av. Principal SJL'),
('00000000002', 'Distribuidora de Abarrotes', '987654322', 'Av. Las Flores'),
('00000000003', 'Carnes y Pollos SJL', '987654323', 'Jr. Los Olivos');
GO

INSERT INTO negocio.clientes (dni, nombre, telefono) VALUES
('00000000', 'Cliente General', ''),
('12345678', 'Juan Perez', '987111222'),
('87654321', 'Maria Garcia', '987333444');
GO

PRINT 'BD_COMERCIAL_SJL creada exitosamente.';
GO
