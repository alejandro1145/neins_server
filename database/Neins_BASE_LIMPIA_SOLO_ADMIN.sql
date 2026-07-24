-- ============================================================
--  NEINS â€” Base de datos COMPLETA v3.0
--  "Una Pa' La Sed" â€“ LicorerÃ­a Premium
--
--  Historial de cambios:
--   v1.0 â†’ BD original con errores
--   v2.0 â†’ Correcciones + tablas Pagos, Detalle_Fiado,
--           Compras_Proveedor, Detalle_Compra, Alertas, Categorias
--   v2.1 â†’ NUEVA tabla Movimientos_Inventario (bitÃ¡cora completa)
--           NUEVA tabla Ventas + Detalle_Venta (ventas de contado)
--   v3.0 â†’ CORRECCIONES COMPLETAS (10 fallos corregidos):
--           [F1]  foto_perfil agregada a Usuarios
--           [F2]  clientes hereda de Usuarios via id_usuario (FK)
--                 â†’ elimina duplicidad de nombre/correo/telÃ©fono/doc
--           [F3]  NUEVA tabla Pagos_A_Proveedores
--                 + trigger que reduce saldo_deuda del proveedor
--           [F4]  Trigger de pagos reescrito como BEFORE INSERT
--                 para evitar Error 1442 de MySQL
--           [F5]  Usuarios.rol reemplazado por id_roles (FK a roles)
--           [F6]  ValidaciÃ³n de stock negativo en triggers de salida
--           [F7]  saldo_pendiente_total en clientes + trigger que
--                 lo actualiza al pagar
--           [F8]  Trigger de compra ahora actualiza saldo_deuda
--                 del proveedor automÃ¡ticamente
--           [F9]  Alertas ahora tiene id_usuarios_destino para
--                 filtrar por destinatario
--           [F10] ContraseÃ±a admin hasheada con SHA2-256 (mÃ­nimo
--                 hasta implementar BCrypt en Java)
-- ============================================================

DROP DATABASE IF EXISTS Neins;
CREATE DATABASE Neins CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci;
USE Neins;

-- ---------------------------------------------------------------
-- Tabla: Tipo_documento
-- ---------------------------------------------------------------
CREATE TABLE Tipo_documento (
    id_tipo_documento INT PRIMARY KEY AUTO_INCREMENT,
    tipo_documento    VARCHAR(45) NOT NULL
);

-- ---------------------------------------------------------------
-- Tabla: roles
-- [F5] Esta tabla ahora SÃ se usa como FK en Usuarios
-- ---------------------------------------------------------------
CREATE TABLE roles (
    id_roles          INT PRIMARY KEY AUTO_INCREMENT,
    descripcion_roles VARCHAR(45) NOT NULL UNIQUE
);

-- ---------------------------------------------------------------
-- Tabla: medio_pago
-- ---------------------------------------------------------------
CREATE TABLE medio_pago (
    id_medio_pago          INT AUTO_INCREMENT PRIMARY KEY,
    descripcion_medio_pago VARCHAR(45) NOT NULL
);

-- ---------------------------------------------------------------
-- Tabla: Categorias
-- ---------------------------------------------------------------
CREATE TABLE Categorias (
    id_categoria INT AUTO_INCREMENT PRIMARY KEY,
    nombre       VARCHAR(60) NOT NULL
);

