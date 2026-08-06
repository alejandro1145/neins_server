<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, Controlador.Conexion, java.text.NumberFormat, java.util.Locale" %>
<%
    // ── Protección de sesión ──────────────────────────────────────────────
    if (session.getAttribute("usuario") == null ||
        !"administrador".equals(session.getAttribute("rol"))) {
        response.sendRedirect(request.getContextPath() + "/Vista/Login.jsp");
        return;
    }
    String nombreAdmin = (String) session.getAttribute("nombre");
    if (nombreAdmin == null) nombreAdmin = (String) session.getAttribute("usuario");
    if (nombreAdmin == null) nombreAdmin = "Usuario";

    // ── Leer datos reales de la BD ────────────────────────────────────────
    Conexion conexionObj = new Conexion();
    Connection con = null;

    int totalUsuarios   = 0;
    int totalClientes   = 0;
    int totalProductos  = 0;
    int stockBajo       = 0;          // productos con stock <= 5
    double totalFiados  = 0;          // suma real de saldos pendientes
    int fiadosPendientes = 0;
    int fiadosVencidos   = 0;         // fecha_limite_pago < HOY y sin pagar

    // Para la tabla de fiados recientes
    java.util.List<String[]> fiados = new java.util.ArrayList<>();
    // Para la tabla de clientes con deuda
    java.util.List<String[]> clientesDeuda = new java.util.ArrayList<>();
    // Para la tabla de productos
    java.util.List<String[]> productos = new java.util.ArrayList<>();
    java.util.List<String[]> alertasAdmin = new java.util.ArrayList<>();

    String errorBD = null;

    try {
        con = conexionObj.getConnection();

        // Totales simples
        ResultSet rs;
        rs = con.createStatement().executeQuery("SELECT COUNT(*) FROM Usuarios");
        if (rs.next()) totalUsuarios = rs.getInt(1);

        rs = con.createStatement().executeQuery("SELECT COUNT(*) FROM clientes");
        if (rs.next()) totalClientes = rs.getInt(1);

        rs = con.createStatement().executeQuery("SELECT COUNT(*) FROM Productos");
        if (rs.next()) totalProductos = rs.getInt(1);

        rs = con.createStatement().executeQuery("SELECT COUNT(*) FROM Productos WHERE stock <= 5");
        if (rs.next()) stockBajo = rs.getInt(1);

        // Fiados pendientes: se usa saldo_pendiente para respetar pagos parciales
        rs = con.createStatement().executeQuery(
            "SELECT COUNT(*), COALESCE(SUM(saldo_pendiente),0) FROM Fiado WHERE saldo_pendiente > 0");
        if (rs.next()) { fiadosPendientes = rs.getInt(1); totalFiados = rs.getDouble(2); }

        // Fiados vencidos (fecha_limite_pago < hoy y con saldo pendiente)
        rs = con.createStatement().executeQuery(
            "SELECT COUNT(*) FROM Fiado WHERE saldo_pendiente > 0 AND fecha_limite_pago < CURDATE()");
        if (rs.next()) fiadosVencidos = rs.getInt(1);

        // Últimos 8 fiados (con nombre del cliente)
        rs = con.createStatement().executeQuery(
            "SELECT f.id_fiado, vc.nombre_completo AS nombre, vc.tipo_documento, vc.identificacion, vc.telefono, " +
            "f.fecha_fiado, f.fecha_limite_pago, f.valor, f.saldo_pendiente, " +
            "CASE WHEN f.saldo_pendiente > 0 AND f.fecha_limite_pago < CURDATE() THEN 'Vencido' " +
            "     WHEN f.saldo_pendiente > 0 THEN 'Pendiente' " +
            "     ELSE 'Pagado' END AS estado " +
            "FROM Fiado f JOIN v_clientes_completo vc ON f.id_cliente = vc.id_cliente " +
            "ORDER BY f.fecha_fiado DESC LIMIT 8");
        while (rs.next()) {
            fiados.add(new String[]{
                String.valueOf(rs.getInt("id_fiado")),
                rs.getString("nombre"),
                rs.getString("tipo_documento") + " " + rs.getString("identificacion"),
                rs.getString("telefono"),
                rs.getString("fecha_fiado"),
                rs.getString("fecha_limite_pago"),
                String.valueOf(rs.getDouble("valor")),
                String.valueOf(rs.getDouble("saldo_pendiente")),
                rs.getString("estado")
            });
        }

        // Clientes con deuda pendiente
        rs = con.createStatement().executeQuery(
            "SELECT vc.id_cliente, vc.nombre_completo AS nombre, vc.telefono, vc.cupo_credito, " +
            "COALESCE(SUM(CASE WHEN f.saldo_pendiente > 0 THEN f.saldo_pendiente ELSE 0 END),0) AS deuda " +
            "FROM v_clientes_completo vc LEFT JOIN Fiado f ON vc.id_cliente = f.id_cliente " +
            "GROUP BY vc.id_cliente, vc.nombre_completo, vc.telefono, vc.cupo_credito " +
            "HAVING deuda > 0 ORDER BY deuda DESC LIMIT 8");
        while (rs.next()) {
            clientesDeuda.add(new String[]{
                rs.getString("nombre"),
                rs.getString("telefono"),
                String.valueOf(rs.getDouble("cupo_credito")),
                String.valueOf(rs.getDouble("deuda"))
            });
        }

        // Productos con bajo stock primero
        rs = con.createStatement().executeQuery(
            "SELECT nombre, precio, stock FROM Productos ORDER BY stock ASC LIMIT 8");
        while (rs.next()) {
            productos.add(new String[]{
                rs.getString("nombre"),
                String.valueOf(rs.getDouble("precio")),
                String.valueOf(rs.getInt("stock"))
            });
        }

        rs = con.createStatement().executeQuery(
            "SELECT descripcion, fecha_alerta FROM Alertas WHERE id_usuarios_destino IS NULL AND leida = 0 ORDER BY fecha_alerta DESC LIMIT 6");
        while (rs.next()) {
            alertasAdmin.add(new String[]{rs.getString("descripcion"), String.valueOf(rs.getTimestamp("fecha_alerta"))});
        }

    } catch (Exception e) {
        errorBD = e.getMessage();
    } finally {
        if (con != null) try { con.close(); } catch (Exception ignore) {}
    }

    // Formateo de moneda colombiana
    NumberFormat nf = NumberFormat.getInstance(new Locale("es","CO"));
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Panel Administrativo — Neins</title>
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@600;700&family=DM+Sans:wght@300;400;500;600&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg:        #0f0e0b;
            --bg2:       #1a1814;
            --bg3:       #222018;
            --gold:      #c9a84c;
            --gold-lt:   #e8c97a;
            --gold-dk:   #9a7a30;
            --red:       #e05252;
            --green:     #4caf7d;
            --orange:    #e8942a;
            --text:      #f0ead8;
            --text-muted:#9a9282;
            --border:    rgba(201,168,76,.18);
            --sidebar-w: 220px;
        }
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: 'DM Sans', sans-serif;
            background: var(--bg);
            color: var(--text);
            display: flex;
            min-height: 100vh;
        }

        /* ── SIDEBAR ── */
        .sidebar {
            width: var(--sidebar-w);
            background: var(--bg2);
            border-right: 1px solid var(--border);
            display: flex;
            flex-direction: column;
            position: fixed;
            top: 0; left: 0; bottom: 0;
            z-index: 100;
        }
        .brand {
            padding: 28px 20px 20px;
            border-bottom: 1px solid var(--border);
            display: flex; align-items: center; gap: 12px;
        }
        .brand-icon {
            width: 38px; height: 38px;
            background: var(--gold);
            border-radius: 10px;
            display: flex; align-items: center; justify-content: center;
            font-size: 20px;
        }
        .brand-name { font-family: 'Playfair Display', serif; font-size: 13px; color: var(--gold); }
        .brand-sub  { font-size: 10px; color: var(--text-muted); letter-spacing: 1px; text-transform: uppercase; }

        .nav { flex: 1; padding: 16px 0; overflow-y: auto; }
        .nav-section { font-size: 10px; letter-spacing: 1.5px; text-transform: uppercase; color: var(--text-muted); padding: 18px 20px 6px; }
        .nav-item {
            display: flex; align-items: center; gap: 10px;
            padding: 11px 20px;
            color: var(--text-muted);
            text-decoration: none;
            font-size: 14px; font-weight: 500;
            border-left: 3px solid transparent;
            transition: all .2s; cursor: pointer;
        }
        .nav-item:hover { color: var(--text); background: rgba(201,168,76,.06); }
        .nav-item.active { color: var(--gold); border-left-color: var(--gold); background: rgba(201,168,76,.08); }
        .nav-item svg { width: 18px; height: 18px; flex-shrink: 0; }

        .logout-wrap { padding: 16px 20px; border-top: 1px solid var(--border); }
        .logout-btn {
            display: flex; align-items: center; gap: 8px;
            color: var(--red); font-size: 13px; font-weight: 500;
            text-decoration: none; background: none; border: none; cursor: pointer;
        }

        /* ── MAIN ── */
        .main { margin-left: var(--sidebar-w); flex: 1; display: flex; flex-direction: column; }

        /* ── TOPBAR ── */
        .topbar {
            padding: 18px 32px;
            border-bottom: 1px solid var(--border);
            display: flex; align-items: center; justify-content: space-between;
            background: var(--bg); position: sticky; top: 0; z-index: 50;
        }
        .topbar h1 { font-family: 'Playfair Display', serif; font-size: 20px; }
        .topbar p  { font-size: 13px; color: var(--text-muted); margin-top: 2px; }
        .topbar-right { display: flex; align-items: center; gap: 12px; }
        .admin-badge {
            background: rgba(201,168,76,.12);
            border: 1px solid var(--border);
            color: var(--gold);
            padding: 6px 14px;
            border-radius: 8px;
            font-size: 12px; font-weight: 600;
        }
        .refresh-btn {
            width: 36px; height: 36px;
            background: var(--bg2); border: 1px solid var(--border);
            border-radius: 8px; color: var(--text-muted);
            cursor: pointer; display: flex; align-items: center; justify-content: center;
        }
        .refresh-btn:hover { color: var(--gold); }

        /* ── CONTENT ── */
        .content { padding: 28px 32px; flex: 1; }
        .admin-frame {
            width: 100%;
            min-height: calc(100vh - 72px);
            border: 0;
            display: none;
            background: var(--bg);
        }
        .admin-frame.active { display: block; }
        .content.hidden { display: none; }

        /* ── ALERTA BD ── */
        .alert-error {
            background: rgba(224,82,82,.1);
            border: 1px solid rgba(224,82,82,.3);
            border-radius: 10px;
            padding: 14px 18px;
            color: var(--red);
            font-size: 13px;
            margin-bottom: 20px;
        }

        /* ── STAT CARDS ── */
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(5, 1fr);
            gap: 16px;
            margin-bottom: 28px;
        }
        .stat-card {
            background: var(--bg2);
            border: 1px solid var(--border);
            border-radius: 14px;
            padding: 20px;
            transition: border-color .2s;
        }
        .stat-card:hover { border-color: var(--gold-dk); }
        .stat-icon { width: 36px; height: 36px; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 18px; margin-bottom: 12px; }
        .stat-icon.gold   { background: rgba(201,168,76,.12); }
        .stat-icon.green  { background: rgba(76,175,125,.12); }
        .stat-icon.red    { background: rgba(224,82,82,.12); }
        .stat-icon.orange { background: rgba(232,148,42,.12); }
        .stat-label { font-size: 12px; color: var(--text-muted); margin-bottom: 8px; }
        .stat-value { font-size: 22px; font-weight: 700; margin-bottom: 8px; }
        .stat-value.c-gold   { color: var(--gold); }
        .stat-value.c-red    { color: var(--red); }
        .stat-value.c-green  { color: var(--green); }
        .stat-value.c-orange { color: var(--orange); }
        .stat-value.c-white  { color: var(--text); }
        .stat-link { font-size: 12px; color: var(--text-muted); text-decoration: none; cursor: pointer; }
        .stat-link:hover { color: var(--gold); }

        /* ── TABLES ROW ── */
        .tables-row { display: grid; grid-template-columns: 1fr 1.1fr 0.9fr; gap: 20px; }

        /* ── PANEL ── */
        .panel { background: var(--bg2); border: 1px solid var(--border); border-radius: 14px; overflow: hidden; }
        .panel-header {
            padding: 16px 20px 12px;
            border-bottom: 1px solid var(--border);
            display: flex; align-items: center; justify-content: space-between;
        }
        .panel-title { font-size: 14px; font-weight: 600; }
        .panel-sub   { font-size: 11px; color: var(--text-muted); margin-top: 2px; }

        .btn-ir {
            font-size: 12px; color: var(--gold);
            background: rgba(201,168,76,.1);
            border: 1px solid rgba(201,168,76,.25);
            padding: 5px 12px; border-radius: 6px;
            text-decoration: none; cursor: pointer;
            transition: background .2s;
        }
        .btn-ir:hover { background: var(--gold); color: var(--bg); }

        table { width: 100%; border-collapse: collapse; }
        thead th {
            font-size: 11px; letter-spacing: .8px; text-transform: uppercase;
            color: var(--text-muted); padding: 9px 16px;
            text-align: left; border-bottom: 1px solid var(--border);
        }
        tbody tr { border-bottom: 1px solid rgba(255,255,255,.04); transition: background .15s; }
        tbody tr:last-child { border-bottom: none; }
        tbody tr:hover { background: rgba(201,168,76,.04); }
        tbody td { padding: 11px 16px; font-size: 13px; }

        .td-red    { color: var(--red);    font-weight: 600; }
        .td-gold   { color: var(--gold);   font-weight: 600; }
        .td-green  { color: var(--green);  font-weight: 600; }
        .td-orange { color: var(--orange); font-weight: 600; }

        /* badges */
        .badge { display: inline-block; padding: 2px 9px; border-radius: 20px; font-size: 11px; font-weight: 600; }
        .badge-red    { background: rgba(224,82,82,.15);   color: var(--red); }
        .badge-green  { background: rgba(76,175,125,.15);  color: var(--green); }
        .badge-orange { background: rgba(232,148,42,.15);  color: var(--orange); }
        .badge-gold   { background: rgba(201,168,76,.15);  color: var(--gold); }

        /* resumen panel */
        .resumen-list { padding: 8px 16px; }
        .resumen-item {
            display: flex; justify-content: space-between; align-items: center;
            padding: 12px 0; border-bottom: 1px solid var(--border); font-size: 13px;
        }
        .resumen-item:last-child { border-bottom: none; }
        .resumen-item span { color: var(--text-muted); }

        .btn-acceso {
            margin: 14px 16px;
            display: flex; align-items: center; justify-content: center; gap: 8px;
            background: var(--gold); color: var(--bg);
            border: none; padding: 11px;
            border-radius: 10px; font-size: 13px; font-weight: 700;
            cursor: pointer; width: calc(100% - 32px);
            text-decoration: none; transition: background .2s;
        }
        .btn-acceso:hover { background: var(--gold-lt); }

        /* Priorizacion operativa: acciones arriba y paneles menos comprimidos. */
        .quick-actions { display:flex; flex-wrap:wrap; gap:10px; margin:0 0 22px; }
        .quick-actions a { display:flex; align-items:center; gap:8px; padding:11px 15px; border-radius:9px; border:1px solid var(--border); background:var(--bg2); color:var(--text); text-decoration:none; font-size:13px; font-weight:600; }
        .quick-actions a:first-child { background:var(--gold); color:var(--bg); border-color:var(--gold); }
        .quick-actions a:hover { border-color:var(--gold); }
        .stats-grid { grid-template-columns:repeat(4, minmax(0, 1fr)); gap:18px; }
        .stat-card { padding:24px; min-height:160px; }
        .tables-row { grid-template-columns:minmax(0, 1.35fr) minmax(320px, .85fr); gap:20px; }
        .tables-row > .panel:nth-child(3) { grid-column:1 / -1; }
        .panel { min-width:0; }
        @media (max-width:1100px) { .stats-grid { grid-template-columns:repeat(2, 1fr); } .tables-row { grid-template-columns:1fr; } .tables-row > .panel:nth-child(3) { grid-column:auto; } }

        /* empty state */
        .empty-row td { text-align: center; color: var(--text-muted); padding: 24px; font-style: italic; }
    </style>
    <link rel="stylesheet" href="../Estilos/global.css">
