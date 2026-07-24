<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@page import="Controlador.TipoDocumentoDAO, Modelo.Tipo_documento, java.util.List"%>

<% boolean embedAdmin = "1".equals(request.getParameter("embed")); %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tipo de Documento — Neins</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Cinzel:wght@500;700&family=Inter:wght@300;400;500;600&display=swap" rel="stylesheet">
    <style>
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

        body {
            font-family: 'Inter', sans-serif;
            background: #0a0a0f;
            color: #e0d4b4;
            display: flex;
            min-height: 100vh;
        }

        /* ── SIDEBAR ── */
        .sidebar {
            width: 260px;
            min-height: 100vh;
            background: linear-gradient(180deg, #0d0d1a 0%, #0a0a0f 100%);
            border-right: 1px solid rgba(212,175,55,0.15);
            display: flex;
            flex-direction: column;
            padding: 0;
            position: fixed;
            top: 0; left: 0;
            z-index: 100;
        }

        .sidebar-brand {
            padding: 28px 24px 20px;
            border-bottom: 1px solid rgba(212,175,55,0.15);
        }
        .sidebar-brand h2 {
            font-family: 'Cinzel', serif;
            color: #d4af37;
            font-size: 1.4rem;
            letter-spacing: 2px;
        }
        .sidebar-brand p {
            color: rgba(212,175,55,0.5);
            font-size: 0.75rem;
            margin-top: 4px;
        }

        .sidebar-nav { padding: 20px 0; flex: 1; }

        .nav-section-title {
            padding: 8px 24px;
            font-size: 0.65rem;
            letter-spacing: 2px;
            color: rgba(212,175,55,0.4);
            text-transform: uppercase;
            margin-top: 8px;
        }

        .nav-item {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 11px 24px;
            color: rgba(224,212,180,0.7);
            text-decoration: none;
            font-size: 0.9rem;
            transition: all 0.25s;
            border-left: 3px solid transparent;
        }
        .nav-item:hover {
            background: rgba(212,175,55,0.08);
            color: #d4af37;
            border-left-color: rgba(212,175,55,0.4);
        }
        .nav-item.active {
            background: rgba(212,175,55,0.12);
            color: #d4af37;
            border-left-color: #d4af37;
            font-weight: 600;
        }
        .nav-item .icon { width: 18px; text-align: center; font-size: 1rem; }

        .sidebar-footer {
            padding: 20px 24px;
            border-top: 1px solid rgba(212,175,55,0.15);
        }
        .btn-logout {
            display: block;
            width: 100%;
            padding: 10px;
            background: transparent;
            border: 1px solid rgba(192,57,43,0.5);
            color: #e74c3c;
            border-radius: 8px;
            cursor: pointer;
            font-size: 0.85rem;
            text-align: center;
            text-decoration: none;
            transition: all 0.3s;
        }
        .btn-logout:hover { background: rgba(192,57,43,0.15); border-color: #e74c3c; }

        /* ── MAIN ── */
        .main-content {
            margin-left: 260px;
            flex: 1;
            padding: 40px;
            max-width: calc(100vw - 260px);
        }

        .page-header {
            margin-bottom: 32px;
            padding-bottom: 20px;
            border-bottom: 1px solid rgba(212,175,55,0.15);
        }
        .page-header h1 {
            font-family: 'Cinzel', serif;
            font-size: 1.8rem;
            color: #d4af37;
            letter-spacing: 1px;
        }
        .page-header p { color: rgba(224,212,180,0.5); margin-top: 6px; font-size: 0.9rem; }

        /* ── LAYOUT DOS COLUMNAS ── */
        .layout {
            display: grid;
            grid-template-columns: 380px 1fr;
            gap: 32px;
            align-items: start;
        }

        /* ── FORM CARD ── */
        .form-card {
            background: rgba(255,255,255,0.03);
            border: 1px solid rgba(212,175,55,0.2);
            border-radius: 16px;
            padding: 28px;
        }
        .form-card h2 {
            font-family: 'Cinzel', serif;
            color: #d4af37;
            font-size: 1.1rem;
            margin-bottom: 22px;
            letter-spacing: 1px;
        }

        .edit-badge {
            display: inline-block;
            background: rgba(212,175,55,0.15);
            border: 1px solid rgba(212,175,55,0.4);
            color: #d4af37;
            padding: 6px 14px;
            border-radius: 20px;
            font-size: 0.8rem;
            margin-bottom: 18px;
        }

        .form-group { margin-bottom: 18px; }
        .form-group label {
            display: block;
            font-size: 0.82rem;
            color: rgba(212,175,55,0.8);
            margin-bottom: 7px;
            letter-spacing: 0.5px;
        }
        .form-group input[type="text"] {
            width: 100%;
            padding: 10px 14px;
            background: rgba(255,255,255,0.05);
            border: 1px solid rgba(212,175,55,0.2);
            border-radius: 8px;
            color: #e0d4b4;
            font-size: 0.9rem;
            font-family: 'Inter', sans-serif;
            transition: border-color 0.3s;
            outline: none;
        }
        .form-group input[type="text"]:focus {
            border-color: #d4af37;
            background: rgba(212,175,55,0.05);
        }

        /* Opciones rápidas tipo chips */
        .chip-options {
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
            margin-top: 6px;
        }
        .chip {
            padding: 6px 14px;
            background: rgba(255,255,255,0.04);
            border: 1px solid rgba(212,175,55,0.2);
            border-radius: 20px;
            color: rgba(224,212,180,0.7);
            font-size: 0.82rem;
            cursor: pointer;
            transition: all 0.25s;
            user-select: none;
        }
        .chip:hover {
            background: rgba(212,175,55,0.12);
            border-color: #d4af37;
            color: #d4af37;
        }

        .divider {
            text-align: center;
            color: rgba(212,175,55,0.3);
            font-size: 0.75rem;
            margin: 14px 0;
            position: relative;
        }
        .divider::before, .divider::after {
            content: '';
            position: absolute;
            top: 50%;
            width: 38%;
            height: 1px;
            background: rgba(212,175,55,0.15);
        }
        .divider::before { left: 0; }
        .divider::after { right: 0; }

        .btn-row { display: flex; gap: 10px; margin-top: 22px; }
        .btn-primary {
            flex: 1;
            padding: 11px;
            background: linear-gradient(135deg, #d4af37, #b8962e);
            color: #0a0a0f;
            border: none;
            border-radius: 8px;
            font-weight: 700;
            font-size: 0.9rem;
            cursor: pointer;
            transition: opacity 0.3s;
        }
        .btn-primary:hover { opacity: 0.85; }
        .btn-secondary {
            padding: 11px 18px;
            background: transparent;
            border: 1px solid rgba(212,175,55,0.3);
            color: rgba(212,175,55,0.7);
            border-radius: 8px;
            font-size: 0.9rem;
            cursor: pointer;
            text-decoration: none;
            display: flex;
            align-items: center;
            transition: all 0.3s;
        }
        .btn-secondary:hover { border-color: #d4af37; color: #d4af37; }

        /* ── TABLA ── */
        .table-card {
            background: rgba(255,255,255,0.03);
            border: 1px solid rgba(212,175,55,0.2);
            border-radius: 16px;
            overflow: hidden;
        }
        .table-card-header {
            padding: 18px 24px;
            border-bottom: 1px solid rgba(212,175,55,0.15);
            display: flex;
            align-items: center;
            justify-content: space-between;
        }
        .table-card-header h3 {
            font-family: 'Cinzel', serif;
            color: #d4af37;
            font-size: 1rem;
        }
        .count-badge {
            background: rgba(212,175,55,0.15);
            color: #d4af37;
            padding: 3px 12px;
            border-radius: 12px;
            font-size: 0.8rem;
        }

        table { width: 100%; border-collapse: collapse; }
        th {
            background: rgba(212,175,55,0.1);
            color: #d4af37;
            padding: 13px 16px;
            text-align: left;
            font-size: 0.8rem;
            letter-spacing: 1px;
            text-transform: uppercase;
        }
        td {
            padding: 13px 16px;
            border-bottom: 1px solid rgba(255,255,255,0.05);
            font-size: 0.9rem;
            color: rgba(224,212,180,0.85);
        }
        tr:last-child td { border-bottom: none; }
        tr:hover td { background: rgba(212,175,55,0.04); }

        .doc-badge {
            display: inline-block;
            background: rgba(26,188,156,0.15);
            border: 1px solid rgba(26,188,156,0.3);
            color: #1abc9c;
            padding: 3px 10px;
            border-radius: 10px;
            font-size: 0.8rem;
        }

        .action-btns { display: flex; gap: 8px; }
        .btn-edit {
            background: transparent;
            border: 1px solid rgba(212,175,55,0.4);
            color: #d4af37;
            padding: 5px 12px;
            border-radius: 6px;
            cursor: pointer;
            font-size: 0.82rem;
            transition: all 0.3s;
        }
        .btn-edit:hover { background: rgba(212,175,55,0.15); }
        .btn-delete {
            background: transparent;
            border: 1px solid rgba(192,57,43,0.4);
            color: #e74c3c;
            padding: 5px 12px;
            border-radius: 6px;
            cursor: pointer;
            font-size: 0.82rem;
            transition: all 0.3s;
        }
        .btn-delete:hover { background: rgba(192,57,43,0.15); }

        .empty-state {
            text-align: center;
            padding: 50px 20px;
            color: rgba(224,212,180,0.35);
        }
        .empty-state .empty-icon { font-size: 2.5rem; margin-bottom: 12px; }

        /* ── ALERTAS ── */
        .alert {
            padding: 12px 18px;
            border-radius: 10px;
            margin-bottom: 22px;
            font-size: 0.9rem;
        }
        .alert-success {
            background: rgba(46,204,113,0.1);
            border: 1px solid rgba(46,204,113,0.3);
            color: #2ecc71;
        }
        .alert-error {
            background: rgba(192,57,43,0.1);
            border: 1px solid rgba(192,57,43,0.3);
            color: #e74c3c;
        }
    

        body.embed-admin {
            background: #0f0e0b !important;
            min-height: auto;
            display: block;
            overflow-x: hidden;
        }
        body.embed-admin .sidebar { display: none !important; }
        body.embed-admin .main-content {
            margin-left: 0 !important;
            max-width: none !important;
            width: 100% !important;
            padding: 28px 32px !important;
        }
        body.embed-admin .back-link,
        body.embed-admin .back-btn { display: none !important; }
        body.embed-admin .layout,
        body.embed-admin .content-grid { grid-template-columns: minmax(280px, 380px) minmax(420px, 1fr); }
        @media (max-width: 900px) {
            body.embed-admin .layout,
            body.embed-admin .content-grid { grid-template-columns: 1fr; }
        }

    </style>
    <link rel="stylesheet" href="../Estilos/global.css">
</head>
<body class='<%= embedAdmin ? "embed-admin" : "" %>'>

<%
    String usuario = (String) session.getAttribute("usuario");
    String rol     = (String) session.getAttribute("rol");
    if (usuario == null) { response.sendRedirect("Login.jsp"); return; }
    if (!"administrador".equals(rol)) { response.sendRedirect("MenuCliente.jsp"); return; }
%>

<!-- ══════════════════ SIDEBAR ══════════════════ -->
<aside class="sidebar">
    <div class="sidebar-brand">
        <h2>NEINS</h2>
        <p>Panel de Administración</p>
    </div>

    <nav class="sidebar-nav">
        <div class="nav-section-title">Principal</div>
        <a href="MenuAdmin.jsp" class="nav-item">
            <span class="icon">🏠</span> Dashboard
        </a>

        <div class="nav-section-title">Gestión</div>
        <a href="Productos.jsp" class="nav-item">
            <span class="icon">📦</span> Productos
        </a>
        <a href="Clientes.jsp" class="nav-item">
            <span class="icon">👥</span> Clientes
        </a>
        <a href="Fiado.jsp" class="nav-item">
            <span class="icon">📋</span> Fiado
        </a>
        <a href="Proveedores.jsp" class="nav-item">
            <span class="icon">🏭</span> Proveedores
        </a>

        <div class="nav-section-title">Configuración</div>
        <a href="MedioPago.jsp" class="nav-item">
            <span class="icon">💳</span> Medios de Pago
        </a>
        <a href="Roles.jsp" class="nav-item">
            <span class="icon">🔑</span> Roles
        </a>
        <a href="TipoDocumento.jsp" class="nav-item active">
            <span class="icon">🪪</span> Tipo Documento
        </a>

        <div class="nav-section-title">Usuarios</div>
        <a href="RegistroUsuario.jsp" class="nav-item">
            <span class="icon">👤</span> Usuarios
        </a>
    </nav>

    <div class="sidebar-footer">
        <span style="display:block; font-size:0.78rem; color:rgba(212,175,55,0.5); margin-bottom:10px;">
            👋 <%= usuario %>
        </span>
        <a href="../Login.jsp" class="btn-logout">Cerrar Sesión</a>
    </div>
</aside>

<!-- ══════════════════ CONTENIDO PRINCIPAL ══════════════════ -->
<main class="main-content">

<%
    TipoDocumentoDAO dao = new TipoDocumentoDAO();
    String mensaje  = "";
    String tipoMsg  = "";
    int    editId   = 0;
    String editDesc = "";

    String accion = request.getParameter("accion");

    if ("insertar".equals(accion)) {
        Tipo_documento t = new Tipo_documento();
        t.setTipo_documento(request.getParameter("descripcion"));
        if (dao.insertar(t)) {
            mensaje = "✅ Tipo de documento registrado correctamente";
            tipoMsg = "success";
        } else {
            mensaje = "❌ Error al registrar el tipo de documento";
            tipoMsg = "error";
        }

    } else if ("actualizar".equals(accion)) {
        Tipo_documento t = new Tipo_documento();
        t.setId_tipo_documento(Integer.parseInt(request.getParameter("id")));
        t.setTipo_documento(request.getParameter("descripcion"));
        if (dao.actualizar(t)) {
            mensaje = "✅ Tipo de documento actualizado correctamente";
            tipoMsg = "success";
        } else {
            mensaje = "❌ Error al actualizar el tipo de documento";
            tipoMsg = "error";
        }

    } else if ("eliminar".equals(accion)) {
        int id = Integer.parseInt(request.getParameter("id"));
        if (dao.eliminar(id)) {
            mensaje = "✅ Tipo de documento eliminado";
            tipoMsg = "success";
        } else {
            mensaje = "❌ Error al eliminar el tipo de documento";
            tipoMsg = "error";
        }

    } else if ("editar".equals(accion)) {
        editId   = Integer.parseInt(request.getParameter("id"));
        editDesc = request.getParameter("descripcion");
    }

    List<Tipo_documento> lista = dao.listar();
%>

    <div class="page-header">
        <h1>🪪 Tipos de Documento</h1>
        <p>Administra los tipos de documento de identidad del sistema</p>
    </div>

    <% if (!mensaje.isEmpty()) { %>
        <div class="alert alert-<%= tipoMsg %>"><%= mensaje %></div>
    <% } %>

    <div class="layout">

        <!-- ── FORMULARIO ── -->
        <div class="form-card">
            <h2><%= editId > 0 ? "✏️ Editar Tipo de Documento" : "➕ Nuevo Tipo de Documento" %></h2>

            <% if (editId > 0) { %>
                <div class="edit-badge">✏️ Modo edición — Tipo Doc #<%= editId %></div>
            <% } %>

            <form action="TipoDocumento.jsp" method="post">
                <input type="hidden" name="accion" value="<%= editId > 0 ? "actualizar" : "insertar" %>">
                <% if (editId > 0) { %>
                    <input type="hidden" name="id" value="<%= editId %>">
                <% } %>

                <div class="form-group">
                    <label for="descripcion">Nombre del Tipo de Documento</label>
                    <input type="text" id="descripcion" name="descripcion"
                           value="<%= editDesc %>"
                           placeholder="Ej: Cédula de ciudadanía"
                           required>
                </div>

                <% if (editId == 0) { %>
                <div class="divider">o elige uno común</div>
                <div class="chip-options">
                    <span class="chip" onclick="document.getElementById('descripcion').value=this.textContent">Cédula de ciudadanía</span>
                    <span class="chip" onclick="document.getElementById('descripcion').value=this.textContent">Cédula de extranjería</span>
                    <span class="chip" onclick="document.getElementById('descripcion').value=this.textContent">Pasaporte</span>
                    <span class="chip" onclick="document.getElementById('descripcion').value=this.textContent">Tarjeta de identidad</span>
                    <span class="chip" onclick="document.getElementById('descripcion').value=this.textContent">NIT</span>
                </div>
                <% } %>

                <div class="btn-row">
                    <button type="submit" class="btn-primary">
                        <%= editId > 0 ? "💾 Guardar Cambios" : "➕ Registrar" %>
                    </button>
                    <% if (editId > 0) { %>
                        <a href="TipoDocumento.jsp" class="btn-secondary">✕ Cancelar</a>
                    <% } else { %>
                        <button type="reset" class="btn-secondary">🔄 Limpiar</button>
                    <% } %>
                </div>
            </form>
        </div>

        <!-- ── TABLA ── -->
        <div class="table-card">
            <div class="table-card-header">
                <h3>Tipos de Documento Registrados</h3>
                <span class="count-badge"><%= lista.size() %> registros</span>
            </div>

            <% if (lista.isEmpty()) { %>
                <div class="empty-state">
                    <div class="empty-icon">🪪</div>
                    <p>No hay tipos de documento registrados aún</p>
                </div>
            <% } else { %>
                <table>
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>Tipo de Documento</th>
                            <th>Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% for (Tipo_documento t : lista) { %>
                        <tr>
                            <td><%= t.getId_tipo_documento() %></td>
                            <td><span class="doc-badge">🪪 <%= t.getTipo_documento() %></span></td>
                            <td>
                                <div class="action-btns">
                                    <!-- Botón Editar -->
                                    <form action="TipoDocumento.jsp" method="post" style="display:inline;">
                                        <input type="hidden" name="accion"      value="editar">
                                        <input type="hidden" name="id"          value="<%= t.getId_tipo_documento() %>">
                                        <input type="hidden" name="descripcion" value="<%= t.getTipo_documento() %>">
                                        <button type="submit" class="btn-edit">✏️ Editar</button>
                                    </form>

                                    <!-- Botón Eliminar con confirmación -->
                                    <form action="TipoDocumento.jsp" method="post" style="display:inline;"
                                          onsubmit="return confirm('¿Eliminar el tipo de documento \'<%= t.getTipo_documento() %>\'?\nEsta acción no se puede deshacer.');">
                                        <input type="hidden" name="accion" value="eliminar">
                                        <input type="hidden" name="id"    value="<%= t.getId_tipo_documento() %>">
                                        <button type="submit" class="btn-delete">🗑️ Eliminar</button>
                                    </form>
                                </div>
                            </td>
                        </tr>
                        <% } %>
                    </tbody>
                </table>
            <% } %>
        </div>

    </div><!-- /layout -->

</main>

<script>
(function () {
    const params = new URLSearchParams(window.location.search);
    if (params.get('embed') !== '1') return;

    document.querySelectorAll('form').forEach(form => {
        if (!form.querySelector('input[name="embed"]')) {
            const input = document.createElement('input');
            input.type = 'hidden';
            input.name = 'embed';
            input.value = '1';
            form.appendChild(input);
        }
    });

    document.querySelectorAll('a[href]').forEach(link => {
        const href = link.getAttribute('href');
        if (!href || href.startsWith('#') || href.startsWith('http') || href.includes('LogoutServlet') || href.includes('Login.jsp')) return;
        if (!href.includes('.jsp')) return;
        const url = new URL(href, window.location.href);
        url.searchParams.set('embed', '1');
        link.setAttribute('href', url.pathname.split('/').pop() + url.search + url.hash);
    });
})();
</script>
    <script src="../Scripts/premium-ui.js"></script>
</body>
</html>