-- ---------------------------------------------------------------
-- Tabla: Usuarios
-- [F1]  Columna foto_perfil agregada para los avatares de la UI
-- [F5]  rol VARCHAR eliminado; ahora usa id_roles FK â†’ roles
-- ---------------------------------------------------------------
CREATE TABLE Usuarios (
    id_usuarios       INT AUTO_INCREMENT PRIMARY KEY,
    nombre            VARCHAR(100) NOT NULL,
    apellidos         VARCHAR(45)  NOT NULL,
    identificacion    VARCHAR(45)  NOT NULL UNIQUE,
    id_tipo_documento INT          NOT NULL,
    correo            VARCHAR(100) NOT NULL UNIQUE,
    telefono          VARCHAR(45)  NOT NULL UNIQUE,
    clave             VARCHAR(255) NOT NULL,
    -- [F10] VARCHAR(255) para BCrypt (60 chars) o SHA2 (64 chars)
    id_roles          INT          NOT NULL DEFAULT 2,
    -- DEFAULT 2 = 'cliente' segÃºn datos iniciales
    foto_perfil       VARCHAR(255) NULL DEFAULT NULL,
    -- [F1]  Ruta o URL de la imagen de perfil (nullable)
    fecha_nacimiento  DATE NULL,
    clave_expira      DATE NULL,
    acepto_terminos   TINYINT(1) NOT NULL DEFAULT 0,
    fecha_acepto_terminos DATETIME NULL,
    ip_acepto_terminos VARCHAR(45) NULL,
    version_terminos  VARCHAR(10) NOT NULL DEFAULT '1.0',
    telefono_verificado TINYINT(1) NOT NULL DEFAULT 0,
    otp_codigo        VARCHAR(6) NULL,
    otp_expira        DATETIME NULL,
    CONSTRAINT fk_usuario_tipodoc FOREIGN KEY (id_tipo_documento)
        REFERENCES Tipo_documento(id_tipo_documento),
    CONSTRAINT fk_usuario_rol FOREIGN KEY (id_roles)
        REFERENCES roles(id_roles)
);

-- ---------------------------------------------------------------
-- Tabla: clientes
-- [F2]  Eliminada la duplicidad de datos personales.
--       Ahora clientes apunta a Usuarios (id_usuario FK).
--       Solo guarda datos exclusivos del crÃ©dito:
--         - cupo_credito        â†’ lÃ­mite mÃ¡ximo de fiado
--         - saldo_pendiente_total â†’ crÃ©dito utilizado actual [F7]
-- ---------------------------------------------------------------
CREATE TABLE clientes (
    id_cliente              INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario              INT           NOT NULL UNIQUE,
    -- [F2] Un usuario â†’ un cliente (relaciÃ³n 1:1)
    cupo_credito            DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    saldo_pendiente_total   DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    -- [F7] Se actualiza automÃ¡ticamente con trigger al registrar
    --      fiados y pagos. Permite pintar "CrÃ©dito Utilizado"
    --      sin hacer SUM() en cada peticiÃ³n desde Java.
    CONSTRAINT fk_cliente_usuario FOREIGN KEY (id_usuario)
        REFERENCES Usuarios(id_usuarios)
);

-- ---------------------------------------------------------------
-- Tabla: Productos
-- ---------------------------------------------------------------
CREATE TABLE Productos (
    id_productos  INT AUTO_INCREMENT PRIMARY KEY,
    nombre        VARCHAR(100)  NOT NULL,
    precio        DECIMAL(10,2) NOT NULL,
    stock         INT           NOT NULL DEFAULT 0,
    stock_minimo  INT           NOT NULL DEFAULT 5,
    id_categoria  INT,
    estado        TINYINT(1)    NOT NULL DEFAULT 1,
    CONSTRAINT fk_producto_cat FOREIGN KEY (id_categoria)
        REFERENCES Categorias(id_categoria)
);

-- ---------------------------------------------------------------
-- Tabla: proveedores
-- ---------------------------------------------------------------
CREATE TABLE proveedores (
    id_proveedores INT AUTO_INCREMENT PRIMARY KEY,
    razon_social   VARCHAR(100)  NOT NULL,
    nit            VARCHAR(20)   NOT NULL UNIQUE,
    telefono       VARCHAR(45),
    correo         VARCHAR(100),
    saldo_deuda    DECIMAL(10,2) NOT NULL DEFAULT 0.00
    -- [F8] Este campo se actualiza automÃ¡ticamente por triggers
);