</head>
<body>

<!-- ═══ SIDEBAR ═══ -->
<aside class="sidebar">
    <div class="brand">
        <div class="brand-icon">🥃</div>
        <div>
            <div class="brand-name">UNA PA' LA SED</div>
            <div class="brand-sub">Licoreria Premium</div>
        </div>
    </div>

    <nav class="nav">
        <div class="nav-section">Principal</div>

        <a class="nav-item active" id="nav-dashboard" onclick="showSection('dashboard', this)">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/></svg>
            Dashboard
        </a>

        <div class="nav-section">Gestión</div>

        <a class="nav-item" href="<%= request.getContextPath() %>/Vista/Productos.jsp?embed=1" target="adminFrame" onclick="showModuleFrame(this)">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10"/></svg>
            Productos
        </a>

        <a class="nav-item" href="<%= request.getContextPath() %>/Vista/Clientes.jsp?embed=1" target="adminFrame" onclick="showModuleFrame(this)">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/></svg>
            Clientes
        </a>

        <a class="nav-item" href="<%= request.getContextPath() %>/Vista/Fiado.jsp?embed=1" target="adminFrame" onclick="showModuleFrame(this)">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 14l6-6m-5.5.5h.01m4.99 5h.01M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16l3.5-2 3.5 2 3.5-2 3.5 2z"/></svg>
            Fiados / Créditos
        </a>

        <a class="nav-item" href="<%= request.getContextPath() %>/Vista/MedioPago.jsp?embed=1" target="adminFrame" onclick="showModuleFrame(this)">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"/></svg>
            Medios de pago
        </a>

        <a class="nav-item" href="<%= request.getContextPath() %>/Vista/Proveedores.jsp?embed=1" target="adminFrame" onclick="showModuleFrame(this)">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 14v3m4-3v3m4-3v3M3 21h18M3 10h18M3 7l9-4 9 4"/></svg>
            Proveedores
        </a>

        <div class="nav-section">Sistema</div>

        <a class="nav-item" href="<%= request.getContextPath() %>/Vista/RegistroUsuario.jsp?embed=1" target="adminFrame" onclick="showModuleFrame(this)">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0"/></svg>
            Usuarios
        </a>

        <a class="nav-item" href="<%= request.getContextPath() %>/Vista/Roles.jsp?embed=1" target="adminFrame" onclick="showModuleFrame(this)">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/></svg>
            Roles
        </a>

        <a class="nav-item" href="<%= request.getContextPath() %>/Vista/TipoDocumento.jsp?embed=1" target="adminFrame" onclick="showModuleFrame(this)">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
            Tipo Documento
        </a>
    </nav>

    <div class="logout-wrap">
        <a href="<%= request.getContextPath() %>/LogoutServlet" class="logout-btn">
            <svg width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/></svg>
            Cerrar sesión
        </a>
    </div>
