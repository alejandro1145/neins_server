<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@page import="Controlador.ClienteDAO, Modelo.Clientes, java.util.List"%>

<%
    boolean embedAdmin = "1".equals(request.getParameter("embed"));
    String usuario = (String) session.getAttribute("usuario");
    String rol = (String) session.getAttribute("rol");
    if (usuario == null) { response.sendRedirect("Login.jsp"); return; }
    if (!"administrador".equalsIgnoreCase(rol)) { response.sendRedirect("MenuCliente.jsp"); return; }

    ClienteDAO dao = new ClienteDAO();
    String mensaje = "";
    String tipoMsg = "";
    String accion = request.getParameter("accion");

    if ("insertar".equals(accion)) {
        try {
            Clientes c = new Clientes();
            c.setIdUsuario(Integer.parseInt(request.getParameter("id_usuario")));
            c.setCupo_credito(request.getParameter("Credito"));
            if (dao.insertar(c)) { mensaje = "Cliente activado correctamente"; tipoMsg = "exito"; }
            else { mensaje = "No se pudo activar el cliente"; tipoMsg = "error"; }
        } catch (Exception ex) {
            mensaje = "Selecciona un usuario cliente valido"; tipoMsg = "error";
        }
    }

    if ("actualizar".equals(accion)) {
        Clientes c = new Clientes();
        c.setId_clientes(Integer.parseInt(request.getParameter("id")));
        c.setCupo_credito(request.getParameter("Credito"));
        if (dao.actualizar(c)) { mensaje = "Cupo actualizado correctamente"; tipoMsg = "exito"; }
        else { mensaje = "Error al actualizar cupo"; tipoMsg = "error"; }
    }

    if ("eliminar".equals(accion)) {
        int id = Integer.parseInt(request.getParameter("id"));
        if (dao.eliminar(id)) { mensaje = "Ficha de cliente eliminada"; tipoMsg = "exito"; }
        else { mensaje = "No se pudo eliminar: revisa si tiene fiados asociados"; tipoMsg = "error"; }
    }

    Clientes editando = null;
    if ("editar".equals(accion)) {
        int idEdit = Integer.parseInt(request.getParameter("id"));
        for (Clientes cx : dao.listar()) {
            if (cx.getId_clientes() == idEdit) { editando = cx; break; }
        }
    }

    List<Clientes> lista = dao.listar();
    List<Clientes> disponibles = dao.listarUsuariosClienteSinFicha();
    String embedParam = embedAdmin ? "?embed=1" : "";
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Clientes - Neins</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Poppins:wght@600;700&display=swap" rel="stylesheet">
    <style>
        :root{--bg:#0B0E14;--card:#121620;--field:#171C28;--gold:#D4A373;--gold2:#E6B863;--gold3:#B38637;--text:#FFFFFF;--muted:#8E9AA8;--line:#232B3E;--red:#E63946;--green:#2A9D8F}
        *{box-sizing:border-box;margin:0;padding:0}
        body{min-height:100vh;background:var(--bg);color:var(--text);font-family:Inter,sans-serif;padding:32px}
        body.embed{padding:24px 28px}
        .page-header{display:flex;align-items:center;justify-content:space-between;margin-bottom:24px}
        h1{font-family:Poppins,sans-serif;font-size:22px;color:var(--gold);text-transform:uppercase}
        .sub{font-size:13px;color:var(--muted);margin-top:4px}
        .back-link{color:var(--muted);text-decoration:none;font-size:13px}
        .back-link:hover{color:var(--gold)}
        .layout{display:grid;grid-template-columns:1fr;gap:24px;align-items:start}
        .panel{background:var(--card);border:1px solid var(--line);border-radius:8px;overflow:hidden}
        .panel-header{padding:18px 22px 14px;border-bottom:1px solid var(--line)}
        .panel-title{font-weight:700;font-size:14px}
        .panel-sub{font-size:12px;color:var(--muted);margin-top:3px}
        .panel-body{padding:22px}
        .msg{padding:11px 14px;border-radius:8px;font-size:13px;margin-bottom:16px}
        .msg-exito{background:rgba(42,157,143,.12);border:1px solid rgba(42,157,143,.35);color:var(--green)}
        .msg-error{background:rgba(230,57,70,.12);border:1px solid rgba(230,57,70,.35);color:var(--red)}
        .badge-edit{display:inline-flex;margin-bottom:16px;padding:5px 12px;border-radius:999px;background:rgba(212,163,115,.1);border:1px solid rgba(212,163,115,.35);color:var(--gold);font-size:12px}
        label{display:block;font-size:12px;color:var(--muted);margin-bottom:7px;text-transform:uppercase;letter-spacing:.4px}
        input,select{width:100%;background:var(--field);border:1px solid var(--line);border-radius:6px;padding:11px 14px;color:var(--text);font-size:14px;font-family:Inter,sans-serif;outline:none}
        input:focus,select:focus{border-color:var(--gold);box-shadow:0 0 5px rgba(212,163,115,.3)}
        input[readonly]{color:var(--muted)}
        .form-group{margin-bottom:16px}
        .btn-row{display:flex;gap:10px;margin-top:20px}
        .btn-primary{flex:1;border:0;border-radius:8px;padding:12px;background:linear-gradient(90deg,var(--gold2),var(--gold3));color:#000;font-weight:700;cursor:pointer}
        .btn-secondary,.btn-cancelar{border:1px solid var(--gold);border-radius:8px;padding:12px 16px;background:transparent;color:var(--text);text-decoration:none;cursor:pointer}
        .btn-secondary:hover,.btn-cancelar:hover{background:var(--gold);color:#000}
        .table-wrap{overflow-x:auto}
        table{width:100%;border-collapse:collapse}
        th{padding:11px 16px;text-align:left;color:var(--muted);font-size:11px;text-transform:uppercase;border-bottom:1px solid var(--line)}
        td{padding:12px 16px;font-size:13px;border-bottom:1px solid #1C2333}
        tr:hover td{background:rgba(212,163,115,.04)}
        .muted{color:var(--muted)}
        .gold{color:var(--gold);font-weight:700}
        .red{color:var(--red);font-weight:700}
        .actions{display:flex;gap:8px}
        .btn-edit,.btn-del{border:1px solid;border-radius:6px;padding:6px 12px;background:transparent;font-size:12px;cursor:pointer}
        .btn-edit{border-color:var(--gold);color:var(--gold)}
        .btn-del{border-color:var(--red);color:var(--red)}
        .btn-edit:hover{background:var(--gold);color:#000}
        .btn-del:hover{background:var(--red);color:#fff}
        .empty td{text-align:center;color:var(--muted);padding:32px}
        @media(max-width:900px){.layout{grid-template-columns:1fr}.page-header{align-items:flex-start;gap:12px;flex-direction:column}}
    </style>
    <link rel="stylesheet" href="../Estilos/global.css">
</head>
<body class="<%= embedAdmin ? "embed" : "" %>">
    <div class="page-header">
        <div>
            <h1>Clientes</h1>
            <p class="sub">Cupos de credito conectados a Usuarios y a la vista v_clientes_completo</p>
        </div>
        <% if (!embedAdmin) { %><a href="MenuAdmin.jsp" class="back-link">Volver al panel</a><% } %>
    </div>

    <div class="layout">
        <section class="panel">
            <div class="panel-header">
                <div class="panel-title">Clientes registrados</div>
                <div class="panel-sub"><%= lista.size() %> clientes activos. El cupo se gestiona desde Fiados; aquí solo se consulta su perfil, saldo e historial.</div>
            </div>
            <div class="table-wrap">
                <table>
                    <thead>
                        <tr><th>#</th><th>Nombre</th><th>Telefono</th><th>Documento</th><th>Cupo</th><th>Deuda</th><th>Acciones</th></tr>
                    </thead>
                    <tbody>
                        <% if (lista.isEmpty()) { %>
                            <tr class="empty"><td colspan="7">No hay clientes registrados aun</td></tr>
                        <% } else { for (Clientes c : lista) { %>
                            <tr>
                                <td class="muted">#<%= c.getId_clientes() %></td>
                                <td><strong><%= c.getNombreCompleto() %></strong><br><span class="muted"><%= c.getCorreo() %></span></td>
                                <td class="muted"><%= c.getTelefono() %></td>
                                <td class="muted"><%= c.getIdentificacion() %></td>
                                <td class="gold">$ <%= c.getCupo_credito() %></td>
                                <td class="<%= !"0.00".equals(c.getSaldoPendienteTotal()) ? "red" : "muted" %>">$ <%= c.getSaldoPendienteTotal() %></td>
                                <td><a class="btn-edit" href="ClienteHistorial.jsp?id=<%= c.getId_clientes() %><%= embedAdmin ? "&embed=1" : "" %>">Ver historial y cupo</a></td>
                            </tr>
                        <% } } %>
                    </tbody>
                </table>
            </div>
        </section>
    </div>
    <script src="../Scripts/premium-ui.js"></script>
</body>
</html>
