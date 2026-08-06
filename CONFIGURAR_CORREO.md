# Configurar el correo de verificación

El proyecto ya no muestra el código en pantalla. Para enviar códigos reales, define estas variables de entorno en el servidor donde se ejecuta GlassFish y reinícialo:

```text
NEINS_SMTP_HOST=smtp.gmail.com
NEINS_SMTP_PORT=587
NEINS_SMTP_USER=correo-del-negocio@gmail.com
NEINS_SMTP_PASSWORD=contraseña-de-aplicación
NEINS_SMTP_FROM=correo-del-negocio@gmail.com
```

Para Gmail usa una **contraseña de aplicación**, no la contraseña normal de la cuenta. También puedes usar el SMTP de tu proveedor de correo; cambia host, puerto y credenciales según sus datos.

No subas estas variables ni una contraseña al repositorio. El código solo guarda el código de seis dígitos en la sesión durante 10 minutos y lo guarda únicamente después de que el servicio SMTP confirma el envío.
