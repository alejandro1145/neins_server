<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@page import="Controlador.UsuariosDAO, Controlador.Conexion, Modelo.Usuarios"%>
<%@page import="Controlador.RolesDAO, Modelo.Roles"%>
<%@page import="Controlador.TipoDocumentoDAO, Modelo.Tipo_documento"%>
<%@page import="java.sql.Connection, java.time.LocalDate, java.util.List"%>

<%
    final int DIAS_EXPIRACION_CLAVE = 30;
    boolean embedAdmin = "1".equals(request.getParameter("embed"));
    String usuarioSesion = (String) session.getAttribute("usuario");
    String rolSesion = (String) session.getAttribute("rol");

    if (usuarioSesion != null && !"administrador".equals(rolSesion)) {
        response.sendRedirect("MenuCliente.jsp");
        return;
    }
    boolean esAdmin = "administrador".equals(rolSesion);

    String errorConexion = null;
    try {
        Conexion testCon = new Conexion();
        Connection conn = testCon.getConnection();
        if (conn == null) errorConexion = "La conexion devolvio null. Revisa Conexion.java";
        else conn.close();
    } catch (Exception ex) {
        errorConexion = "Error de BD: " + ex.getMessage();
    }

    List<Roles> listaRoles = new java.util.ArrayList<>();
    List<Tipo_documento> listaTipos = new java.util.ArrayList<>();
    if (errorConexion == null) {
        try {
            listaRoles = new RolesDAO().listar();
            listaTipos = new TipoDocumentoDAO().listar();
        } catch (Exception ex) { }
    }

    UsuariosDAO dao = new UsuariosDAO();
    String mensaje = "";
    String tipoMsg = "";
    String accion = request.getParameter("accion");

    if ("insertar".equals(accion) && errorConexion == null) {
        String nombre = request.getParameter("nombre");
        String apellido = request.getParameter("Apellidos");
        String identificacion = request.getParameter("Identificacion");
        String tipoDocumento = request.getParameter("id_tipo_documento");
        String correo = request.getParameter("Correo");
        String telefono = request.getParameter("Telefono");
        String clave = request.getParameter("password");
        String codigoCorreo = request.getParameter("codigo_correo");
        boolean aceptoTerminos = "on".equals(request.getParameter("acepto_terminos"));
        String rol = esAdmin ? request.getParameter("rol") : "cliente";

        String correoSesion = (String) session.getAttribute("registroCorreo");
        String codigoSesion = (String) session.getAttribute("registroCodigo");
        Long expiraCodigo = (Long) session.getAttribute("registroCodigoExpira");
        boolean codigoOk = esAdmin || (
                correoSesion != null && codigoSesion != null && expiraCodigo != null &&
                correoSesion.equalsIgnoreCase(correo != null ? correo.trim() : "") &&
                codigoSesion.equals(codigoCorreo != null ? codigoCorreo.trim() : "") &&
                System.currentTimeMillis() <= expiraCodigo
        );

        if (nombre == null || nombre.trim().isEmpty() ||
            apellido == null || apellido.trim().isEmpty() ||
            identificacion == null || identificacion.trim().isEmpty() ||
            correo == null || correo.trim().isEmpty() ||
            telefono == null || telefono.trim().isEmpty() ||
            clave == null || clave.trim().isEmpty()) {
            mensaje = "Todos los campos son obligatorios.";
            tipoMsg = "error";
        } else if (!identificacion.trim().matches("[1-9][0-9]{9}")) {
            mensaje = "El documento debe tener 10 digitos y no puede iniciar en cero.";
            tipoMsg = "error";
        } else if (!telefono.trim().matches("3[0-9]{9}")) {
            mensaje = "El telefono debe ser celular colombiano de 10 digitos, por ejemplo 3001234567.";
            tipoMsg = "error";
        } else if (!codigoOk) {
            mensaje = "Verifica tu correo con el codigo enviado antes de crear la cuenta.";
            tipoMsg = "error";
        } else if (!aceptoTerminos) {
            mensaje = "Debes aceptar los terminos, condiciones y tratamiento de datos.";
            tipoMsg = "error";
        } else {
            String dup = dao.validarDuplicado(correo, telefono, identificacion);
            if (dup != null) {
                mensaje = "Ya existe un usuario con ese " + dup + ".";
                tipoMsg = "error";
            } else {
                Usuarios u = new Usuarios();
                u.setNombre(nombre.trim());
                u.setApellido(apellido.trim());
                u.setIdentificacion(identificacion.trim());
                u.setIdTipoDocumento(tipoDocumento != null && !tipoDocumento.isEmpty() ? Integer.parseInt(tipoDocumento) : 1);
                u.setCorreo(correo.trim());
                u.setTelefono(telefono.trim());
                u.setClave(clave);
                u.setRol(rol != null ? rol : "cliente");
                u.setFechaNacimiento(null);
                u.setClaveExpira(LocalDate.now().plusDays(DIAS_EXPIRACION_CLAVE).toString());
                u.setAceptoTerminos(true);
                u.setIpAceptoTerminos(request.getRemoteAddr());
                u.setVersionTerminos("1.0");

                if (dao.insertar(u)) {
                    session.removeAttribute("registroCorreo");
                    session.removeAttribute("registroCodigo");
                    session.removeAttribute("registroCodigoExpira");
                    if (!esAdmin) {
                        response.sendRedirect(request.getContextPath() + "/index.html?registrado=1");
                        return;
                    }
                    mensaje = "Usuario registrado correctamente.";
                    tipoMsg = "exito";
                } else {
                    mensaje = "Error al guardar. Revisa el log del servidor.";
                    tipoMsg = "error";
                }
            }
        }
    }

    if ("actualizar".equals(accion) && errorConexion == null) {
        Usuarios u = new Usuarios();
        u.setId_usuarios(Integer.parseInt(request.getParameter("id")));
        u.setNombre(request.getParameter("nombre").trim());
        u.setApellido(request.getParameter("Apellidos").trim());
        u.setIdentificacion(request.getParameter("Identificacion").trim());
        String tipoDocumentoEdit = request.getParameter("id_tipo_documento");
        u.setIdTipoDocumento(tipoDocumentoEdit != null && !tipoDocumentoEdit.isEmpty() ? Integer.parseInt(tipoDocumentoEdit) : 1);
        u.setCorreo(request.getParameter("Correo").trim());
        u.setTelefono(request.getParameter("Telefono").trim());
        u.setClave(request.getParameter("password"));
        u.setRol(request.getParameter("rol") != null ? request.getParameter("rol") : "cliente");
        u.setFechaNacimiento(null);
        u.setClaveExpira(LocalDate.now().plusDays(DIAS_EXPIRACION_CLAVE).toString());
        u.setAceptoTerminos("on".equals(request.getParameter("acepto_terminos")));
        u.setIpAceptoTerminos(request.getRemoteAddr());
        u.setVersionTerminos("1.0");
        String dupEdit = dao.validarDuplicadoEdicion(u.getId_usuarios(), u.getCorreo(), u.getTelefono(), u.getIdentificacion());
        if (!u.getIdentificacion().matches("[1-9][0-9]{9}")) {
            mensaje = "El documento debe tener 10 digitos y no puede iniciar en cero.";
            tipoMsg = "error";
        } else if (!u.getTelefono().matches("3[0-9]{9}")) {
            mensaje = "El telefono debe ser celular colombiano de 10 digitos.";
            tipoMsg = "error";
        } else if (!u.isAceptoTerminos()) {
            mensaje = "El usuario debe tener aceptados los terminos y tratamiento de datos.";
            tipoMsg = "error";
        } else if (dupEdit != null) {
            mensaje = "Ya existe otro usuario con ese " + dupEdit + ".";
            tipoMsg = "error";
        } else if (dao.actualizar(u)) {
            mensaje = "Usuario actualizado correctamente.";
            tipoMsg = "exito";
        } else {
            mensaje = "Error al actualizar.";
            tipoMsg = "error";
        }
    }

    if ("eliminar".equals(accion) && errorConexion == null) {
        int id = Integer.parseInt(request.getParameter("id"));
        if (dao.eliminar(id)) { mensaje = "Usuario eliminado correctamente."; tipoMsg = "exito"; }
        else { mensaje = "Error al eliminar."; tipoMsg = "error"; }
    }

    Usuarios editando = null;
    if ("editar".equals(accion)) {
        int idEdit = Integer.parseInt(request.getParameter("id"));
        for (Usuarios ux : dao.listar()) {
            if (ux.getId_usuarios() == idEdit) { editando = ux; break; }
        }
    }
    List<Usuarios> listaUsuarios = esAdmin ? dao.listar() : null;
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Usuarios - Neins</title>
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@600;700&family=DM+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="../Estilos/global.css">
    <style>
        :root {
            --bg:#101115; --panel:#171a21; --panel2:#11141b; --gold:#d8a93d; --gold2:#f0c96a;
            --text:#f4f0e7; --muted:#9da8bc; --line:rgba(216,169,61,.24); --red:#ff6b6b; --green:#64d18a;
        }
        *{box-sizing:border-box} body{margin:0;min-height:100vh;background:radial-gradient(circle at top left,rgba(216,169,61,.10),transparent 34%),var(--bg);font-family:'DM Sans',sans-serif;color:var(--text)}
        body:not(.embed-admin){display:flex;justify-content:center;align-items:flex-start;padding:42px 18px} body.embed-admin{background:transparent;padding:24px}
        .page-wrap{width:100%;display:flex;flex-direction:column;align-items:center;gap:26px}.page-header{text-align:center}.page-header h1{font-family:'Playfair Display',serif;color:var(--gold);font-size:30px}.page-header p{color:var(--muted);font-size:12px;text-transform:uppercase;letter-spacing:2px}
        .card,.table-card{width:100%;max-width:920px;background:rgba(23,26,33,.96);border:1px solid var(--line);border-radius:16px;box-shadow:0 24px 70px rgba(0,0,0,.46)}.card{max-width:760px;padding:30px}.card-title{font-family:'Playfair Display',serif;font-size:24px;margin-bottom:8px}.hint{color:var(--muted);font-size:13px;margin-bottom:24px}
        .form-grid{display:grid;grid-template-columns:1fr 1fr;gap:16px}.full{grid-column:1/-1}.form-group{display:flex;flex-direction:column;gap:7px}label{font-size:12px;text-transform:uppercase;letter-spacing:.7px;color:#adc0df;font-weight:700}
        input,select{width:100%;min-height:43px;border-radius:9px;border:1px solid rgba(173,192,223,.18);background:#10141f;color:var(--text);padding:11px 13px;font:inherit}input:focus,select:focus{outline:0;border-color:var(--gold);box-shadow:0 0 0 3px rgba(216,169,61,.15)}select option{background:#10141f;color:var(--text)}
        .verify-row{display:grid;grid-template-columns:1fr auto;gap:10px}.btn-mini,.btn-primary,.btn-secondary,.btn-edit,.btn-del{border-radius:9px;border:1px solid var(--line);font:inherit;font-weight:700;cursor:pointer}.btn-mini{background:#24202a;color:var(--gold2);padding:0 14px}.btn-primary{flex:1;background:linear-gradient(135deg,#f0c96a,#c8942e);color:#120f08;border:0;padding:14px}.btn-secondary{background:transparent;color:var(--text);padding:13px 18px}.btn-row{display:flex;gap:12px;margin-top:24px}.btn-edit{background:transparent;color:var(--gold);padding:6px 10px}.btn-del{background:transparent;color:var(--red);border-color:rgba(255,107,107,.35);padding:6px 10px}
        .alert{padding:13px 15px;border-radius:10px;margin-bottom:18px;font-size:14px}.alert-error{background:rgba(255,107,107,.12);border:1px solid rgba(255,107,107,.32);color:#ffb0b0}.alert-ok{background:rgba(100,209,138,.12);border:1px solid rgba(100,209,138,.32);color:#9df0b6}.alert-warn{background:rgba(216,169,61,.12);border:1px solid var(--line);color:#ffe0a0}
        .terms-box{display:grid;grid-template-columns:24px 1fr;gap:14px;padding:18px;border-radius:14px;background:linear-gradient(135deg,rgba(216,169,61,.13),rgba(255,255,255,.03));border:1px solid var(--line)}.terms-box input{width:18px;min-height:18px;accent-color:var(--gold);margin-top:3px}.terms-title{font-weight:800;color:var(--gold2);margin-bottom:6px}.terms-copy{color:#c8d2e3;font-size:13px;line-height:1.55}.legal-note{grid-column:1/-1;color:#aeb8c8;font-size:12px;line-height:1.45;background:rgba(0,0,0,.16);border-radius:10px;padding:12px}
        .back-link{text-align:center;margin-top:18px}.back-link a{color:var(--gold2);text-decoration:none}.table-card{overflow:auto}.table-header{display:flex;justify-content:space-between;align-items:center;padding:18px 20px;border-bottom:1px solid var(--line)}table{width:100%;border-collapse:collapse}th,td{padding:11px 13px;text-align:left;border-bottom:1px solid rgba(255,255,255,.06);font-size:13px}th{color:var(--muted);text-transform:uppercase;font-size:11px}.badge{display:inline-flex;border-radius:999px;padding:4px 9px;background:rgba(216,169,61,.12);color:var(--gold2);font-weight:700}
        @media(max-width:700px){.card{padding:22px 16px}.form-grid,.verify-row{grid-template-columns:1fr}.btn-row{flex-direction:column}}
    </style>
</head>
<body class="<%= embedAdmin ? "embed-admin" : "" %>">
<div class="page-wrap">
    <% if (!embedAdmin) { %>
    <div class="page-header"><h1>Neins</h1><p>Gestion de usuarios</p></div>
    <% } %>

    <div class="card">
        <div class="card-title"><%= (editando != null) ? "Editar usuario" : (esAdmin ? "Registrar usuario" : "Crear cuenta") %></div>
        <div class="hint">La clave vence automaticamente <%= DIAS_EXPIRACION_CLAVE %> dias despues del registro. No se elige manualmente.</div>

        <% if (errorConexion != null) { %><div class="alert alert-warn"><strong>Sin conexion:</strong> <%= errorConexion %></div><% } %>
        <% if (!mensaje.isEmpty()) { %><div class="alert <%= "exito".equals(tipoMsg) ? "alert-ok" : "alert-error" %>"><%= mensaje %></div><% } %>

        <form action="RegistroUsuario.jsp" method="post">
            <% if (editando != null) { %>
                <input type="hidden" name="accion" value="actualizar"><input type="hidden" name="id" value="<%= editando.getId_usuarios() %>">
            <% } else { %>
                <input type="hidden" name="accion" value="insertar">
            <% } %>

            <div class="form-grid">
                <div class="form-group"><label>Nombres</label><input type="text" name="nombre" required placeholder="Ej: Carlos" value="<%= (editando != null) ? editando.getNombre() : "" %>"></div>
                <div class="form-group"><label>Apellidos</label><input type="text" name="Apellidos" required placeholder="Ej: Garcia Lopez" value="<%= (editando != null) ? editando.getApellido() : "" %>"></div>
                <div class="form-group"><label>Numero de documento</label><input type="text" name="Identificacion" required pattern="[1-9][0-9]{9}" maxlength="10" inputmode="numeric" placeholder="Ej: 1234567890" value="<%= (editando != null) ? editando.getIdentificacion() : "" %>"></div>
                <div class="form-group"><label>Tipo de documento</label><select name="id_tipo_documento" required>
                    <% if (listaTipos.isEmpty()) { %><option value="1">Cedula de ciudadania</option><% } else { for (Tipo_documento td : listaTipos) { boolean sel = editando != null && editando.getIdTipoDocumento() == td.getId_tipo_documento(); %>
                    <option value="<%= td.getId_tipo_documento() %>" <%= sel ? "selected" : "" %>><%= td.getTipo_documento() %></option><% } } %>
                </select></div>
                <div class="form-group"><label>Telefono</label><input type="text" name="Telefono" required pattern="3[0-9]{9}" maxlength="10" inputmode="numeric" placeholder="Ej: 3001234567" value="<%= (editando != null) ? editando.getTelefono() : "" %>"></div>
                <div class="form-group"><label>Correo electronico</label><div class="verify-row"><input type="email" id="correo" name="Correo" required placeholder="usuario@correo.com" value="<%= (editando != null) ? editando.getCorreo() : "" %>"><button type="button" class="btn-mini" id="btnCodigo" <%= (editando != null || esAdmin) ? "disabled" : "" %>>Enviar codigo</button></div></div>
                <% if (!esAdmin && editando == null) { %>
                <div class="form-group"><label>Codigo de verificacion</label><input type="text" name="codigo_correo" id="codigoCorreo" required maxlength="6" inputmode="numeric" placeholder="6 digitos"></div>
                <% } %>
                <div class="form-group <%= esAdmin ? "" : "full" %>"><label>Contrasena</label><input type="password" name="password" <%= editando == null ? "required" : "" %> minlength="6" placeholder="<%= editando != null ? "Dejar vacio mantiene la actual" : "Minimo 6 caracteres" %>"></div>
                <% if (esAdmin) { %>
                <div class="form-group"><label>Rol</label><select name="rol">
                    <% if (listaRoles.isEmpty()) { %><option value="cliente">Cliente</option><option value="administrador">Administrador</option><% } else { for (Roles rr : listaRoles) { String val = rr.getDescrpcion_roles().toLowerCase(); boolean sel = editando != null && val.equals(editando.getRol()); %>
                    <option value="<%= val %>" <%= sel ? "selected" : "" %>><%= rr.getDescrpcion_roles() %></option><% } } %>
                </select></div>
                <% } %>
                <div class="form-group full"><label>Tratamiento de datos y credito</label><div class="terms-box">
                    <input type="checkbox" name="acepto_terminos" <%= (editando != null && editando.isAceptoTerminos()) ? "checked" : "" %> required>
                    <div><div class="terms-title">Acepto los terminos y condiciones de Una Pa' La Sed.</div><div class="terms-copy">Autorizo el tratamiento de mis datos personales conforme a la Ley 1581 de 2012. Tambien autorizo que la informacion relacionada con creditos o fiados sea tratada conforme a la Ley 1266 de 2008, incluyendo seguimiento de pagos, cobros respetuosos y conservacion de esta aceptacion como mensaje de datos.</div></div>
                    <div class="legal-note">Esta autorizacion no permite descuentos automaticos de cuentas bancarias ni multas automaticas. Cualquier debito requiere autorizacion bancaria expresa y los cobros deben respetar los canales y horarios permitidos por la Ley 2300 de 2023.</div>
                </div></div>
            </div>

            <div class="btn-row">
                <% if (errorConexion == null) { %>
                    <button type="submit" class="btn-primary"><%= editando != null ? "Guardar cambios" : (esAdmin ? "Registrar usuario" : "Crear cuenta") %></button>
                    <% if (editando != null) { %><a href="RegistroUsuario.jsp" class="btn-secondary">Cancelar</a><% } else { %><button type="reset" class="btn-secondary">Limpiar</button><% } %>
                <% } else { %><button type="button" class="btn-primary" disabled>Sin conexion</button><% } %>
            </div>
        </form>
        <div class="back-link"><a href="<%= esAdmin ? "MenuAdmin.jsp" : request.getContextPath() + "/index.html" %>">Volver</a></div>
    </div>

    <% if (esAdmin && listaUsuarios != null) { %>
    <div class="table-card">
        <div class="table-header"><div><strong>Usuarios registrados</strong><br><span style="color:var(--muted);font-size:12px;">Solo aparece lo que existe en la base actual</span></div><span class="badge"><%= listaUsuarios.size() %> usuarios</span></div>
        <table><thead><tr><th>ID</th><th>Nombre</th><th>Documento</th><th>Correo</th><th>Telefono</th><th>Rol</th><th>Clave vence</th><th>Acciones</th></tr></thead><tbody>
        <% if (listaUsuarios.isEmpty()) { %><tr><td colspan="8" style="text-align:center;color:var(--muted);padding:28px;">No hay usuarios registrados.</td></tr><% } else { for (Usuarios u : listaUsuarios) { %>
        <tr><td>#<%= u.getId_usuarios() %></td><td><strong><%= u.getNombre() %> <%= u.getApellido() %></strong></td><td><%= u.getIdentificacion() %></td><td><%= u.getCorreo() %></td><td><%= u.getTelefono() %></td><td><span class="badge"><%= u.getRol() %></span></td><td><%= u.getClaveExpira() != null ? u.getClaveExpira() : "Automatico" %></td><td>
            <form action="RegistroUsuario.jsp" method="post" style="display:inline"><input type="hidden" name="accion" value="editar"><input type="hidden" name="id" value="<%= u.getId_usuarios() %>"><button class="btn-edit">Editar</button></form>
            <form action="RegistroUsuario.jsp" method="post" style="display:inline" onsubmit="return confirm('Eliminar usuario?');"><input type="hidden" name="accion" value="eliminar"><input type="hidden" name="id" value="<%= u.getId_usuarios() %>"><button class="btn-del">Eliminar</button></form>
        </td></tr><% } } %>
        </tbody></table>
    </div>
    <% } %>
</div>

<script>
(function () {
    var btn = document.getElementById('btnCodigo');
    var correo = document.getElementById('correo');
    if (!btn || !correo) return;
    btn.addEventListener('click', function () {
        if (!correo.value) { alert('Escribe tu correo primero.'); return; }
        btn.disabled = true;
        btn.textContent = 'Enviando...';
        fetch('<%= request.getContextPath() %>/EmailVerificationServlet', {
            method: 'POST',
            headers: {'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8'},
            body: 'correo=' + encodeURIComponent(correo.value)
        }).then(function (r) { return r.json(); }).then(function (data) {
            if (data.ok) {
                alert('Codigo generado. En modo desarrollo es: ' + data.devCode);
                var input = document.getElementById('codigoCorreo');
                if (input) input.focus();
            } else {
                alert(data.message || 'No se pudo generar el codigo.');
            }
        }).catch(function () {
            alert('No se pudo contactar el servidor.');
        }).finally(function () {
            btn.disabled = false;
            btn.textContent = 'Enviar codigo';
        });
    });
})();
</script>
<script src="../Scripts/premium-ui.js"></script>
</body>
</html>
