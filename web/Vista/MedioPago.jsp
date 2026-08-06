<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@page import="Controlador.MedioPagoDAO, Modelo.Medio_pago, java.util.List"%>

<% boolean embedAdmin = "1".equals(request.getParameter("embed")); %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Medios de Pago — NEINS</title>
    <link rel="stylesheet" type="text/css" href="../Estilos/global.css">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Cinzel:wght@500;700&family=Inter:wght@300;400;500;600&display=swap" rel="stylesheet">
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }

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
            background: linear-gradient(180deg, #0d0d1a 0%, #0a0a14 100%);
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
            letter-spacing: 3px;
        }

        .sidebar-brand p {
            color: rgba(212,175,55,0.5);
            font-size: 0.72rem;
            margin-top: 4px;
            letter-spacing: 1px;
        }

        .sidebar-nav { flex: 1; padding: 16px 0; overflow-y: auto; }

        .nav-section {
            padding: 8px 16px 4px;
            font-size: 0.65rem;
            text-transform: uppercase;
            letter-spacing: 2px;
            color: rgba(212,175,55,0.4);
            margin-top: 8px;
        }

        .nav-item {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 11px 24px;
            color: rgba(224,212,180,0.7);
            text-decoration: none;
            font-size: 0.88rem;
            transition: all 0.2s;
            border-left: 3px solid transparent;
        }

        .nav-item:hover {
            color: #d4af37;
            background: rgba(212,175,55,0.06);
            border-left-color: rgba(212,175,55,0.4);
        }

        .nav-item.active {
            color: #d4af37;
            background: rgba(212,175,55,0.1);
            border-left-color: #d4af37;
            font-weight: 600;
        }

        .nav-icon { font-size: 1.05rem; width: 20px; text-align: center; }

        .sidebar-footer {
            padding: 16px 24px;
            border-top: 1px solid rgba(212,175,55,0.1);
        }

        .btn-logout {
            display: flex;
            align-items: center;
            gap: 10px;
            width: 100%;
            padding: 10px 16px;
            background: rgba(192,57,43,0.12);
            border: 1px solid rgba(192,57,43,0.3);
            border-radius: 8px;
            color: #e74c3c;
            font-size: 0.85rem;
            cursor: pointer;
            text-decoration: none;
            transition: all 0.2s;
        }

        .btn-logout:hover { background: rgba(192,57,43,0.25); }

        /* ── MAIN ── */
        .main-content {
            margin-left: 260px;
            flex: 1;
            padding: 40px;
            min-height: 100vh;
        }

        .page-header {
            margin-bottom: 32px;
            padding-bottom: 20px;
            border-bottom: 1px solid rgba(212,175,55,0.15);
        }

        .page-header h1 {
            font-family: 'Cinzel', serif;
            color: #d4af37;
            font-size: 1.7rem;
            letter-spacing: 2px;
        }

        .page-header p {
            color: rgba(224,212,180,0.5);
            font-size: 0.85rem;
            margin-top: 6px;
        }

        /* ── LAYOUT ── */
        .content-grid {
            display: grid;
            grid-template-columns: 380px 1fr;
            gap: 32px;
            align-items: start;
        }

        /* ── CARD ── */
        .card {
            background: rgba(255,255,255,0.03);
            border: 1px solid rgba(212,175,55,0.15);
            border-radius: 14px;
            padding: 28px;
        }

        .card h2 {
            font-family: 'Cinzel', serif;
            color: #d4af37;
            font-size: 1.05rem;
            letter-spacing: 1px;
            margin-bottom: 22px;
        }

        /* ── BADGE MODO EDICIÓN ── */
        .edit-badge {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            background: rgba(212,175,55,0.12);
            border: 1px solid rgba(212,175,55,0.4);
            color: #d4af37;
            padding: 8px 14px;
            border-radius: 8px;
            font-size: 0.82rem;
            margin-bottom: 18px;
            width: 100%;
        }

        /* ── FORM ── */
        .form-group {
            margin-bottom: 18px;
        }

        .form-group label {
            display: block;
            font-size: 0.8rem;
            text-transform: uppercase;
            letter-spacing: 1px;
            color: rgba(212,175,55,0.7);
            margin-bottom: 8px;
        }

        .form-group input {
            width: 100%;
            padding: 11px 14px;
            background: rgba(255,255,255,0.05);
            border: 1px solid rgba(212,175,55,0.2);
            border-radius: 8px;
            color: #e0d4b4;
            font-size: 0.92rem;
            transition: border-color 0.2s;
        }

        .form-group input:focus {
            outline: none;
            border-color: #d4af37;
            background: rgba(212,175,55,0.05);
        }

        .form-buttons {
            display: flex;
            gap: 10px;
            margin-top: 6px;
        }

        .btn-primary {
            flex: 1;
            padding: 11px;
            background: linear-gradient(135deg, #d4af37, #b8962e);
            border: none;
            border-radius: 8px;
            color: #0a0a0f;
            font-weight: 700;
            font-size: 0.88rem;
            cursor: pointer;
            transition: opacity 0.2s;
            letter-spacing: 0.5px;
        }

        .btn-primary:hover { opacity: 0.85; }

        .btn-secondary {
            flex: 1;
            padding: 11px;
            background: transparent;
            border: 1px solid rgba(212,175,55,0.3);
            border-radius: 8px;
            color: #d4af37;
            font-size: 0.88rem;
            cursor: pointer;
            transition: all 0.2s;
            text-decoration: none;
            text-align: center;
        }

        .btn-secondary:hover { background: rgba(212,175,55,0.08); }

        /* ── ALERTS ── */
        .alert {
            padding: 12px 16px;
            border-radius: 8px;
            font-size: 0.88rem;
            margin-bottom: 18px;
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

        /* ── TABLE ── */
        .table-wrapper { overflow-x: auto; }

        table {
            width: 100%;
            border-collapse: collapse;
        }

        th {
            background: rgba(212,175,55,0.1);
            color: #d4af37;
            padding: 12px 16px;
            text-align: left;
            font-size: 0.75rem;
            text-transform: uppercase;
            letter-spacing: 1px;
            border-bottom: 1px solid rgba(212,175,55,0.2);
        }

        td {
            padding: 13px 16px;
            border-bottom: 1px solid rgba(255,255,255,0.05);
            font-size: 0.9rem;
            vertical-align: middle;
        }

        tr:last-child td { border-bottom: none; }
        tr:hover td { background: rgba(212,175,55,0.04); }

        .td-actions {
            display: flex;
            gap: 8px;
        }

        .btn-edit {
            background: rgba(212,175,55,0.1);
            border: 1px solid rgba(212,175,55,0.35);
            color: #d4af37;
            padding: 6px 14px;
            border-radius: 6px;
            cursor: pointer;
            font-size: 0.82rem;
            transition: all 0.2s;
            white-space: nowrap;
        }

        .btn-edit:hover { background: rgba(212,175,55,0.2); }

        .btn-delete {
            background: transparent;
            border: 1px solid rgba(192,57,43,0.5);
            color: #e74c3c;
            padding: 6px 14px;
            border-radius: 6px;
            cursor: pointer;
            font-size: 0.82rem;
            transition: all 0.2s;
            white-space: nowrap;
        }

        .btn-delete:hover { background: rgba(192,57,43,0.15); }

        .empty-state {
            text-align: center;
            color: rgba(224,212,180,0.35);
            padding: 40px 20px;
            font-size: 0.9rem;
        }

        /* ── BADGE TIPO ── */
        .badge-pago {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            background: rgba(52,152,219,0.12);
            border: 1px solid rgba(52,152,219,0.3);
            color: #3498db;
            padding: 4px 10px;
            border-radius: 20px;
            font-size: 0.78rem;
            font-weight: 500;
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

<%-- ─── SEGURIDAD: solo admin ─── --%>
<%
    String usuarioSesion = (String) session.getAttribute("usuario");
    String rolSesion     = (String) session.getAttribute("rol");
    if (usuarioSesion == null) { response.sendRedirect("Login.jsp"); return; }
    if (!"administrador".equals(rolSesion)) { response.sendRedirect("MenuCliente.jsp"); return; }
%>

<%-- ─── LÓGICA CRUD ─── --%>
<%
    MedioPagoDAO dao = new MedioPagoDAO();
    String mensaje   = "";
    String tipoMsg   = "";

    String accion = request.getParameter("accion");
    if (accion == null) accion = "";

    if ("insertar".equals(accion)) {
        Medio_pago m = new Medio_pago();
        m.setDescripcion_medio_pago(request.getParameter("descripcion").trim());
        if (dao.insertar(m)) { mensaje = "✅ Medio de pago registrado correctamente."; tipoMsg = "success"; }
        else                 { mensaje = "❌ Error al registrar el medio de pago.";     tipoMsg = "error";   }

    } else if ("actualizar".equals(accion)) {
        int id = Integer.parseInt(request.getParameter("id_editar"));
        Medio_pago m = new Medio_pago();
        m.setId_medio_pago(id);
        m.setDescripcion_medio_pago(request.getParameter("descripcion").trim());
        if (dao.actualizar(m)) { mensaje = "✅ Medio de pago actualizado correctamente."; tipoMsg = "success"; }
        else                   { mensaje = "❌ Error al actualizar el medio de pago.";     tipoMsg = "error";   }

    } else if ("eliminar".equals(accion)) {
        int id = Integer.parseInt(request.getParameter("id"));
        if (dao.eliminar(id)) { mensaje = "✅ Medio de pago eliminado."; tipoMsg = "success"; }
        else                  { mensaje = "❌ Error al eliminar.";        tipoMsg = "error";   }
    }

    List<Medio_pago> lista = dao.listar();

    // Modo edición
    String modoEdicion = request.getParameter("editar");
    int idEditando     = 0;
    String descEditar  = "";
    if (modoEdicion != null && !modoEdicion.isEmpty()) {
        idEditando = Integer.parseInt(modoEdicion);
        for (Medio_pago mp : lista) {
            if (mp.getId_medio_pago() == idEditando) {
                descEditar = mp.getDescripcion_medio_pago();
                break;
            }
        }
    }
%>

<!-- ══════════════════════════════════════
     SIDEBAR
════════════════════════════════════════ -->
<aside class="sidebar">
    <div class="sidebar-brand">
        <h2>NEINS</h2>
        <p>PANEL DE ADMINISTRACIÓN</p>
    </div>

    <nav class="sidebar-nav">
        <div class="nav-section">Principal</div>
        <a href="MenuAdmin.jsp" class="nav-item">
            <span class="nav-icon">📊</span> Dashboard
        </a>

        <div class="nav-section">Gestión</div>
        <a href="Productos.jsp"       class="nav-item"><span class="nav-icon">📦</span> Productos</a>
        <a href="Clientes.jsp"        class="nav-item"><span class="nav-icon">👥</span> Clientes</a>
        <a href="Fiado.jsp"           class="nav-item"><span class="nav-icon">💳</span> Fiados</a>
        <a href="MedioPago.jsp"       class="nav-item active"><span class="nav-icon">💰</span> Medio de Pago</a>
        <a href="Proveedores.jsp"     class="nav-item"><span class="nav-icon">🏭</span> Proveedores</a>

        <div class="nav-section">Configuración</div>
        <a href="RegistroUsuario.jsp" class="nav-item"><span class="nav-icon">👤</span> Usuarios</a>
        <a href="Roles.jsp"           class="nav-item"><span class="nav-icon">🔑</span> Roles</a>
        <a href="TipoDocumento.jsp"   class="nav-item"><span class="nav-icon">📄</span> Tipo Documento</a>
    </nav>

    <div class="sidebar-footer">
        <a href="../LoginServlet?accion=logout" class="btn-logout">
            <span>🚪</span> Cerrar sesión
        </a>
    </div>
</aside>

<!-- ══════════════════════════════════════
     CONTENIDO PRINCIPAL
════════════════════════════════════════ -->
<main class="main-content">

    <div class="page-header">
        <h1>💰 MEDIO DE PAGO</h1>
        <p>Gestiona los métodos de pago disponibles en el sistema</p>
    </div>

    <div class="content-grid">

        <!-- ── FORMULARIO ── -->
        <div class="card">

            <% if (idEditando > 0) { %>
                <div class="edit-badge">
                    ✏️ Modo edición — Medio de Pago #<%= idEditando %>
                </div>
                <h2>Editar Medio de Pago</h2>
            <% } else { %>
                <h2>Nuevo Medio de Pago</h2>
            <% } %>

            <% if (!mensaje.isEmpty()) { %>
                <div class="alert alert-<%= tipoMsg %>"><%= mensaje %></div>
            <% } %>

            <form action="MedioPago.jsp" method="post">
                <input type="hidden" name="accion"    value="<%= idEditando > 0 ? "actualizar" : "insertar" %>">
                <input type="hidden" name="id_editar" value="<%= idEditando %>">

                <div class="form-group">
                    <label for="descripcion">Descripción</label>
                    <input type="text"
                           id="descripcion"
                           name="descripcion"
                           placeholder="Ej: Efectivo, Nequi, Transferencia..."
                           value="<%= descEditar %>"
                           required>
                </div>

                <div class="form-buttons">
                    <button type="submit" class="btn-primary">
                        <%= idEditando > 0 ? "💾 Guardar cambios" : "➕ Agregar" %>
                    </button>
                    <% if (idEditando > 0) { %>
                        <a href="MedioPago.jsp" class="btn-secondary">✖ Cancelar</a>
                    <% } else { %>
                        <button type="reset" class="btn-secondary">Limpiar</button>
                    <% } %>
                </div>
            </form>
        </div>

        <!-- ── TABLA ── -->
        <div class="card">
            <h2>Medios registrados (<%= lista.size() %>)</h2>

            <div class="table-wrapper">
                <table>
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>Descripción</th>
                            <th>Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% if (lista.isEmpty()) { %>
                            <tr>
                                <td colspan="3" class="empty-state">
                                    No hay medios de pago registrados aún.
                                </td>
                            </tr>
                        <% } else {
                               for (Medio_pago mp : lista) { %>
                            <tr>
                                <td><%= mp.getId_medio_pago() %></td>
                                <td>
                                    <span class="badge-pago">💳 <%= mp.getDescripcion_medio_pago() %></span>
                                </td>
                                <td>
                                    <div class="td-actions">
                                        <!-- Botón Editar -->
                                        <a href="MedioPago.jsp?editar=<%= mp.getId_medio_pago() %>"
                                           class="btn-edit">✏️ Editar</a>

                                        <!-- Botón Eliminar -->
                                        <form action="MedioPago.jsp" method="post"
                                              onsubmit="return confirm('¿Eliminar el medio de pago \'<%= mp.getDescripcion_medio_pago() %>\'? Esta acción no se puede deshacer.');">
                                            <input type="hidden" name="accion" value="eliminar">
                                            <input type="hidden" name="id"     value="<%= mp.getId_medio_pago() %>">
                                            <button type="submit" class="btn-delete">🗑️ Eliminar</button>
                                        </form>
                                    </div>
                                </td>
                            </tr>
                        <% } } %>
                    </tbody>
                </table>
            </div>
        </div>

    </div><!-- /content-grid -->
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