-- ---------------------------------------------------------------
-- Tabla: Fiado
-- ---------------------------------------------------------------
CREATE TABLE Fiado (
    id_fiado          INT AUTO_INCREMENT PRIMARY KEY,
    fecha_fiado       DATE          NOT NULL,
    fecha_limite_pago DATE          NOT NULL,
    fecha_pago        DATE,
    valor             DECIMAL(10,2) NOT NULL,
    saldo_pendiente   DECIMAL(10,2) NOT NULL,
    estado            VARCHAR(20)   NOT NULL DEFAULT 'Pendiente',
    -- 'Pendiente' | 'Pagado' | 'Vencido'
    id_cliente        INT           NOT NULL,
    id_medio_pago     INT,
    CONSTRAINT fk_fiado_cliente   FOREIGN KEY (id_cliente)
        REFERENCES clientes(id_cliente),
    CONSTRAINT fk_fiado_mediopago FOREIGN KEY (id_medio_pago)
        REFERENCES medio_pago(id_medio_pago)
);

-- ---------------------------------------------------------------
-- Tabla: Detalle_Fiado
-- ---------------------------------------------------------------
CREATE TABLE Detalle_Fiado (
    id_detalle    INT AUTO_INCREMENT PRIMARY KEY,
    id_fiado      INT           NOT NULL,
    id_productos  INT           NOT NULL,
    cantidad      INT           NOT NULL DEFAULT 1,
    precio_venta  DECIMAL(10,2) NOT NULL,
    subtotal      DECIMAL(10,2) GENERATED ALWAYS AS (cantidad * precio_venta) STORED,
    observacion   VARCHAR(255),
    CONSTRAINT fk_detalle_fiado    FOREIGN KEY (id_fiado)
        REFERENCES Fiado(id_fiado),
    CONSTRAINT fk_detalle_producto FOREIGN KEY (id_productos)
        REFERENCES Productos(id_productos)
);

-- ---------------------------------------------------------------
-- Tabla: Pagos
--   Cada abono que hace un cliente. Un fiado puede tener
--   varios pagos parciales hasta quedar en cero.
-- ---------------------------------------------------------------
CREATE TABLE Pagos (
    id_pago       INT AUTO_INCREMENT PRIMARY KEY,
    fecha_pago    DATE          NOT NULL,
    monto         DECIMAL(10,2) NOT NULL,
    id_fiado      INT           NOT NULL,
    id_cliente    INT           NOT NULL,
    id_medio_pago INT           NOT NULL,
    observaciones VARCHAR(255),
    CONSTRAINT fk_pago_fiado   FOREIGN KEY (id_fiado)
        REFERENCES Fiado(id_fiado),
    CONSTRAINT fk_pago_cliente FOREIGN KEY (id_cliente)
        REFERENCES clientes(id_cliente),
    CONSTRAINT fk_pago_medio   FOREIGN KEY (id_medio_pago)
        REFERENCES medio_pago(id_medio_pago)
);

-- ---------------------------------------------------------------
-- Tabla: Ventas
--   Ventas de CONTADO (paga en el momento, no fÃ­a).
-- ---------------------------------------------------------------
CREATE TABLE Ventas (
    id_venta      INT AUTO_INCREMENT PRIMARY KEY,
    fecha_venta   DATE          NOT NULL,
    total         DECIMAL(10,2) NOT NULL,
    id_cliente    INT,
    -- puede ser NULL si es venta a desconocido
    id_medio_pago INT           NOT NULL,
    id_usuarios   INT,
    -- quiÃ©n registrÃ³ la venta
    CONSTRAINT fk_venta_cliente FOREIGN KEY (id_cliente)
        REFERENCES clientes(id_cliente),
    CONSTRAINT fk_venta_medio   FOREIGN KEY (id_medio_pago)
        REFERENCES medio_pago(id_medio_pago),
    CONSTRAINT fk_venta_usuario FOREIGN KEY (id_usuarios)
        REFERENCES Usuarios(id_usuarios)
);

-- ---------------------------------------------------------------
-- Tabla: Detalle_Venta
-- ---------------------------------------------------------------
CREATE TABLE Detalle_Venta (
    id_detalle_venta INT AUTO_INCREMENT PRIMARY KEY,
    id_venta         INT           NOT NULL,
    id_productos     INT           NOT NULL,
    cantidad         INT           NOT NULL DEFAULT 1,
    precio_venta     DECIMAL(10,2) NOT NULL,
    subtotal         DECIMAL(10,2) GENERATED ALWAYS AS (cantidad * precio_venta) STORED,
    CONSTRAINT fk_detventa_venta    FOREIGN KEY (id_venta)
        REFERENCES Ventas(id_venta),
    CONSTRAINT fk_detventa_producto FOREIGN KEY (id_productos)
        REFERENCES Productos(id_productos)
);

