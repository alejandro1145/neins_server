<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@page import="Controlador.FiadoDAO, Modelo.Fiado, java.util.List"%>
<%@page import="Controlador.ClienteDAO,  Modelo.Clientes"%>
<%@page import="Controlador.MedioPagoDAO, Modelo.Medio_pago"%>

<% boolean embedAdmin = "1".equals(request.getParameter("embed")); %>
<%
    // ── Protección de sesión ──────────────────────────────────────
    String usuarioSes = (String) session.getAttribute("usuario");
    if (usuarioSes == null) { response.sendRedirect("Login.jsp"); return; }
    String rolSes = (String) session.getAttribute("rol");
    if (!"administrador".equals(rolSes)) { response.sendRedirect("MenuCliente.jsp"); return; }

    // ── DAOs ──────────────────────────────────────────────────────
    FiadoDAO     dao        = new FiadoDAO();
    ClienteDAO   clienteDAO = new ClienteDAO();
    MedioPagoDAO mpDAO      = new MedioPagoDAO();

    String mensaje = "";
    String tipoMsg = "";
    String accion  = request.getParameter("accion");

    // ── INSERTAR ──────────────────────────────────────────────────
    if ("insertar".equals(accion)) {
        try {
            Fiado f = new Fiado();
            f.setFecha_fiado(request.getParameter("Fiado"));
            f.setFecha_limite_pago(request.getParameter("Limite"));
            String fechaPago = request.getParameter("Pago");
            f.setFecha_pago((fechaPago != null && !fechaPago.trim().isEmpty()) ? fechaPago : null);
            f.setValor(Double.parseDouble(request.getParameter("Valor")));
            f.setId_cliente(Integer.parseInt(request.getParameter("id_cliente")));
            f.setId_medio_pago(Integer.parseInt(request.getParameter("id_medio_pago")));
            if (dao.insertar(f)) { mensaje = "✅ Fiado registrado correctamente"; tipoMsg = "exito"; }
            else                 { mensaje = "❌ Error al registrar el fiado";     tipoMsg = "error"; }
        } catch (Exception e) {
            mensaje = "❌ Datos inválidos: " + e.getMessage(); tipoMsg = "error";
        }
    }

    // ── ACTUALIZAR ────────────────────────────────────────────────
    if ("actualizar".equals(accion)) {
        try {
            Fiado f = new Fiado();
            f.setId_fiado(Integer.parseInt(request.getParameter("id_fiado")));
            f.setFecha_fiado(request.getParameter("Fiado"));
            f.setFecha_limite_pago(request.getParameter("Limite"));
            String fechaPago2 = request.getParameter("Pago");
            f.setFecha_pago((fechaPago2 != null && !fechaPago2.trim().isEmpty()) ? fechaPago2 : null);
            f.setValor(Double.parseDouble(request.getParameter("Valor")));
            f.setId_cliente(Integer.parseInt(request.getParameter("id_cliente")));
            f.setId_medio_pago(Integer.parseInt(request.getParameter("id_medio_pago")));
            if (dao.actualizar(f)) { mensaje = "✅ Fiado actualizado correctamente"; tipoMsg = "exito"; }
            else                   { mensaje = "❌ Error al actualizar el fiado";     tipoMsg = "error"; }
        } catch (Exception e) {
            mensaje = "❌ Datos inválidos: " + e.getMessage(); tipoMsg = "error";
        }
    }

    // ── ELIMINAR ──────────────────────────────────────────────────
    if ("eliminar".equals(accion)) {
        try {
            int id = Integer.parseInt(request.getParameter("id"));
            if (dao.eliminar(id)) { mensaje = "✅ Fiado eliminado correctamente"; tipoMsg = "exito"; }
            else                  { mensaje = "❌ Error al eliminar el fiado";     tipoMsg = "error"; }
        } catch (Exception e) {
            mensaje = "❌ Error: " + e.getMessage(); tipoMsg = "error";
        }
    }

    // El cupo se administra aquí: el usuario ya es cliente al registrarse.
    if ("actualizar_cupo".equals(accion)) {
        try {
            int idCliente = Integer.parseInt(request.getParameter("id_cliente_cupo"));
            double nuevoCupo = Double.parseDouble(request.getParameter("cupo_credito"));
            Clientes clienteCupo = null;
            for (Clientes c : clienteDAO.listar()) if (c.getId_clientes() == idCliente) { clienteCupo = c; break; }
            if (clienteCupo == null) {
                mensaje = "Cliente no encontrado."; tipoMsg = "error";
            } else if (nuevoCupo < Double.parseDouble(clienteCupo.getSaldoPendienteTotal())) {
                mensaje = "El cupo no puede ser menor que la deuda actual ($" + clienteCupo.getSaldoPendienteTotal() + ")."; tipoMsg = "error";
            } else {
                clienteCupo.setCupo_credito(String.valueOf(nuevoCupo));
                if (clienteDAO.actualizar(clienteCupo)) { mensaje = "Cupo de crédito actualizado."; tipoMsg = "exito"; }
                else { mensaje = "No se pudo actualizar el cupo."; tipoMsg = "error"; }
            }
        } catch (Exception e) { mensaje = "Revisa el cliente y el cupo ingresado."; tipoMsg = "error"; }
    }

    // ── Cargar datos para edición ─────────────────────────────────
    Fiado fEditar   = null;
    String editId   = request.getParameter("editar");
    if (editId != null && !editId.isEmpty()) {
        int idEdit = Integer.parseInt(editId);
        List<Fiado> todos = dao.listar();
        for (Fiado fi : todos) {
            if (fi.getId_fiado() == idEdit) { fEditar = fi; break; }
        }
    }

    // ── Listas para selects ───────────────────────────────────────
    List<Fiado>      lista    = dao.listar();
    List<Clientes>   clientes = clienteDAO.listar();
    List<Medio_pago> medios   = mpDAO.listar();

    // ── Formato moneda COP ────────────────────────────────────────
    java.text.NumberFormat nf = java.text.NumberFormat.getIntegerInstance(new java.util.Locale("es","CO"));
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Fiados — Neins</title>
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
            --blue:     #64a0ff;
            --text:     #f0ead8;
            --muted:    #9a9282;
            --border:   rgba(201,168,76,.18);
            --sw:       220px;
        }
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: 'DM Sans', sans-serif; background: var(--bg); color: var(--text); display: flex; min-height: 100vh; }

        /* ── SIDEBAR ── */
        .sidebar {
            width: var(--sw); background: var(--bg2); border-right: 1px solid var(--border);
            display: flex; flex-direction: column; position: fixed; top: 0; left: 0; bottom: 0; z-index: 100;
        }
        .brand { padding: 28px 20px 20px; border-bottom: 1px solid var(--border); display: flex; align-items: center; gap: 12px; }
        .brand-icon { width: 38px; height: 38px; background: var(--gold); border-radius: 10px; display: flex; align-items: center; justify-content: center; font-size: 20px; }
        .brand-name { font-family: 'Playfair Display', serif; font-size: 13px; color: var(--gold); letter-spacing: .5px; }
        .brand-sub  { font-size: 10px; color: var(--muted); letter-spacing: 1px; text-transform: uppercase; }
        .nav { flex: 1; padding: 16px 0; overflow-y: auto; }
        .nav-item {
            display: flex; align-items: center; gap: 10px; padding: 11px 20px;
            color: var(--muted); text-decoration: none; font-size: 14px; font-weight: 500;
            border-left: 3px solid transparent; transition: all .2s;
        }
        .nav-item:hover { color: var(--text); background: rgba(201,168,76,.06); }
        .nav-item.active { color: var(--gold); border-left-color: var(--gold); background: rgba(201,168,76,.08); }
        .nav-item svg { width: 18px; height: 18px; flex-shrink: 0; }
        .logout-wrap { padding: 16px 20px; border-top: 1px solid var(--border); }
        .logout-btn { display: flex; align-items: center; gap: 8px; color: var(--red); font-size: 13px; font-weight: 500; text-decoration: none; background: none; border: none; cursor: pointer; }

        /* ── MAIN ── */
        .main { margin-left: var(--sw); flex: 1; display: flex; flex-direction: column; }
        .topbar {
            padding: 20px 32px; border-bottom: 1px solid var(--border);
            display: flex; align-items: center; justify-content: space-between;
            background: var(--bg); position: sticky; top: 0; z-index: 50;
        }
        .topbar h1 { font-family: 'Playfair Display', serif; font-size: 22px; }
        .topbar p  { font-size: 13px; color: var(--muted); margin-top: 2px; }
        .back-btn {
            display: flex; align-items: center; gap: 8px;
            background: var(--bg2); border: 1px solid var(--border); color: var(--text);
            padding: 8px 16px; border-radius: 8px; font-size: 13px; text-decoration: none; transition: border-color .2s;
        }
        .back-btn:hover { border-color: var(--gold); color: var(--gold); }

        /* ── CONTENT ── */
        .content { padding: 28px 32px; flex: 1; }
        .two-col { display: grid; grid-template-columns: 380px 1fr; gap: 24px; align-items: start; }

        /* ── PANEL ── */
        .panel { background: var(--bg2); border: 1px solid var(--border); border-radius: 14px; padding: 24px; }
        .panel-title { font-family: 'Playfair Display', serif; font-size: 16px; color: var(--text); margin-bottom: 20px; }

        /* ── TOAST ── */
        .toast {
            padding: 12px 16px; border-radius: 10px; font-size: 14px;
            margin-bottom: 20px; font-weight: 500;
        }
        .toast.exito { background: rgba(76,175,125,.12); border: 1px solid rgba(76,175,125,.3); color: var(--green); }
        .toast.error { background: rgba(224,82,82,.12);  border: 1px solid rgba(224,82,82,.3);  color: var(--red);   }

        /* ── EDIT BADGE ── */
        .edit-badge {
            display: inline-flex; align-items: center; gap: 8px;
            background: rgba(201,168,76,.12); border: 1px solid rgba(201,168,76,.3);
            color: var(--gold); font-size: 12px; font-weight: 600;
            padding: 6px 12px; border-radius: 20px; margin-bottom: 16px;
        }

        /* ── FORM ── */
        .form-group { display: flex; flex-direction: column; gap: 6px; margin-bottom: 14px; }
        .form-group label { font-size: 12px; color: var(--muted); letter-spacing: .8px; text-transform: uppercase; }
        .form-group input,
        .form-group select {
            background: var(--bg3); border: 1px solid var(--border); color: var(--text);
            padding: 11px 14px; border-radius: 8px; font-size: 14px; font-family: 'DM Sans', sans-serif;
            transition: border-color .2s; width: 100%;
        }
        .form-group input:focus,
        .form-group select:focus  { outline: none; border-color: var(--gold); }
        .form-group select option { background: var(--bg3); }

        .btn-row { display: flex; gap: 10px; margin-top: 6px; }
        .btn-primary {
            flex: 1; padding: 12px; background: var(--gold); color: #1a1300;
            border: none; border-radius: 8px; font-size: 14px; font-weight: 700;
            cursor: pointer; transition: background .2s;
        }
        .btn-primary:hover { background: var(--gold-lt); }
        .btn-secondary {
            padding: 12px 18px; background: transparent; border: 1px solid var(--border);
            color: var(--muted); border-radius: 8px; font-size: 14px; cursor: pointer;
            text-decoration: none; display: flex; align-items: center; transition: all .2s;
        }
        .btn-secondary:hover { border-color: var(--muted); color: var(--text); }

        /* ── TABLA ── */
        .table-wrap { overflow-x: auto; }
        table { width: 100%; border-collapse: collapse; font-size: 13px; }
        th { padding: 10px 12px; text-align: left; color: var(--muted); font-weight: 500; border-bottom: 1px solid var(--border); white-space: nowrap; }
        td { padding: 11px 12px; border-bottom: 1px solid rgba(201,168,76,.07); vertical-align: middle; }
        tr:hover td { background: rgba(201,168,76,.04); }

        .badge {
            display: inline-block; padding: 3px 10px; border-radius: 20px;
            font-size: 11px; font-weight: 600; white-space: nowrap;
        }
        .badge-green  { background: rgba(76,175,125,.15);  color: var(--green); }
        .badge-red    { background: rgba(224,82,82,.15);   color: var(--red);   }
        .badge-gold   { background: rgba(201,168,76,.15);  color: var(--gold);  }

        .action-btns { display: flex; gap: 6px; }
        .btn-edit, .btn-del {
            padding: 5px 12px; border-radius: 6px; font-size: 12px;
            font-weight: 600; cursor: pointer; border: 1px solid;
            text-decoration: none; display: inline-flex; align-items: center; gap: 4px;
            transition: all .2s; background: transparent;
        }
        .btn-edit { border-color: var(--gold);  color: var(--gold); }
        .btn-edit:hover { background: var(--gold); color: #1a1300; }
        .btn-del  { border-color: var(--red);   color: var(--red);  }
        .btn-del:hover  { background: var(--red);  color: #fff; }

        .empty-row td { text-align: center; color: var(--muted); padding: 32px; }
    

        body.embed-admin {
            background: #0f0e0b !important;
            min-height: auto;
            display: block;
            overflow-x: hidden;
        }
        body.embed-admin aside.sidebar { display: none !important; }
        body.embed-admin .main {
            margin-left: 0 !important;
            max-width: none !important;
            width: 100% !important;
        }
        body.embed-admin .topbar {
            padding: 20px 32px !important;
        }
        body.embed-admin .back-link,
        body.embed-admin .back-btn { display: none !important; }
        body.embed-admin .two-col { grid-template-columns: minmax(280px, 380px) minmax(420px, 1fr); }
        @media (max-width: 900px) {
            body.embed-admin .two-col { grid-template-columns: 1fr; }
        }

    </style>
    <link rel="stylesheet" href="../Estilos/global.css">
</head>
<body class='<%= embedAdmin ? "embed-admin" : "" %>'>

<!-- ══ SIDEBAR ══ -->
<aside class="sidebar">
    <div class="brand">
        <div class="brand-icon">🍺</div>
        <div>
            <div class="brand-name">UNA PA' LA SED</div>
            <div class="brand-sub">Panel Admin</div>
        </div>
    </div>
    <nav class="nav">
        <a class="nav-item" href="<%= request.getContextPath() %>/Vista/MenuAdmin.jsp">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/></svg>
            Dashboard
        </a>
        <a class="nav-item" href="<%= request.getContextPath() %>/Vista/Productos.jsp">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z"/><line x1="3" y1="6" x2="21" y2="6"/><path d="M16 10a4 4 0 0 1-8 0"/></svg>
            Productos
        </a>
        <a class="nav-item" href="<%= request.getContextPath() %>/Vista/Clientes.jsp">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
            Clientes
        </a>
        <a class="nav-item active" href="<%= request.getContextPath() %>/Vista/Fiado.jsp">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 5H7a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2h-2"/><rect x="9" y="3" width="6" height="4" rx="1"/><line x1="9" y1="12" x2="15" y2="12"/><line x1="9" y1="16" x2="12" y2="16"/></svg>
            Fiados
        </a>
        <a class="nav-item" href="<%= request.getContextPath() %>/Vista/MedioPago.jsp">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="5" width="20" height="14" rx="2"/><line x1="2" y1="10" x2="22" y2="10"/></svg>
            Medios de Pago
        </a>
        <a class="nav-item" href="<%= request.getContextPath() %>/Vista/Proveedores.jsp">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>
            Proveedores
        </a>
        <a class="nav-item" href="<%= request.getContextPath() %>/Vista/RegistroUsuario.jsp">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
            Usuarios
        </a>
        <a class="nav-item" href="<%= request.getContextPath() %>/Vista/Roles.jsp">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
            Roles
        </a>
        <a class="nav-item" href="<%= request.getContextPath() %>/Vista/TipoDocumento.jsp">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
            Tipo Documento
        </a>
    </nav>
    <div class="logout-wrap">
        <a class="logout-btn" href="<%= request.getContextPath() %>/LogoutServlet">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
            Cerrar sesión
        </a>
    </div>
</aside>

<!-- ══ MAIN ══ -->
<div class="main">
    <header class="topbar">
        <div>
            <h1>Fiados</h1>
            <p>Registra y gestiona los fiados de tus clientes</p>
        </div>
        <a class="back-btn" href="<%= request.getContextPath() %>/Vista/MenuAdmin.jsp">
            ← Volver al Dashboard
        </a>
    </header>

    <div class="content">

        <% if (!mensaje.isEmpty()) { %>
        <div class="toast <%= tipoMsg %>"><%= mensaje %></div>
        <% } %>

        <div class="two-col">

            <!-- ══ FORMULARIO ══ -->
            <div class="panel">
                <% if (fEditar != null) { %>
                    <div class="panel-title">Editar Fiado</div>
                    <div class="edit-badge">✏️ Modo edición — Fiado #<%= fEditar.getId_fiado() %></div>
                <% } else { %>
                    <div class="panel-title">Nuevo Fiado</div>
                <% } %>

                <form action="Fiado.jsp" method="post">
                    <input type="hidden" name="accion" value="<%= fEditar != null ? "actualizar" : "insertar" %>">
                    <% if (fEditar != null) { %>
                    <input type="hidden" name="id_fiado" value="<%= fEditar.getId_fiado() %>">
                    <% } %>

                    <!-- Cliente -->
                    <div class="form-group">
                        <label>Cliente *</label>
                        <input id="buscarCliente" type="search" placeholder="Buscar por documento, correo, teléfono, nombre…" autocomplete="off">
                        <small style="display:block;color:var(--muted);margin:7px 0;">Usa documento, correo o teléfono para distinguir homónimos.</small>
                        <select id="clienteFiado" name="id_cliente" required>
                            <option value="" disabled <%= fEditar == null ? "selected" : "" %>>Seleccione un cliente</option>
                            <% for (Clientes c : clientes) { %>
                            <option value="<%= c.getId_clientes() %>"
                                <%= (fEditar != null && fEditar.getId_cliente() == c.getId_clientes()) ? "selected" : "" %>>
                                <%= c.getNombreCompleto() %> — Doc. <%= c.getIdentificacion() %> — <%= c.getCorreo() %> — Tel. <%= c.getTelefono() %>
                            </option>
                            <% } %>
                        </select>
                    </div>

                    <!-- Medio de pago -->
                    <div class="form-group">
                        <label>Medio de Pago *</label>
                        <select name="id_medio_pago" required>
                            <option value="" disabled <%= fEditar == null ? "selected" : "" %>>Seleccione medio de pago</option>
                            <% for (Medio_pago mp : medios) { %>
                            <option value="<%= mp.getId_medio_pago() %>"
                                <%= (fEditar != null && fEditar.getId_medio_pago() == mp.getId_medio_pago()) ? "selected" : "" %>>
                                <%= mp.getDescripcion_medio_pago() %>
                            </option>
                            <% } %>
                        </select>
                    </div>

                    <!-- Fecha fiado -->
                    <div class="form-group">
                        <label>Fecha del Fiado *</label>
                        <input type="date" name="Fiado" required
                               value="<%= fEditar != null && fEditar.getFecha_fiado() != null ? fEditar.getFecha_fiado() : "" %>">
                    </div>

                    <!-- Fecha límite -->
                    <div class="form-group">
                        <label>Fecha Límite de Pago *</label>
                        <input type="date" name="Limite" required
                               value="<%= fEditar != null && fEditar.getFecha_limite_pago() != null ? fEditar.getFecha_limite_pago() : "" %>">
                    </div>

                    <!-- Fecha pago (opcional) -->
                    <div class="form-group">
                        <label>Fecha de Pago (opcional)</label>
                        <input type="date" name="Pago"
                               value="<%= (fEditar != null && fEditar.getFecha_pago() != null && !fEditar.getFecha_pago().equals("null")) ? fEditar.getFecha_pago() : "" %>">
                    </div>

                    <!-- Valor -->
                    <div class="form-group">
                        <label>Valor ($) *</label>
                        <input type="number" name="Valor" step="0.01" min="0" required placeholder="0.00"
                               value="<%= fEditar != null ? fEditar.getValor() : "" %>">
                    </div>

                    <div class="btn-row">
                        <button type="submit" class="btn-primary">
                            <%= fEditar != null ? "💾 Guardar cambios" : "➕ Registrar fiado" %>
                        </button>
                        <% if (fEditar != null) { %>
                        <a href="Fiado.jsp" class="btn-secondary">✕ Cancelar</a>
                        <% } else { %>
                        <button type="reset" class="btn-secondary">Limpiar</button>
                        <% } %>
                    </div>
                </form>

                <details style="margin-top:18px;border-top:1px solid var(--line);padding-top:16px;">
                    <summary style="cursor:pointer;color:var(--gold);font-weight:700;">Administrar cupo de crédito</summary>
                    <p style="color:var(--muted);font-size:12px;margin:8px 0 12px;">Ajusta el cupo del cliente seleccionado sin duplicar su ficha.</p>
                    <form action="Fiado.jsp" method="post">
                        <input type="hidden" name="accion" value="actualizar_cupo">
                        <div class="form-group"><label>Cliente</label><select name="id_cliente_cupo" required>
                            <option value="" selected disabled>Seleccione por documento o correo</option>
                            <% for (Clientes c : clientes) { %><option value="<%= c.getId_clientes() %>"><%= c.getNombreCompleto() %> — <%= c.getIdentificacion() %> — saldo $<%= c.getSaldoPendienteTotal() %></option><% } %>
                        </select></div>
                        <div class="form-group"><label>Nuevo cupo (COP)</label><input type="number" name="cupo_credito" min="0" step="1000" required></div>
                        <button type="submit" class="btn-secondary">Guardar cupo</button>
                    </form>
                </details>
            </div>

            <!-- ══ TABLA ══ -->
            <div class="panel">
                <div class="panel-title">Fiados registrados (<%= lista.size() %>)</div>
                <div class="table-wrap">
                    <table>
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Cliente</th>
                                <th>Documento</th>
                                <th>Teléfono</th>
                                <th>Fecha</th>
                                <th>Límite</th>
                                <th>Valor</th>
                                <th>Saldo</th>
                                <th>Estado</th>
                                <th>Acciones</th>
                            </tr>
                        </thead>
                        <tbody>
                        <% if (lista.isEmpty()) { %>
                            <tr class="empty-row"><td colspan="10">No hay fiados registrados aún</td></tr>
                        <% } else {
                            for (Fiado f : lista) {

                                // Nombre cliente
                                String nomCliente = "N/A";
                                String docCliente = "N/A";
                                String telCliente = "N/A";
                                for (Clientes c : clientes) {
                                    if (c.getId_clientes() == f.getId_cliente()) {
                                        nomCliente = c.getNombreCompleto();
                                        docCliente = (c.getTipoDocumento() != null ? c.getTipoDocumento() : "Doc.") + " " + c.getIdentificacion();
                                        telCliente = c.getTelefono();
                                        break;
                                    }
                                }

                                // Estado
                                boolean pagado  = f.getSaldo_pendiente() <= 0 || (f.getFecha_pago() != null && !f.getFecha_pago().equals("null"));
                                boolean vencido = false;
                                if (!pagado && f.getFecha_limite_pago() != null) {
                                    try {
                                        java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("yyyy-MM-dd");
                                        java.util.Date limite = sdf.parse(f.getFecha_limite_pago());
                                        vencido = limite.before(new java.util.Date());
                                    } catch (Exception ex) {}
                                }

                                String badgeClass = pagado ? "badge-green" : vencido ? "badge-red" : "badge-gold";
                                String badgeText  = pagado ? "Pagado"      : vencido ? "Vencido"    : "Pendiente";
                        %>
                        <tr>
                            <td style="color:var(--muted);">#<%= f.getId_fiado() %></td>
                            <td style="font-weight:500;"><%= nomCliente %></td>
                            <td style="color:var(--muted);"><%= docCliente %></td>
                            <td style="color:var(--muted);"><%= telCliente %></td>
                            <td style="color:var(--muted);"><%= f.getFecha_fiado() %></td>
                            <td style="color:<%= vencido && !pagado ? "var(--red)" : "var(--muted)" %>"><%= f.getFecha_limite_pago() %></td>
                            <td style="font-weight:600;color:var(--gold);">$<%= nf.format(f.getValor()) %></td>
                            <td style="font-weight:600;color:<%= f.getSaldo_pendiente() > 0 ? "var(--red)" : "var(--green)" %>">$<%= nf.format(f.getSaldo_pendiente()) %></td>
                            <td><span class="badge <%= badgeClass %>"><%= badgeText %></span></td>
                            <td>
                                <div class="action-btns">
                                    <a class="btn-edit" href="Fiado.jsp?editar=<%= f.getId_fiado() %>">✏️</a>
                                    <form action="Fiado.jsp" method="post" style="display:inline;"
                                          onsubmit="return confirm('¿Eliminar el fiado #<%= f.getId_fiado() %> de <%= nomCliente %>?');">
                                        <input type="hidden" name="accion" value="eliminar">
                                        <input type="hidden" name="id" value="<%= f.getId_fiado() %>">
                                        <button type="submit" class="btn-del">🗑️</button>
                                    </form>
                                </div>
                            </td>
                        </tr>
                        <%  }
                           } %>
                        </tbody>
                    </table>
                </div>
            </div>

        </div><!-- /two-col -->
    </div><!-- /content -->
</div><!-- /main -->

<script>
(function () {
    const search = document.getElementById('buscarCliente');
    const select = document.getElementById('clienteFiado');
    if (search && select) search.addEventListener('input', function () {
        const needle = this.value.toLowerCase().trim();
        Array.from(select.options).forEach(option => {
            if (!option.value) return;
            option.hidden = needle && !option.text.toLowerCase().includes(needle);
        });
    });
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
