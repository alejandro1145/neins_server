USE Neins;

ALTER TABLE Usuarios
    ADD COLUMN fecha_nacimiento DATE NULL AFTER foto_perfil,
    ADD COLUMN clave_expira DATE NULL AFTER fecha_nacimiento,
    ADD COLUMN acepto_terminos TINYINT(1) NOT NULL DEFAULT 0 AFTER clave_expira,
    ADD COLUMN fecha_acepto_terminos DATETIME NULL AFTER acepto_terminos,
    ADD COLUMN ip_acepto_terminos VARCHAR(45) NULL AFTER fecha_acepto_terminos,
    ADD COLUMN version_terminos VARCHAR(10) NOT NULL DEFAULT '1.0' AFTER ip_acepto_terminos,
    ADD COLUMN telefono_verificado TINYINT(1) NOT NULL DEFAULT 0 AFTER version_terminos,
    ADD COLUMN otp_codigo VARCHAR(6) NULL AFTER telefono_verificado,
    ADD COLUMN otp_expira DATETIME NULL AFTER otp_codigo;

CREATE OR REPLACE VIEW v_clientes_completo AS
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