-- ---------------------------------------------------------------
-- Tabla: Compras_Proveedor
-- ---------------------------------------------------------------
CREATE TABLE Compras_Proveedor (
    id_compra       INT AUTO_INCREMENT PRIMARY KEY,
    fecha_compra    DATE          NOT NULL,
    fecha_vence     DATE,
    total           DECIMAL(10,2) NOT NULL,
    saldo_pendiente DECIMAL(10,2) NOT NULL,
    estado          VARCHAR(20)   NOT NULL DEFAULT 'Al dia',
    -- 'Al dia' | 'Proximo a vencer' | 'Vencido'
    id_proveedores  INT           NOT NULL,
    id_medio_pago   INT,
    CONSTRAINT fk_compra_proveedor FOREIGN KEY (id_proveedores)
        REFERENCES proveedores(id_proveedores),
    CONSTRAINT fk_compra_medio     FOREIGN KEY (id_medio_pago)
        REFERENCES medio_pago(id_medio_pago)
);

-- ---------------------------------------------------------------
-- Tabla: Detalle_Compra
-- ---------------------------------------------------------------
CREATE TABLE Detalle_Compra (
    id_detalle_compra INT AUTO_INCREMENT PRIMARY KEY,
    id_compra         INT           NOT NULL,
    id_productos      INT           NOT NULL,
    cantidad          INT           NOT NULL DEFAULT 1,
    precio_costo      DECIMAL(10,2) NOT NULL,
    subtotal          DECIMAL(10,2) GENERATED ALWAYS AS (cantidad * precio_costo) STORED,
    CONSTRAINT fk_detcompra_compra   FOREIGN KEY (id_compra)
        REFERENCES Compras_Proveedor(id_compra),
    CONSTRAINT fk_detcompra_producto FOREIGN KEY (id_productos)
        REFERENCES Productos(id_productos)
);

-- ---------------------------------------------------------------
-- Tabla: Pagos_A_Proveedores   â† NUEVA [F3]
--   Registra cada abono que la licorerÃ­a hace a una factura
--   de proveedor. Permite saber la fecha, el monto y el medio
--   de cada pago parcial, y el indicador "Deuda a Proveedores"
--   baja automÃ¡ticamente vÃ­a trigger.
-- ---------------------------------------------------------------
CREATE TABLE Pagos_A_Proveedores (
    id_pago_prov  INT AUTO_INCREMENT PRIMARY KEY,
    fecha_pago    DATE          NOT NULL,
    monto         DECIMAL(10,2) NOT NULL,
    id_compra     INT           NOT NULL,
    -- a quÃ© factura de compra se le abona
    id_proveedores INT          NOT NULL,
    id_medio_pago INT           NOT NULL,
    observaciones VARCHAR(255),
    CONSTRAINT fk_pagprov_compra     FOREIGN KEY (id_compra)
        REFERENCES Compras_Proveedor(id_compra),
    CONSTRAINT fk_pagprov_proveedor  FOREIGN KEY (id_proveedores)
        REFERENCES proveedores(id_proveedores),
    CONSTRAINT fk_pagprov_medio      FOREIGN KEY (id_medio_pago)
        REFERENCES medio_pago(id_medio_pago)
);