</aside>

<!-- ═══ MAIN ═══ -->
<div class="main">

    <!-- TOPBAR -->
    <div class="topbar">
        <div>
            <h1>Dashboard Administrativo</h1>
            <p>Bienvenido, <%= nombreAdmin %> — datos en tiempo real</p>
        </div>
        <div class="topbar-right">
            <span class="admin-badge"><%= nombreAdmin %></span>
            <button class="refresh-btn" onclick="location.reload()" title="Actualizar datos">
                <svg width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/></svg>
            </button>
        </div>
    </div>

    <!-- CONTENT -->
    <div class="content" id="section-dashboard">

        <% if (errorBD != null) { %>
        <div class="alert-error">
            ⚠️ <strong>Error de conexión con la base de datos:</strong> <%= errorBD %>
            — Verifique que MySQL esté activo y la base de datos <code>Neins</code> exista.
        </div>
        <% } %>

        <div class="quick-actions" aria-label="Acciones rapidas">
            <a href="<%= request.getContextPath() %>/Vista/Fiado.jsp?embed=1" target="adminFrame" onclick="showModuleFrame(this)">+ Nuevo fiado</a>
            <a href="<%= request.getContextPath() %>/Vista/MedioPago.jsp?embed=1" target="adminFrame" onclick="showModuleFrame(this)">Registrar abono</a>
            <a href="<%= request.getContextPath() %>/Vista/Clientes.jsp?embed=1" target="adminFrame" onclick="showModuleFrame(this)">+ Nuevo cliente</a>
            <a href="<%= request.getContextPath() %>/Vista/Productos.jsp?embed=1" target="adminFrame" onclick="showModuleFrame(this)">Inventario</a>
        </div>

        <!-- STAT CARDS -->
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-icon gold">👥</div>
                <div class="stat-label">Usuarios registrados</div>
                <div class="stat-value c-white"><%= totalUsuarios %></div>
                <a class="stat-link" href="<%= request.getContextPath() %>/Vista/RegistroUsuario.jsp?embed=1" target="adminFrame" onclick="showModuleFrame(this)">Ver todos →</a>
            </div>
            <div class="stat-card">
                <div class="stat-icon green">👤</div>
                <div class="stat-label">Clientes activos</div>
                <div class="stat-value c-white"><%= totalClientes %></div>
                <a class="stat-link" href="<%= request.getContextPath() %>/Vista/Clientes.jsp?embed=1" target="adminFrame" onclick="showModuleFrame(this)">Ver todos →</a>
            </div>
            <div class="stat-card">
                <div class="stat-icon red">💳</div>
                <div class="stat-label">Fiados pendientes</div>
                <div class="stat-value c-red">$<%= nf.format(totalFiados) %></div>
                <a class="stat-link" href="<%= request.getContextPath() %>/Vista/Fiado.jsp?embed=1" target="adminFrame" onclick="showModuleFrame(this)"><%= fiadosPendientes %> activos →</a>
            </div>
            <div class="stat-card">
                <div class="stat-icon orange">⚠️</div>
                <div class="stat-label">Fiados vencidos</div>
                <div class="stat-value c-orange"><%= fiadosVencidos %></div>
                <a class="stat-link" href="<%= request.getContextPath() %>/Vista/Fiado.jsp?embed=1" target="adminFrame" onclick="showModuleFrame(this)">Ver detalle →</a>
            </div>
            <div class="stat-card">
                <div class="stat-icon gold">📦</div>
                <div class="stat-label">Productos / Stock bajo</div>
                <div class="stat-value c-gold"><%= totalProductos %></div>
                <a class="stat-link" href="<%= request.getContextPath() %>/Vista/Productos.jsp?embed=1" target="adminFrame" onclick="showModuleFrame(this)">
                    <% if (stockBajo > 0) { %><span style="color:var(--red)"><%= stockBajo %> con stock bajo ⚠️</span><% } else { %>Ver catálogo →<% } %>
                </a>
            </div>
        </div>

        <!-- TABLES ROW -->
        <div class="tables-row">

            <!-- Panel: Fiados recientes -->
            <div class="panel">
                <div class="panel-header">
                    <div>
                        <div class="panel-title">Fiados recientes</div>
                        <div class="panel-sub">Últimas 8 operaciones</div>
                    </div>
                    <a class="btn-ir" href="<%= request.getContextPath() %>/Vista/Fiado.jsp?embed=1" target="adminFrame" onclick="showModuleFrame(this)">Ver todos</a>
                </div>
                <table>
                    <thead>
                        <tr>
                            <th>Cliente</th>
                            <th>Documento</th>
                            <th>Teléfono</th>
                            <th>Valor</th>
                            <th>Saldo</th>
                            <th>Estado</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% if (fiados.isEmpty()) { %>
                        <tr class="empty-row"><td colspan="6">No hay fiados registrados</td></tr>
                        <% } else { for (String[] f : fiados) {
                            double valF = Double.parseDouble(f[6]);
                            double saldoF = Double.parseDouble(f[7]);
                            String estado = f[8];
                        %>
                        <tr>
                            <td><%= f[1] %></td>
                            <td style="font-size:12px;color:var(--text-muted)"><%= f[2] %></td>
                            <td style="font-size:12px;color:var(--text-muted)"><%= f[3] %></td>
                            <td class="td-red">$<%= nf.format(valF) %></td>
                            <td class="<%= saldoF > 0 ? "td-red" : "td-green" %>">$<%= nf.format(saldoF) %></td>
                            <td>
                                <% if ("Vencido".equals(estado)) { %>
                                    <span class="badge badge-red">Vencido</span>
                                <% } else if ("Pendiente".equals(estado)) { %>
                                    <span class="badge badge-orange">Pendiente</span>
                                <% } else { %>
                                    <span class="badge badge-green">Pagado</span>
                                <% } %>
                            </td>
                        </tr>
                        <% } } %>
                    </tbody>
                </table>
            </div>

            <!-- Panel: Clientes con deuda -->
            <div class="panel">
                <div class="panel-header">
                    <div>
                        <div class="panel-title">Clientes con deuda</div>
                        <div class="panel-sub">Ordenados por mayor deuda</div>
                    </div>
                    <a class="btn-ir" href="<%= request.getContextPath() %>/Vista/Clientes.jsp?embed=1" target="adminFrame" onclick="showModuleFrame(this)">Ver todos</a>
                </div>
                <table>
                    <thead>
                        <tr>
                            <th>Cliente</th>
                            <th>Teléfono</th>
                            <th>Cupo</th>
                            <th>Deuda</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% if (clientesDeuda.isEmpty()) { %>
                        <tr class="empty-row"><td colspan="4">Ningún cliente tiene deuda activa 🎉</td></tr>
                        <% } else { for (String[] c : clientesDeuda) {
                            double cupo = Double.parseDouble(c[2]);
                            double deuda = Double.parseDouble(c[3]);
                        %>
                        <tr>
                            <td><%= c[0] %></td>
                            <td style="font-size:12px;color:var(--text-muted)"><%= c[1] %></td>
                            <td class="td-gold">$<%= nf.format(cupo) %></td>
                            <td class="td-red">$<%= nf.format(deuda) %></td>
                        </tr>
                        <% } } %>
                    </tbody>
                </table>
            </div>

            <!-- Panel: Resumen + accesos rápidos -->
            <div class="panel">
                <div class="panel-header">
                    <div class="panel-title">Accesos rápidos</div>
                </div>
                <div class="resumen-list">
                    <% if (!alertasAdmin.isEmpty()) { for (String[] alerta : alertasAdmin) { %>
                    <div class="resumen-item">
                        <span><%= alerta[0] %><br><small><%= alerta[1] %></small></span>
                        <strong class="td-gold">Nueva</strong>
                    </div>
                    <% } } %>
                    <div class="resumen-item">
                        <span>Total usuarios</span>
                        <strong class="td-gold"><%= totalUsuarios %></strong>
                    </div>
                    <div class="resumen-item">
                        <span>Total clientes</span>
                        <strong class="td-gold"><%= totalClientes %></strong>
                    </div>
                    <div class="resumen-item">
                        <span>Cartera activa</span>
                        <strong class="td-red">$<%= nf.format(totalFiados) %></strong>
                    </div>
                    <div class="resumen-item">
                        <span>Fiados vencidos</span>
                        <strong class="<%= fiadosVencidos > 0 ? "td-red" : "td-green" %>"><%= fiadosVencidos %></strong>
                    </div>
                    <div class="resumen-item">
                        <span>Productos totales</span>
                        <strong class="td-gold"><%= totalProductos %></strong>
                    </div>
                    <div class="resumen-item">
                        <span>Stock bajo (≤5)</span>
                        <strong class="<%= stockBajo > 0 ? "td-orange" : "td-green" %>"><%= stockBajo %></strong>
                    </div>
                </div>
                <a class="btn-acceso" href="<%= request.getContextPath() %>/Vista/Fiado.jsp?embed=1" target="adminFrame" onclick="showModuleFrame(this)">📋 Gestionar fiados</a>
                <a class="btn-acceso" href="<%= request.getContextPath() %>/Vista/Productos.jsp?embed=1" target="adminFrame" onclick="showModuleFrame(this)" style="margin-top:0;background:var(--bg3);color:var(--gold);border:1px solid var(--border);">📦 Ver productos</a>
            </div>

        </div><!-- /tables-row -->

        <!-- Fila inferior: productos con bajo stock -->
        <% if (stockBajo > 0) { %>
        <div class="panel" style="margin-top:20px">
            <div class="panel-header">
                <div>
                    <div class="panel-title">⚠️ Productos con stock bajo o agotado</div>
                    <div class="panel-sub">Stock ≤ 5 unidades — requiere atención</div>
                </div>
                <a class="btn-ir" href="<%= request.getContextPath() %>/Vista/Productos.jsp?embed=1" target="adminFrame" onclick="showModuleFrame(this)">Gestionar</a>
            </div>
            <table>
                <thead>
                    <tr><th>Producto</th><th>Precio</th><th>Stock</th><th>Alerta</th></tr>
                </thead>
                <tbody>
                    <% for (String[] p : productos) {
                        int stk = Integer.parseInt(p[2]);
                        if (stk > 5) continue;
                        double prec = Double.parseDouble(p[1]);
                    %>
                    <tr>
                        <td><%= p[0] %></td>
                        <td class="td-gold">$<%= nf.format(prec) %></td>
                        <td class="<%= stk == 0 ? "td-red" : "td-orange" %>"><%= stk %></td>
                        <td>
                            <% if (stk == 0) { %>
                                <span class="badge badge-red">Agotado</span>
                            <% } else { %>
                                <span class="badge badge-orange">Bajo</span>
                            <% } %>
                        </td>
                    </tr>
                    <% } %>
                </tbody>
            </table>
        </div>
        <% } %>

    </div><!-- /content -->
    <iframe id="admin-frame" class="admin-frame" name="adminFrame" title="Modulo administrativo"></iframe>
</div><!-- /main -->

<script>
    // Marcar nav-item activo al hacer clic (para los que no redirigen)
    function showSection(name, el) {
        document.querySelectorAll('.nav-item').forEach(a => a.classList.remove('active'));
        if (el) el.classList.add('active');
        document.getElementById('section-dashboard').classList.remove('hidden');
        document.getElementById('admin-frame').classList.remove('active');
    }

    function showModuleFrame(el) {
        document.querySelectorAll('.nav-item').forEach(a => a.classList.remove('active'));
        if (el && el.classList.contains('nav-item')) el.classList.add('active');
        document.getElementById('section-dashboard').classList.add('hidden');
        document.getElementById('admin-frame').classList.add('active');
    }

    // Marcar automáticamente activo si venimos de un link directo
    document.querySelectorAll('.nav-item[href]').forEach(a => {
        if (window.location.pathname === new URL(a.href, location.origin).pathname) {
            a.classList.add('active');
        }
    });
</script>
    <script src="../Scripts/premium-ui.js"></script>
</body>
</html>



