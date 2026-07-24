<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@page import="Controlador.ProductosDAO, Modelo.Productos, java.util.List"%>

<% boolean embedAdmin = "1".equals(request.getParameter("embed")); %>
<%
    // ── Protección de sesión ───────────────────────────────────────────────
    String usuario = (String) session.getAttribute("usuario");
    String rolSesion = (String) session.getAttribute("rol");
    if (usuario == null) { response.sendRedirect("Login.jsp"); return; }
    if (!"administrador".equals(rolSesion)) { response.sendRedirect("MenuCliente.jsp"); return; }

    // ── Lógica CRUD ───────────────────────────────────────────────────────
    ProductosDAO dao = new ProductosDAO();
    String mensaje = "";
    String tipoMsg = "";

    String accion = request.getParameter("accion");

    if ("insertar".equals(accion)) {
        try {
            Productos p = new Productos();
            p.setNombre(request.getParameter("nombre").trim());
            p.setPrecio(Float.parseFloat(request.getParameter("precio")));
            p.setStock(Integer.parseInt(request.getParameter("stock")));
            if (dao.insertar(p)) { mensaje = "✅ Producto registrado correctamente"; tipoMsg = "exito"; }
            else                 { mensaje = "❌ Error al registrar producto";         tipoMsg = "error"; }
        } catch (Exception ex) {
            mensaje = "❌ Datos inválidos: " + ex.getMessage(); tipoMsg = "error";
        }
    }

    if ("actualizar".equals(accion)) {
        try {
            Productos p = new Productos();
            p.setId_productos(Integer.parseInt(request.getParameter("id")));
            p.setNombre(request.getParameter("nombre").trim());
            p.setPrecio(Float.parseFloat(request.getParameter("precio")));
            p.setStock(Integer.parseInt(request.getParameter("stock")));
            if (dao.actualizar(p)) { mensaje = "✅ Producto actualizado correctamente"; tipoMsg = "exito"; }
            else                   { mensaje = "❌ Error al actualizar producto";         tipoMsg = "error"; }
        } catch (Exception ex) {
            mensaje = "❌ Datos inválidos: " + ex.getMessage(); tipoMsg = "error";
        }
    }

    if ("eliminar".equals(accion)) {
        try {
            int id = Integer.parseInt(request.getParameter("id"));
            if (dao.eliminar(id)) { mensaje = "✅ Producto eliminado"; tipoMsg = "exito"; }
            else                  { mensaje = "❌ Error al eliminar";   tipoMsg = "error"; }
        } catch (Exception ex) {
            mensaje = "❌ Error: " + ex.getMessage(); tipoMsg = "error";
        }
    }

    // Producto a editar (para prellenar el formulario)
    Productos productoEditar = null;
    if ("editar".equals(accion)) {
        try {
            int idEditar = Integer.parseInt(request.getParameter("id"));
            List<Productos> todos = dao.listar();
            for (Productos p : todos) {
                if (p.getId_productos() == idEditar) { productoEditar = p; break; }
            }
        } catch (Exception ex) { /* ignorar */ }
    }

    List<Productos> lista = dao.listar();
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Productos — Una Pa' La Sed</title>
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@600;700&family=DM+Sans:wght@300;400;500;600&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg:       #0f0e0b;
            --bg2:      #1a1814;
            --bg3:      #222018;
            --gold:     #c9a84c;
            --gold-lt:  #e8c97a;
            --gold-dk:  #9a7a30;
            --red:      #e05252;
            --green:    #4caf7d;
            --text:     #f0ead8;
            --muted:    #9a9282;
            --border:   rgba(201,168,76,.18);
        }
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: 'DM Sans', sans-serif;
            background: var(--bg);
            color: var(--text);
            min-height: 100vh;
            padding: 40px 20px;
        }
        .page-wrap { max-width: 900px; margin: 0 auto; }

        /* ── Encabezado ── */
        .page-header {
            display: flex; align-items: center; justify-content: space-between;
            margin-bottom: 32px;
        }
        .page-header h1 {
            font-family: 'Playfair Display', serif;
            font-size: 1.8rem; color: var(--gold);
        }
        .back-link {
            color: var(--muted); text-decoration: none; font-size: 0.9rem;
            display: flex; align-items: center; gap: 6px;
            transition: color .2s;
        }
        .back-link:hover { color: var(--gold); }

        /* ── Mensaje ── */
        .msg {
            padding: 12px 18px; border-radius: 8px; margin-bottom: 24px;
            font-size: 0.95rem; font-weight: 500;
        }
        .msg.exito { background: rgba(76,175,125,.12); border: 1px solid rgba(76,175,125,.35); color: #4caf7d; }
        .msg.error { background: rgba(224,82,82,.12);  border: 1px solid rgba(224,82,82,.35);  color: #e05252; }

        /* ── Formulario ── */
        .card {
            background: var(--bg2);
            border: 1px solid var(--border);
            border-radius: 14px;
            padding: 28px 32px;
            margin-bottom: 36px;
        }
        .card h2 {
            font-family: 'Playfair Display', serif;
            font-size: 1.1rem; color: var(--gold-lt);
            margin-bottom: 22px;
        }
        .form-grid {
            display: grid;
            grid-template-columns: 1fr 1fr 1fr;
            gap: 16px;
        }
        .form-group { display: flex; flex-direction: column; gap: 7px; }
        .form-group label {
            font-size: 0.78rem; color: var(--muted);
            text-transform: uppercase; letter-spacing: .8px; font-weight: 600;
        }
        .form-group input {
            padding: 11px 14px;
            background: var(--bg3);
            border: 1px solid rgba(201,168,76,.2);
            border-radius: 8px;
            color: var(--text);
            font-size: 0.95rem;
            font-family: 'DM Sans', sans-serif;
            transition: border-color .2s, box-shadow .2s;
        }
        .form-group input:focus {
            outline: none;
            border-color: var(--gold);
            box-shadow: 0 0 0 3px rgba(201,168,76,.12);
        }
        .btn-row { display: flex; gap: 12px; margin-top: 20px; }
        .btn-primary {
            padding: 11px 26px;
            background: linear-gradient(135deg, var(--gold), var(--gold-dk));
            color: #0f0e0b; font-weight: 700; font-size: 0.9rem;
            border: none; border-radius: 8px; cursor: pointer;
            font-family: 'DM Sans', sans-serif;
            transition: transform .2s, box-shadow .2s;
        }
        .btn-primary:hover { transform: translateY(-2px); box-shadow: 0 8px 20px rgba(201,168,76,.3); }
        .btn-secondary {
            padding: 11px 22px;
            background: transparent;
            border: 1px solid var(--border);
            color: var(--muted); font-size: 0.9rem;
            border-radius: 8px; cursor: pointer;
            font-family: 'DM Sans', sans-serif;
            transition: color .2s, border-color .2s;
            text-decoration: none; display: inline-flex; align-items: center;
        }
        .btn-secondary:hover { color: var(--text); border-color: var(--muted); }

        /* ── Tabla ── */
        .table-wrap { overflow-x: auto; }
        table { width: 100%; border-collapse: collapse; }
        thead tr { background: rgba(201,168,76,.1); }
        th {
            padding: 13px 14px; text-align: left;
            color: var(--gold); font-size: 0.8rem;
            text-transform: uppercase; letter-spacing: .8px;
            border-bottom: 1px solid var(--border);
        }
        td {
            padding: 13px 14px;
            border-bottom: 1px solid rgba(255,255,255,.05);
            font-size: 0.95rem;
            color: var(--text);
        }
        tr:hover td { background: rgba(201,168,76,.04); }
        .badge-stock {
            display: inline-block;
            padding: 3px 10px; border-radius: 20px;
            font-size: 0.82rem; font-weight: 600;
        }
        .stock-ok   { background: rgba(76,175,125,.15); color: #4caf7d; }
        .stock-low  { background: rgba(224,200,82,.15); color: #e0c852; }
        .stock-zero { background: rgba(224,82,82,.15);  color: #e05252; }

        /* ── Acciones ── */
        .actions { display: flex; gap: 8px; }
        .btn-edit {
            padding: 6px 14px; border-radius: 6px; font-size: 0.82rem;
            background: transparent; border: 1px solid var(--gold);
            color: var(--gold); cursor: pointer; font-family: 'DM Sans', sans-serif;
            text-decoration: none; display: inline-block;
            transition: background .2s, color .2s;
        }
        .btn-edit:hover { background: var(--gold); color: #0f0e0b; }
        .btn-delete {
            padding: 6px 14px; border-radius: 6px; font-size: 0.82rem;
            background: transparent; border: 1px solid var(--red);
            color: var(--red); cursor: pointer; font-family: 'DM Sans', sans-serif;
            transition: background .2s, color .2s;
        }
        .btn-delete:hover { background: var(--red); color: white; }

        /* ── Precio ── */
        .precio { color: var(--gold-lt); font-weight: 600; }

        @media (max-width: 600px) {
            .form-grid { grid-template-columns: 1fr; }
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

    

        body.embed-admin > div {
            align-items: stretch !important;
            padding: 28px 32px !important;
        }
        body.embed-admin .form-container {
            max-width: 520px;
            padding: 28px;
            text-align: left;
        }
        body.embed-admin .tabla-container {
            max-width: none;
            margin-top: 28px;
        }

    </style>
    <link rel="stylesheet" href="../Estilos/global.css">
</head>
<body class='<%= embedAdmin ? "embed-admin" : "" %>'>
<div class="page-wrap">

    <!-- Encabezado -->
    <div class="page-header">
        <h1>🍶 Productos</h1>
        <a href="MenuAdmin.jsp" class="back-link">← Volver al Panel</a>
    </div>

    <!-- Mensaje de resultado -->
    <% if (!mensaje.isEmpty()) { %>
        <div class="msg <%= tipoMsg %>"><%= mensaje %></div>
    <% } %>

    <!-- ══════════════════════════════════
         FORMULARIO: Agregar / Editar
    ══════════════════════════════════ -->
    <div class="card">
        <h2><%= (productoEditar != null) ? "✏️ Editar Producto" : "➕ Nuevo Producto" %></h2>

        <form action="Productos.jsp" method="post">
            <input type="hidden" name="accion" value="<%= (productoEditar != null) ? "actualizar" : "insertar" %>">
            <% if (productoEditar != null) { %>
                <input type="hidden" name="id" value="<%= productoEditar.getId_productos() %>">
            <% } %>

            <div class="form-grid">
                <div class="form-group">
                    <label>Nombre del producto</label>
                    <input type="text" name="nombre" required placeholder="Ej: Ron Medellín"
                           value="<%= (productoEditar != null) ? productoEditar.getNombre() : "" %>">
                </div>
                <div class="form-group">
                    <label>Precio ($)</label>
                    <input type="number" name="precio" required step="0.01" min="0" placeholder="0.00"
                           value="<%= (productoEditar != null) ? productoEditar.getPrecio() : "" %>">
                </div>
                <div class="form-group">
                    <label>Stock (unidades)</label>
                    <input type="number" name="stock" required min="0" placeholder="0"
                           value="<%= (productoEditar != null) ? productoEditar.getStock() : "" %>">
                </div>
            </div>

            <div class="btn-row">
                <button type="submit" class="btn-primary">
                    <%= (productoEditar != null) ? "Guardar cambios" : "Registrar producto" %>
                </button>
                <% if (productoEditar != null) { %>
                    <a href="Productos.jsp" class="btn-secondary">Cancelar</a>
                <% } else { %>
                    <button type="reset" class="btn-secondary">Limpiar</button>
                <% } %>
            </div>
        </form>
    </div>

    <!-- ══════════════════════════════════
         TABLA DE PRODUCTOS
    ══════════════════════════════════ -->
    <div class="card">
        <h2>📋 Lista de productos (<%= lista.size() %> en total)</h2>
        <div class="table-wrap">
            <table>
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Nombre</th>
                        <th>Precio</th>
                        <th>Stock</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    <% if (lista.isEmpty()) { %>
                        <tr>
                            <td colspan="5" style="text-align:center; color:var(--muted); padding:30px;">
                                No hay productos registrados aún.
                            </td>
                        </tr>
                    <% } %>
                    <% for (Productos p : lista) { %>
                    <tr>
                        <td style="color:var(--muted);">#<%= p.getId_productos() %></td>
                        <td><strong><%= p.getNombre() %></strong></td>
                        <td class="precio">$<%= String.format("%,.0f", (double)p.getPrecio()) %></td>
                        <td>
                            <%
                                String stockClass = "stock-ok";
                                if (p.getStock() == 0) stockClass = "stock-zero";
                                else if (p.getStock() < 5) stockClass = "stock-low";
                            %>
                            <span class="badge-stock <%= stockClass %>"><%= p.getStock() %> uds</span>
                        </td>
                        <td>
                            <div class="actions">
                                <!-- Botón Editar -->
                                <a href="Productos.jsp?accion=editar&id=<%= p.getId_productos() %>" class="btn-edit">Editar</a>
                                <!-- Botón Eliminar -->
                                <form action="Productos.jsp" method="post" style="display:inline;"
                                      onsubmit="return confirm('¿Eliminar el producto «<%= p.getNombre() %>»? Esta acción no se puede deshacer.')">
                                    <input type="hidden" name="accion" value="eliminar">
                                    <input type="hidden" name="id" value="<%= p.getId_productos() %>">
                                    <button type="submit" class="btn-delete">Eliminar</button>
                                </form>
                            </div>
                        </td>
                    </tr>
                    <% } %>
                </tbody>
            </table>
        </div>
    </div>

</div>
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