-- ---------------------------------------------------------------
-- Tabla: Movimientos_Inventario
-- ---------------------------------------------------------------
CREATE TABLE Movimientos_Inventario (
    id_movimiento    INT AUTO_INCREMENT PRIMARY KEY,
    fecha_movimiento DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    tipo_movimiento  VARCHAR(20)  NOT NULL,
    -- 'entrada' | 'salida' | 'ajuste'
    id_productos     INT          NOT NULL,
    cantidad         INT          NOT NULL,
    stock_anterior   INT          NOT NULL,
    stock_nuevo      INT          NOT NULL,
    id_referencia    INT,
    tabla_referencia VARCHAR(40),
    id_usuarios      INT,
    observacion      VARCHAR(255),
    CONSTRAINT fk_mov_producto FOREIGN KEY (id_productos)
        REFERENCES Productos(id_productos),
    CONSTRAINT fk_mov_usuario  FOREIGN KEY (id_usuarios)
        REFERENCES Usuarios(id_usuarios)
);

-- ---------------------------------------------------------------
-- Tabla: Alertas
-- [F9] Columna id_usuarios_destino agregada para filtrar
--      alertas por destinatario. NULL = alerta global (todos).
-- ---------------------------------------------------------------
CREATE TABLE Alertas (
    id_alerta            INT AUTO_INCREMENT PRIMARY KEY,
    tipo                 VARCHAR(30)  NOT NULL,
    -- 'stock_bajo' | 'fiado_vencido' | 'deuda_vencida' | 'manual'
    descripcion          VARCHAR(255) NOT NULL,
    fecha_alerta         DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    leida                TINYINT(1)   NOT NULL DEFAULT 0,
    id_referencia        INT,
    tabla_referencia     VARCHAR(40),
    id_usuarios_destino  INT          NULL DEFAULT NULL,
    -- [F9] NULL = visible para todos los admins
    --      INT  = solo para ese usuario especÃ­fico
    CONSTRAINT fk_alerta_usuario FOREIGN KEY (id_usuarios_destino)
        REFERENCES Usuarios(id_usuarios)
);

-- ================================================================
--  TRIGGERS
-- ================================================================

DELIMITER $$

-- ---------------------------------------------------------------
-- TRIGGER 1: Fiado â†’ descontar stock + bitÃ¡cora + alerta
-- [F6] ValidaciÃ³n de stock negativo con SIGNAL
-- [F7] Actualiza saldo_pendiente_total del cliente
-- ---------------------------------------------------------------
CREATE TRIGGER trg_detfiado_after_insert
AFTER INSERT ON Detalle_Fiado
FOR EACH ROW
BEGIN
    DECLARE stock_antes   INT;
    DECLARE stock_despues INT;
    DECLARE min_stock     INT;
    DECLARE cliente_id    INT;

    SELECT stock, stock_minimo INTO stock_antes, min_stock
    FROM Productos WHERE id_productos = NEW.id_productos;

    -- [F6] Bloquear si no hay stock suficiente
    IF stock_antes < NEW.cantidad THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Stock insuficiente: no se puede registrar el fiado';
    END IF;

    SET stock_despues = stock_antes - NEW.cantidad;

    UPDATE Productos
    SET stock = stock_despues
    WHERE id_productos = NEW.id_productos;

    -- BitÃ¡cora
    INSERT INTO Movimientos_Inventario
        (tipo_movimiento, id_productos, cantidad, stock_anterior, stock_nuevo,
         id_referencia, tabla_referencia, observacion)
    VALUES
        ('salida', NEW.id_productos, -NEW.cantidad, stock_antes, stock_despues,
         NEW.id_fiado, 'Fiado', CONCAT('Fiado #', NEW.id_fiado));

    -- [F7] Sumar el subtotal al saldo_pendiente_total del cliente
    SELECT id_cliente INTO cliente_id
    FROM Fiado WHERE id_fiado = NEW.id_fiado;

    UPDATE clientes
    SET saldo_pendiente_total = saldo_pendiente_total + (NEW.cantidad * NEW.precio_venta)
    WHERE id_cliente = cliente_id;

    -- [F9] Alerta de stock bajo con destinatario = NULL (alerta global para admins)
    IF stock_despues <= min_stock THEN
        INSERT INTO Alertas (tipo, descripcion, id_referencia, tabla_referencia, id_usuarios_destino)
        VALUES ('stock_bajo',
                CONCAT('Stock bajo: producto id=', NEW.id_productos,
                       ' â€” quedan ', stock_despues, ' unidades'),
                NEW.id_productos, 'Productos', NULL);
    END IF;
END$$

-- ---------------------------------------------------------------
-- TRIGGER 2: Venta de contado â†’ descontar stock + bitÃ¡cora
-- [F6] ValidaciÃ³n de stock negativo
-- ---------------------------------------------------------------
CREATE TRIGGER trg_detventa_after_insert
AFTER INSERT ON Detalle_Venta
FOR EACH ROW
BEGIN
    DECLARE stock_antes   INT;
    DECLARE stock_despues INT;
    DECLARE min_stock     INT;

    SELECT stock, stock_minimo INTO stock_antes, min_stock
    FROM Productos WHERE id_productos = NEW.id_productos;

    -- [F6] Bloquear si no hay stock suficiente
    IF stock_antes < NEW.cantidad THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Stock insuficiente: no se puede registrar la venta';
    END IF;

    SET stock_despues = stock_antes - NEW.cantidad;

    UPDATE Productos
    SET stock = stock_despues
    WHERE id_productos = NEW.id_productos;

    INSERT INTO Movimientos_Inventario
        (tipo_movimiento, id_productos, cantidad, stock_anterior, stock_nuevo,
         id_referencia, tabla_referencia, observacion)
    VALUES
        ('salida', NEW.id_productos, -NEW.cantidad, stock_antes, stock_despues,
         NEW.id_venta, 'Ventas', CONCAT('Venta #', NEW.id_venta));

    IF stock_despues <= min_stock THEN
        INSERT INTO Alertas (tipo, descripcion, id_referencia, tabla_referencia, id_usuarios_destino)
        VALUES ('stock_bajo',
                CONCAT('Stock bajo: producto id=', NEW.id_productos,
                       ' â€” quedan ', stock_despues, ' unidades'),
                NEW.id_productos, 'Productos', NULL);
    END IF;
END$$

-- ---------------------------------------------------------------
-- TRIGGER 3: Compra a proveedor â†’ aumentar stock + bitÃ¡cora
-- [F8] Ahora tambiÃ©n actualiza saldo_deuda del proveedor
-- ---------------------------------------------------------------
CREATE TRIGGER trg_detcompra_after_insert
AFTER INSERT ON Detalle_Compra
FOR EACH ROW
BEGIN
    DECLARE stock_antes    INT;
    DECLARE stock_despues  INT;
    DECLARE prov_id        INT;

    SELECT stock INTO stock_antes
    FROM Productos WHERE id_productos = NEW.id_productos;

    SET stock_despues = stock_antes + NEW.cantidad;

    UPDATE Productos
    SET stock = stock_despues
    WHERE id_productos = NEW.id_productos;

    INSERT INTO Movimientos_Inventario
        (tipo_movimiento, id_productos, cantidad, stock_anterior, stock_nuevo,
         id_referencia, tabla_referencia, observacion)
    VALUES
        ('entrada', NEW.id_productos, NEW.cantidad, stock_antes, stock_despues,
         NEW.id_compra, 'Compras_Proveedor', CONCAT('Compra #', NEW.id_compra));

    -- [F8] Sumar el subtotal de esta lÃ­nea al saldo_deuda del proveedor
    SELECT id_proveedores INTO prov_id
    FROM Compras_Proveedor WHERE id_compra = NEW.id_compra;

    UPDATE proveedores
    SET saldo_deuda = saldo_deuda + (NEW.cantidad * NEW.precio_costo)
    WHERE id_proveedores = prov_id;
END$$

-- ---------------------------------------------------------------
-- TRIGGER 4: Pago a cliente â†’ actualizar saldo del fiado
-- [F4] Reescrito como BEFORE INSERT para evitar Error 1442
-- [F7] TambiÃ©n reduce saldo_pendiente_total del cliente
-- ---------------------------------------------------------------
CREATE TRIGGER trg_pago_before_insert
BEFORE INSERT ON Pagos
FOR EACH ROW
BEGIN
    DECLARE saldo_actual  DECIMAL(10,2);
    DECLARE nuevo_saldo   DECIMAL(10,2);

    SELECT saldo_pendiente INTO saldo_actual
    FROM Fiado WHERE id_fiado = NEW.id_fiado;

    SET nuevo_saldo = saldo_actual - NEW.monto;

    -- Actualizar el fiado directamente dentro del BEFORE INSERT
    -- (modifica otra tabla, no la misma que dispara â†’ sin Error 1442)
    UPDATE Fiado
    SET saldo_pendiente = nuevo_saldo,
        estado     = IF(nuevo_saldo <= 0, 'Pagado', estado),
        fecha_pago = IF(nuevo_saldo <= 0, NEW.fecha_pago, fecha_pago)
    WHERE id_fiado = NEW.id_fiado;

    -- [F7] Reducir saldo_pendiente_total del cliente
    UPDATE clientes
    SET saldo_pendiente_total = GREATEST(0, saldo_pendiente_total - NEW.monto)
    -- GREATEST(0,...) evita que baje de 0 por pagos en exceso
    WHERE id_cliente = NEW.id_cliente;
END$$

-- ---------------------------------------------------------------
-- TRIGGER 5: Pago a proveedor â†’ reduce saldo en Compras y en
--            proveedores.saldo_deuda   [F3]
-- ---------------------------------------------------------------
CREATE TRIGGER trg_pagprov_before_insert
BEFORE INSERT ON Pagos_A_Proveedores
FOR EACH ROW
BEGIN
    DECLARE nuevo_saldo_compra DECIMAL(10,2);

    -- Reducir saldo_pendiente de la factura de compra
    SELECT saldo_pendiente - NEW.monto INTO nuevo_saldo_compra
    FROM Compras_Proveedor WHERE id_compra = NEW.id_compra;

    UPDATE Compras_Proveedor
    SET saldo_pendiente = nuevo_saldo_compra,
        estado = IF(nuevo_saldo_compra <= 0, 'Al dia', estado)
    WHERE id_compra = NEW.id_compra;

    -- Reducir saldo_deuda del proveedor
    UPDATE proveedores
    SET saldo_deuda = GREATEST(0, saldo_deuda - NEW.monto)
    WHERE id_proveedores = NEW.id_proveedores;
END$$

DELIMITER ;

-- ================================================================
--  VISTA: v_clientes_completo
--  Une Usuarios + clientes para que Java haga un solo SELECT
--  y obtenga nombre, correo, cupo, saldo, foto, etc.
--  Especialmente util para la tabla "Clientes con mayor deuda"
--  y la vista del cliente.
-- ================================================================
CREATE VIEW v_clientes_completo AS
SELECT
    c.id_cliente,
    u.id_usuarios,
    u.nombre,
    u.apellidos,
    CONCAT(u.nombre, ' ', u.apellidos) AS nombre_completo,
    u.identificacion,
    td.tipo_documento,
    u.correo,
    u.telefono,
    u.foto_perfil,
    u.fecha_nacimiento,
    u.acepto_terminos,
    u.fecha_acepto_terminos,
    u.telefono_verificado,
    c.cupo_credito,
    c.saldo_pendiente_total,
    (c.cupo_credito - c.saldo_pendiente_total) AS disponible_para_fiar,
    ROUND((c.saldo_pendiente_total / NULLIF(c.cupo_credito, 0)) * 100, 1) AS porcentaje_utilizado
FROM clientes c
INNER JOIN Usuarios u ON c.id_usuario = u.id_usuarios
INNER JOIN Tipo_documento td ON td.id_tipo_documento = u.id_tipo_documento;

-- ================================================================
--  VISTA: v_deuda_proveedores
--  Suma total de deuda activa a proveedores para el KPI
--  "Deuda a Proveedores $1.800.000" del panel administrativo.
-- ================================================================
CREATE VIEW v_deuda_proveedores AS
SELECT
    p.id_proveedores,
    p.razon_social,
    p.nit,
    p.saldo_deuda,
    CASE
        WHEN EXISTS (
            SELECT 1 FROM Compras_Proveedor cp
            WHERE cp.id_proveedores = p.id_proveedores
              AND cp.fecha_vence < CURDATE()
              AND cp.saldo_pendiente > 0
        ) THEN 'Vencido'
        WHEN EXISTS (
            SELECT 1 FROM Compras_Proveedor cp
            WHERE cp.id_proveedores = p.id_proveedores
              AND cp.fecha_vence BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY)
              AND cp.saldo_pendiente > 0
        ) THEN 'Proximo a vencer'
        ELSE 'Al dia'
    END AS estado_calculado
FROM proveedores p;

-- ================================================================
--  DATOS INICIALES
-- ================================================================

INSERT INTO Tipo_documento (tipo_documento)
VALUES ('Cedula de ciudadania'), ('Cedula de extranjeria'), ('Pasaporte'), ('Tarjeta de identidad');

-- [F5] roles se inserta primero para que Usuarios lo referencie
INSERT INTO roles (descripcion_roles)
VALUES ('administrador'), ('cliente');

INSERT INTO medio_pago (descripcion_medio_pago)
VALUES ('Efectivo'), ('Transferencia'), ('Nequi'), ('Daviplata');

INSERT INTO Categorias (nombre)
VALUES ('Licores'), ('Cervezas'), ('Vinos'), ('Aguardientes'), ('Rones'), ('Otros');

-- [F5]  id_roles=1 â†’ administrador
-- [F10] ContraseÃ±a hasheada con SHA2-256 como mÃ­nimo de seguridad.
--       IMPORTANTE: en Java (NetBeans) reemplazar SHA2 por BCrypt
--       antes de salir a producciÃ³n. La clave real es 'admin123'.
INSERT INTO Usuarios
    (nombre, apellidos, identificacion, id_tipo_documento, correo, telefono, clave, id_roles, foto_perfil,
     clave_expira, acepto_terminos, fecha_acepto_terminos, version_terminos)
VALUES
    ('Administrador', 'Sistema', '1234567890', 1, 'admin@neins.com', '3000000000',
     SHA2('admin123', 256), 1, NULL, DATE_ADD(CURDATE(), INTERVAL 30 DAY), TRUE, NOW(), '1.0');

INSERT INTO proveedores (razon_social, nit, telefono, correo, saldo_deuda)
VALUES
    ('Bavaria S.A.',           '860034313-7', '6012345678', 'ventas@bavaria.com',  0.00),
    ('Postobon S.A.',          '860002479-3', '6019876543', 'ventas@postobon.com', 0.00),
    ('Licores Antioquia',      '800197268-4', '6044321098', 'ventas@licant.com',   0.00),
    ('Distribuidora Nacional', '900123456-1', '6015551234', 'dist@nacional.com',   0.00);
INSERT INTO Productos (nombre, precio, stock, stock_minimo, id_categoria)
VALUES
    ('Cerveza Poker x24',   45000.00,  3,  5, 2),
    ('Aguardiente 750ml',   28000.00,  2,  5, 4),
    ('Whisky Black Label', 210000.00,  5,  3, 1),
    ('Ron Medellin 750ml',  38000.00, 18,  5, 5),
    ('Vino Tinto 750ml',    55000.00, 12,  4, 3);

-- ================================================================
--  Datos iniciales de inventario/proveedores.
--  No se insertan usuarios cliente, fiados ni pagos precargados.
-- ================================================================

INSERT INTO Compras_Proveedor (fecha_compra, fecha_vence, total, saldo_pendiente, estado, id_proveedores, id_medio_pago)
VALUES
    ('2026-05-01', '2026-05-20', 800000.00, 800000.00, 'Vencido', 1, 2),
    ('2026-05-04', '2026-06-05', 300000.00, 300000.00, 'Proximo a vencer', 2, 2),
    ('2026-05-08', '2026-05-25', 700000.00, 700000.00, 'Vencido', 3, 2);

INSERT INTO Detalle_Compra (id_compra, id_productos, cantidad, precio_costo)
VALUES
    (1, 1, 20, 40000.00),
    (2, 5,  6, 50000.00),
    (3, 3,  4, 100000.00),
    (3, 4,  5, 40000.00),
    (3, 2,  5, 20000.00);
