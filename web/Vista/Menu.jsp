<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%
    // Verificar sesión de cliente
    if (session.getAttribute("usuario") == null) {
        response.sendRedirect(request.getContextPath() + "/Vista/Login.jsp");
        return;
    }
    String rol = (String) session.getAttribute("rol");
    if ("administrador".equals(rol)) {
        response.sendRedirect(request.getContextPath() + "/Vista/MenuAdmin.jsp");
        return;
    }

    String nombreCliente = (String) session.getAttribute("usuario");
    if (nombreCliente == null) nombreCliente = "Cliente";

    // Variables para mostrar datos del cliente
    double totalDeuda      = 0;
    double cupoTotal       = 0;
    double cupoDisponible  = 0;
    double porcentajeUso   = 0;
    String estadoCuenta    = "Al día";
    boolean tieneMoras     = false;

    // Obtener datos reales del cliente desde BD
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection con = DriverManager.getConnection(
            "jdbc:mysql://localhost:3307/Neins?useSSL=false&serverTimezone=America/Bogota",
            "root", "");

        Integer idUsuario = (Integer) session.getAttribute("id_usuario");
        if (idUsuario != null) {
            // Buscar cliente por identificacion del usuario
            String sqlCliente = "SELECT c.id_cliente, c.cupo_credito FROM clientes c " +
                "JOIN Usuarios u ON u.id_usuarios = c.id_usuario WHERE u.id_usuarios = ?";
            PreparedStatement psC = con.prepareStatement(sqlCliente);
            psC.setInt(1, idUsuario);
            ResultSet rsC = psC.executeQuery();

            int idCliente = -1;
            if (rsC.next()) {
                idCliente    = rsC.getInt("id_cliente");
                cupoTotal    = rsC.getDouble("cupo_credito");
            }
            rsC.close(); psC.close();

            if (idCliente > 0) {
                // Deuda pendiente (sin fecha_pago)
                String sqlDeuda = "SELECT COALESCE(SUM(valor),0) AS deuda FROM Fiado " +
                    "WHERE id_cliente = ? AND fecha_pago IS NULL";
                PreparedStatement psD = con.prepareStatement(sqlDeuda);
                psD.setInt(1, idCliente);
                ResultSet rsD = psD.executeQuery();
                if (rsD.next()) totalDeuda = rsD.getDouble("deuda");
                rsD.close(); psD.close();

                // Moras: fiados vencidos sin pago
                String sqlMora = "SELECT COUNT(*) AS moras FROM Fiado " +
                    "WHERE id_cliente = ? AND fecha_pago IS NULL AND fecha_limite_pago < CURDATE()";
                PreparedStatement psM = con.prepareStatement(sqlMora);
                psM.setInt(1, idCliente);
                ResultSet rsM = psM.executeQuery();
                if (rsM.next()) tieneMoras = rsM.getInt("moras") > 0;
                rsM.close(); psM.close();
            }
        }

        con.close();
    } catch (Exception e) {
        // Si falla la BD se muestran los valores en 0
    }

    cupoDisponible = cupoTotal - totalDeuda;
    if (cupoDisponible < 0) cupoDisponible = 0;
    porcentajeUso  = (cupoTotal > 0) ? (totalDeuda / cupoTotal) * 100 : 0;
    estadoCuenta   = tieneMoras ? "Con moras" : "Al día";

    // Formato COP sin decimales
    java.text.NumberFormat nf = java.text.NumberFormat.getIntegerInstance(new java.util.Locale("es","CO"));
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mi Cartera — Una Pa' La Sed</title>
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
        .brand-text { line-height: 1.2; }
        .brand-name {
            font-family: 'Playfair Display', serif;
            font-size: 13px;
            color: var(--gold);
            letter-spacing: .5px;
        }
        .brand-sub {
            font-size: 10px;
            color: var(--text-muted);
            letter-spacing: 1px;
            text-transform: uppercase;
        }

        .nav { flex: 1; padding: 16px 0; }
        .nav-item {
            display: flex; align-items: center; gap: 10px;
            padding: 11px 20px;
            color: var(--text-muted);
            text-decoration: none;
            font-size: 14px;
            font-weight: 500;
            border-left: 3px solid transparent;
            transition: all .2s;
            cursor: pointer;
        }
        .nav-item:hover { color: var(--text); background: rgba(201,168,76,.06); }
        .nav-item.active {
            color: var(--gold);
            border-left-color: var(--gold);
            background: rgba(201,168,76,.08);
        }
        .nav-item svg { width: 18px; height: 18px; flex-shrink: 0; }

        .logout-wrap { padding: 16px 20px; border-top: 1px solid var(--border); }
        .logout-btn {
            display: flex; align-items: center; gap: 8px;
            color: var(--red);
            font-size: 13px;
            font-weight: 500;
            text-decoration: none;
            cursor: pointer;
            background: none; border: none;
        }

        /* ── MAIN ── */
        .main {
            margin-left: var(--sidebar-w);
            flex: 1;
            display: flex;
            flex-direction: column;
        }

        /* ── TOPBAR ── */
        .topbar {
            padding: 20px 32px;
            border-bottom: 1px solid var(--border);
            display: flex;
            align-items: center;
            justify-content: space-between;
            background: var(--bg);
            position: sticky; top: 0; z-index: 50;
        }
        .topbar-left h1 {
            font-family: 'Playfair Display', serif;
            font-size: 22px;
        }
        .topbar-left p { font-size: 13px; color: var(--text-muted); margin-top: 2px; }

        .notif-btn {
            display: flex; align-items: center; gap: 8px;
            background: var(--bg2);
            border: 1px solid var(--border);
            color: var(--text);
            padding: 8px 14px;
            border-radius: 8px;
            font-size: 13px;
            cursor: pointer;
            position: relative;
        }
        .notif-badge {
            background: var(--red);
            color: #fff;
            font-size: 10px;
            font-weight: 700;
            width: 18px; height: 18px;
            border-radius: 50%;
            display: flex; align-items: center; justify-content: center;
        }

        /* ── CONTENT ── */
        .content { padding: 28px 32px; flex: 1; }

        /* ── STATS TOP ── */
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 16px;
            margin-bottom: 24px;
        }

        .stat-card {
            background: var(--bg2);
            border: 1px solid var(--border);
            border-radius: 14px;
            padding: 20px;
            display: flex;
            flex-direction: column;
            gap: 6px;
            transition: border-color .2s;
        }
        .stat-card:hover { border-color: var(--gold-dk); }

        .stat-label {
            font-size: 12px;
            color: var(--text-muted);
        }
        .stat-value {
            font-size: 26px;
            font-weight: 700;
            line-height: 1;
        }
        .stat-value.red   { color: var(--red); }
        .stat-value.green { color: var(--green); }
        .stat-value.white { color: var(--text); }
        .stat-value.gold  { color: var(--gold); }

        .stat-sub {
            font-size: 12px;
            color: var(--text-muted);
            margin-top: 2px;
        }
        .stat-icon {
            width: 36px; height: 36px;
            border-radius: 8px;
            display: flex; align-items: center; justify-content: center;
            font-size: 18px;
            margin-bottom: 4px;
        }
        .stat-icon.red-bg   { background: rgba(224,82,82,.15); }
        .stat-icon.green-bg { background: rgba(76,175,125,.15); }
        .stat-icon.gold-bg  { background: rgba(201,168,76,.15); }
        .stat-icon.blue-bg  { background: rgba(100,160,255,.15); }

        .stat-link {
            font-size: 12px;
            color: var(--text-muted);
            text-decoration: none;
            display: flex; align-items: center; gap: 4px;
            margin-top: 4px;
        }
        .stat-link:hover { color: var(--gold); }

        /* ── BOTTOM GRID ── */
        .bottom-grid {
            display: grid;
            grid-template-columns: 1fr 1fr 300px;
            gap: 20px;
        }

        /* ── PANEL BASE ── */
        .panel {
            background: var(--bg2);
            border: 1px solid var(--border);
            border-radius: 14px;
            padding: 22px;
        }
        .panel-title {
            font-family: 'Playfair Display', serif;
            font-size: 15px;
            color: var(--text);
            margin-bottom: 20px;
        }

        /* ── DONUT ── */
        .donut-wrap {
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 20px;
        }
        .donut-container {
            position: relative;
            width: 140px; height: 140px;
        }
        .donut-svg { width: 140px; height: 140px; transform: rotate(-90deg); }
        .donut-track { fill: none; stroke: var(--bg3); stroke-width: 12; }
        .donut-fill  {
            fill: none;
            stroke: var(--gold);
            stroke-width: 12;
            stroke-linecap: round;
            stroke-dasharray: 351.86;
            transition: stroke-dashoffset 1s ease;
        }
        .donut-label {
            position: absolute;
            top: 50%; left: 50%;
            transform: translate(-50%,-50%);
            text-align: center;
        }
        .donut-pct {
            font-size: 22px;
            font-weight: 700;
            color: var(--text);
            line-height: 1;
        }
        .donut-sub {
            font-size: 11px;
            color: var(--text-muted);
        }

        .donut-rows { width: 100%; }
        .donut-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 8px 0;
            border-bottom: 1px solid var(--border);
            font-size: 13px;
        }
        .donut-row:last-child { border-bottom: none; }
        .donut-row-label { color: var(--text-muted); }
        .donut-row-val   { font-weight: 600; }

        /* ── PAY BUTTON ── */
        .pay-btn {
            width: 100%;
            margin-top: 16px;
            padding: 13px;
            background: var(--gold);
            color: #1a1300;
            border: none;
            border-radius: 10px;
            font-size: 14px;
            font-weight: 700;
            cursor: pointer;
            display: flex; align-items: center; justify-content: center; gap: 8px;
            transition: background .2s;
            text-decoration: none;
        }
        .pay-btn:hover { background: var(--gold-lt); }

        /* ── ACTIVIDAD RECIENTE ── */
        .activity-list { display: flex; flex-direction: column; gap: 0; }
        .activity-row {
            display: grid;
            grid-template-columns: 90px 1fr auto;
            gap: 12px;
            align-items: center;
            padding: 11px 0;
            border-bottom: 1px solid var(--border);
            font-size: 13px;
        }
        .activity-row:last-child { border-bottom: none; }
        .activity-date { color: var(--text-muted); font-size: 12px; }
        .activity-desc { color: var(--text); }
        .activity-val  { font-weight: 700; }
        .activity-val.red   { color: var(--red); }
        .activity-val.green { color: var(--green); }

        /* ── NAVEGACIÓN RÁPIDA ── */
        .quick-list { display: flex; flex-direction: column; gap: 10px; }
        .quick-item {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 13px 16px;
            background: var(--bg3);
            border: 1px solid var(--border);
            border-radius: 10px;
            text-decoration: none;
            color: var(--text);
            font-size: 13px;
            font-weight: 500;
            transition: border-color .2s, background .2s;
            cursor: pointer;
        }
        .quick-item:hover {
            border-color: var(--gold-dk);
            background: rgba(201,168,76,.06);
            color: var(--gold);
        }
        .quick-item-left { display: flex; align-items: center; gap: 10px; }
        .quick-icon {
            width: 30px; height: 30px;
            background: rgba(201,168,76,.12);
            border-radius: 7px;
            display: flex; align-items: center; justify-content: center;
            font-size: 15px;
        }

        /* estado cuenta badge */
        .estado-badge {
            display: inline-flex; align-items: center; gap: 6px;
            font-size: 16px; font-weight: 700;
        }
        .estado-badge.green { color: var(--green); }
        .estado-badge.red   { color: var(--red); }
        .estado-sub { font-size: 12px; color: var(--text-muted); margin-top: 4px; }

        /* ── SECCIONES OCULTAS ── */
        .section { display: none; }
        .section.active { display: block; }
    </style>
    <link rel="stylesheet" href="../Estilos/global.css">
</head>
<body>

<!-- ══ SIDEBAR ══ -->
<aside class="sidebar">
    <div class="brand">
        <div class="brand-icon">🍺</div>
        <div class="brand-text">
            <div class="brand-name">UNA PA' LA SED</div>
            <div class="brand-sub">Cartera Digital</div>
        </div>
    </div>

    <nav class="nav">
        <a class="nav-item active" onclick="showSection('resumen', this)">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <rect x="3" y="3" width="7" height="7" rx="1"/>
                <rect x="14" y="3" width="7" height="7" rx="1"/>
                <rect x="3" y="14" width="7" height="7" rx="1"/>
                <rect x="14" y="14" width="7" height="7" rx="1"/>
            </svg>
            Mi resumen
        </a>
        <a class="nav-item" onclick="showSection('fiados', this)">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M9 5H7a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2h-2"/>
                <rect x="9" y="3" width="6" height="4" rx="1"/>
                <line x1="9" y1="12" x2="15" y2="12"/><line x1="9" y1="16" x2="12" y2="16"/>
            </svg>
            Mis fiados
        </a>
        <a class="nav-item" onclick="showSection('pagos', this)">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <rect x="2" y="5" width="20" height="14" rx="2"/>
                <line x1="2" y1="10" x2="22" y2="10"/>
            </svg>
            Mis pagos
        </a>
        <a class="nav-item" onclick="showSection('productos', this)">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z"/>
                <line x1="3" y1="6" x2="21" y2="6"/>
                <path d="M16 10a4 4 0 0 1-8 0"/>
            </svg>
            Productos
        </a>
        <a class="nav-item" onclick="showSection('notif', this)">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
                <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
            </svg>
            Notificaciones
        </a>
        <a class="nav-item" onclick="showSection('perfil', this)">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
                <circle cx="12" cy="7" r="4"/>
            </svg>
            Mi perfil
        </a>
    </nav>

    <div class="logout-wrap">
        <a class="logout-btn" href="<%= request.getContextPath() %>/LogoutServlet">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/>
                <polyline points="16 17 21 12 16 7"/>
                <line x1="21" y1="12" x2="9" y2="12"/>
            </svg>
            Cerrar sesión
        </a>
    </div>
</aside>

<!-- ══ MAIN ══ -->
<div class="main">

    <!-- TOPBAR -->
    <header class="topbar">
        <div class="topbar-left">
            <h1>Hola, <%= nombreCliente %></h1>
            <p>Bienvenido a tu cartera digital</p>
        </div>
        <button class="notif-btn">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
                <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
            </svg>
            Notificaciones
            <span class="notif-badge"><%= tieneMoras ? "!" : "0" %></span>
        </button>
    </header>

    <!-- CONTENT -->
    <div class="content">

        <!-- ══ SECCIÓN: MI RESUMEN ══ -->
        <div id="sec-resumen" class="section active">

            <!-- TARJETAS TOP -->
            <div class="stats-grid">

                <!-- Total que debes -->
                <div class="stat-card">
                    <div class="stat-label">Total que debes</div>
                    <div class="stat-icon red-bg">💳</div>
                    <div class="stat-value red">$<%= nf.format(totalDeuda) %></div>
                    <a class="stat-link" onclick="showSection('fiados')">
                        Ver detalle &nbsp;→
                    </a>
                </div>

                <!-- Puedes fiar hasta -->
                <div class="stat-card">
                    <div class="stat-label">Puedes fiar hasta</div>
                    <div class="stat-icon green-bg">🏦</div>
                    <div class="stat-value green">$<%= nf.format(cupoDisponible) %></div>
                    <div class="stat-sub">Límite disponible</div>
                </div>

                <!-- Límite total de crédito -->
                <div class="stat-card">
                    <div class="stat-label">Límite total de crédito</div>
                    <div class="stat-icon gold-bg">🛡️</div>
                    <div class="stat-value white">$<%= nf.format(cupoTotal) %></div>
                    <div class="stat-sub">Tu cupo aprobado</div>
                </div>

                <!-- Estado de cuenta -->
                <div class="stat-card">
                    <div class="stat-label">Estado de cuenta</div>
                    <div class="stat-icon blue-bg">📋</div>
                    <div class="estado-badge <%= tieneMoras ? "red" : "green" %>">
                        <%= estadoCuenta %>
                        <%= tieneMoras ? "⚠️" : "✅" %>
                    </div>
                    <div class="estado-sub"><%= tieneMoras ? "Tienes pagos vencidos" : "Sin moras" %></div>
                </div>
            </div>

            <!-- BOTTOM GRID -->
            <div class="bottom-grid">

                <!-- Donut de resumen -->
                <div class="panel">
                    <div class="panel-title">Resumen de tu cuenta</div>
                    <div class="donut-wrap">
                        <%
                            double dashOffset = 351.86 * (1 - porcentajeUso / 100.0);
                            if (dashOffset < 0) dashOffset = 0;
                        %>
                        <div class="donut-container">
                            <svg class="donut-svg" viewBox="0 0 120 120">
                                <circle class="donut-track" cx="60" cy="60" r="56"/>
                                <circle class="donut-fill" cx="60" cy="60" r="56"
                                    style="stroke-dashoffset:<%= String.format("%.2f", dashOffset) %>"/>
                            </svg>
                            <div class="donut-label">
                                <div class="donut-pct"><%= String.format("%.0f", porcentajeUso) %>%</div>
                                <div class="donut-sub">Utilizado</div>
                            </div>
                        </div>

                        <div class="donut-rows">
                            <div class="donut-row">
                                <span class="donut-row-label">Límite total</span>
                                <span class="donut-row-val">$<%= nf.format(cupoTotal) %></span>
                            </div>
                            <div class="donut-row">
                                <span class="donut-row-label">Total que debes</span>
                                <span class="donut-row-val" style="color:var(--red)">$<%= nf.format(totalDeuda) %></span>
                            </div>
                            <div class="donut-row">
                                <span class="donut-row-label">Disponible para fiar</span>
                                <span class="donut-row-val" style="color:var(--green)">$<%= nf.format(cupoDisponible) %></span>
                            </div>
                        </div>

                        <a class="pay-btn" onclick="showSection('pagos')">
                            Pagar ahora &nbsp;
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <rect x="2" y="5" width="20" height="14" rx="2"/>
                                <line x1="2" y1="10" x2="22" y2="10"/>
                            </svg>
                        </a>
                    </div>
                </div>

                <!-- Actividad reciente -->
                <div class="panel">
                    <div class="panel-title">Actividad reciente</div>
                    <div class="activity-list" id="actividadLista">
                        <%
                        // Cargar actividad reciente del cliente
                        try {
                            Class.forName("com.mysql.cj.jdbc.Driver");
                            Connection conA = DriverManager.getConnection(
                                "jdbc:mysql://localhost:3307/Neins?useSSL=false&serverTimezone=America/Bogota",
                                "root", "");

                            Integer idUsuarioA = (Integer) session.getAttribute("id_usuario");
                            if (idUsuarioA != null) {
                                String sqlIdC = "SELECT c.id_cliente FROM clientes c " +
                                    "JOIN Usuarios u ON u.id_usuarios = c.id_usuario WHERE u.id_usuarios = ?";
                                PreparedStatement psIdC = conA.prepareStatement(sqlIdC);
                                psIdC.setInt(1, idUsuarioA);
                                ResultSet rsIdC = psIdC.executeQuery();

                                if (rsIdC.next()) {
                                    int idClienteA = rsIdC.getInt("id_cliente");

                                    String sqlAct = "SELECT fecha_fiado, valor, fecha_pago FROM Fiado " +
                                        "WHERE id_cliente = ? ORDER BY fecha_fiado DESC LIMIT 5";
                                    PreparedStatement psA = conA.prepareStatement(sqlAct);
                                    psA.setInt(1, idClienteA);
                                    ResultSet rsA = psA.executeQuery();

                                    boolean hayActividad = false;
                                    while (rsA.next()) {
                                        hayActividad = true;
                                        java.sql.Date fFiado = rsA.getDate("fecha_fiado");
                                        double valorA = rsA.getDouble("valor");
                                        java.sql.Date fPago  = rsA.getDate("fecha_pago");
                                        boolean pagado = (fPago != null);
                        %>
                                    <div class="activity-row">
                                        <span class="activity-date"><%= fFiado != null ? fFiado.toString() : "-" %></span>
                                        <span class="activity-desc"><%= pagado ? "Pago recibido" : "Compra de productos" %></span>
                                        <span class="activity-val <%= pagado ? "green" : "red" %>">
                                            <%= pagado ? "-" : "+" %>$<%= nf.format(valorA) %>
                                        </span>
                                    </div>
                        <%
                                    }
                                    rsA.close(); psA.close();

                                    if (!hayActividad) {
                        %>
                                    <div style="color:var(--text-muted);font-size:13px;padding:20px 0;text-align:center;">
                                        No hay actividad reciente
                                    </div>
                        <%      }
                                }
                                rsIdC.close(); psIdC.close();
                            }
                            conA.close();
                        } catch (Exception eA) { %>
                            <div style="color:var(--text-muted);font-size:13px;padding:20px 0;text-align:center;">
                                Sin datos disponibles
                            </div>
                        <% } %>
                    </div>
                </div>

                <!-- Navegación rápida -->
                <div class="panel">
                    <div class="panel-title">Navegación rápida</div>
                    <div class="quick-list">
                        <a class="quick-item" onclick="showSection('fiados')">
                            <div class="quick-item-left">
                                <div class="quick-icon">📋</div>
                                Ver mis fiados
                            </div>
                            <span>→</span>
                        </a>
                        <a class="quick-item" onclick="showSection('pagos')">
                            <div class="quick-item-left">
                                <div class="quick-icon">💳</div>
                                Mis pagos
                            </div>
                            <span>→</span>
                        </a>
                        <a class="quick-item" onclick="showSection('productos')">
                            <div class="quick-item-left">
                                <div class="quick-icon">🛒</div>
                                Catálogo de productos
                            </div>
                            <span>→</span>
                        </a>
                        <a class="quick-item" onclick="showSection('fiados')">
                            <div class="quick-item-left">
                                <div class="quick-icon">📄</div>
                                Historial completo
                            </div>
                            <span>→</span>
                        </a>
                    </div>
                </div>
            </div>
        </div><!-- /sec-resumen -->

        <!-- ══ SECCIÓN: MIS FIADOS ══ -->
        <div id="sec-fiados" class="section">
            <div class="panel">
                <div class="panel-title">Mis Fiados</div>
                <table style="width:100%;border-collapse:collapse;font-size:13px;">
                    <thead>
                        <tr style="border-bottom:1px solid var(--border);">
                            <th style="padding:10px 8px;text-align:left;color:var(--text-muted);font-weight:500;">Fecha</th>
                            <th style="padding:10px 8px;text-align:left;color:var(--text-muted);font-weight:500;">Límite pago</th>
                            <th style="padding:10px 8px;text-align:right;color:var(--text-muted);font-weight:500;">Valor</th>
                            <th style="padding:10px 8px;text-align:center;color:var(--text-muted);font-weight:500;">Estado</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                        try {
                            Class.forName("com.mysql.cj.jdbc.Driver");
                            Connection conF = DriverManager.getConnection(
                                "jdbc:mysql://localhost:3307/Neins?useSSL=false&serverTimezone=America/Bogota",
                                "root", "");
                            Integer idU = (Integer) session.getAttribute("id_usuario");
                            if (idU != null) {
                                String sqlIdF = "SELECT c.id_cliente FROM clientes c " +
                                    "JOIN Usuarios u ON u.id_usuarios = c.id_usuario WHERE u.id_usuarios = ?";
                                PreparedStatement psF0 = conF.prepareStatement(sqlIdF);
                                psF0.setInt(1, idU);
                                ResultSet rsF0 = psF0.executeQuery();
                                if (rsF0.next()) {
                                    int idCF = rsF0.getInt("id_cliente");
                                    String sqlF = "SELECT fecha_fiado, fecha_limite_pago, fecha_pago, valor FROM Fiado " +
                                        "WHERE id_cliente = ? ORDER BY fecha_fiado DESC";
                                    PreparedStatement psF = conF.prepareStatement(sqlF);
                                    psF.setInt(1, idCF);
                                    ResultSet rsF = psF.executeQuery();
                                    boolean hayF = false;
                                    while (rsF.next()) {
                                        hayF = true;
                                        java.sql.Date fF = rsF.getDate("fecha_fiado");
                                        java.sql.Date fLP = rsF.getDate("fecha_limite_pago");
                                        java.sql.Date fP  = rsF.getDate("fecha_pago");
                                        double valF = rsF.getDouble("valor");
                                        boolean pagadoF = (fP != null);
                                        boolean vencidoF = !pagadoF && fLP != null && fLP.before(new java.util.Date());
                        %>
                        <tr style="border-bottom:1px solid var(--border);">
                            <td style="padding:11px 8px;"><%= fF %></td>
                            <td style="padding:11px 8px;color:<%= vencidoF ? "var(--red)" : "var(--text-muted)" %>"><%= fLP %></td>
                            <td style="padding:11px 8px;text-align:right;font-weight:600;">$<%= nf.format(valF) %></td>
                            <td style="padding:11px 8px;text-align:center;">
                                <span style="padding:3px 10px;border-radius:20px;font-size:11px;font-weight:600;
                                    background:<%= pagadoF ? "rgba(76,175,125,.15)" : vencidoF ? "rgba(224,82,82,.15)" : "rgba(201,168,76,.15)" %>;
                                    color:<%= pagadoF ? "var(--green)" : vencidoF ? "var(--red)" : "var(--gold)" %>">
                                    <%= pagadoF ? "Pagado" : vencidoF ? "Vencido" : "Pendiente" %>
                                </span>
                            </td>
                        </tr>
                        <%      }
                                rsF.close(); psF.close();
                                if (!hayF) { %>
                        <tr><td colspan="4" style="padding:24px;text-align:center;color:var(--text-muted);">No tienes fiados registrados</td></tr>
                        <%      }
                                }
                                rsF0.close(); psF0.close();
                            }
                            conF.close();
                        } catch (Exception eF) { %>
                        <tr><td colspan="4" style="padding:24px;text-align:center;color:var(--text-muted);">Error al cargar datos</td></tr>
                        <% } %>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- ══ SECCIÓN: MIS PAGOS ══ -->
        <div id="sec-pagos" class="section">
            <div class="panel">
                <div class="panel-title">Mis Pagos</div>
                <table style="width:100%;border-collapse:collapse;font-size:13px;">
                    <thead>
                        <tr style="border-bottom:1px solid var(--border);">
                            <th style="padding:10px 8px;text-align:left;color:var(--text-muted);font-weight:500;">Fecha pago</th>
                            <th style="padding:10px 8px;text-align:left;color:var(--text-muted);font-weight:500;">Medio de pago</th>
                            <th style="padding:10px 8px;text-align:right;color:var(--text-muted);font-weight:500;">Valor</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                        try {
                            Class.forName("com.mysql.cj.jdbc.Driver");
                            Connection conP = DriverManager.getConnection(
                                "jdbc:mysql://localhost:3307/Neins?useSSL=false&serverTimezone=America/Bogota",
                                "root", "");
                            Integer idUP = (Integer) session.getAttribute("id_usuario");
                            if (idUP != null) {
                                String sqlIdP = "SELECT c.id_cliente FROM clientes c " +
                                    "JOIN Usuarios u ON u.id_usuarios = c.id_usuario WHERE u.id_usuarios = ?";
                                PreparedStatement psPId = conP.prepareStatement(sqlIdP);
                                psPId.setInt(1, idUP);
                                ResultSet rsPId = psPId.executeQuery();
                                if (rsPId.next()) {
                                    int idCP = rsPId.getInt("id_cliente");
                                    String sqlP = "SELECT f.fecha_pago, f.valor, mp.descripcion_medio_pago FROM Fiado f " +
                                        "LEFT JOIN medio_pago mp ON f.id_medio_pago = mp.id_medio_pago " +
                                        "WHERE f.id_cliente = ? AND f.fecha_pago IS NOT NULL ORDER BY f.fecha_pago DESC";
                                    PreparedStatement psP = conP.prepareStatement(sqlP);
                                    psP.setInt(1, idCP);
                                    ResultSet rsP = psP.executeQuery();
                                    boolean hayP = false;
                                    while (rsP.next()) {
                                        hayP = true;
                                        java.sql.Date fPP = rsP.getDate("fecha_pago");
                                        double valP = rsP.getDouble("valor");
                                        String medioP = rsP.getString("descripcion_medio_pago");
                                        if (medioP == null) medioP = "—";
                        %>
                        <tr style="border-bottom:1px solid var(--border);">
                            <td style="padding:11px 8px;"><%= fPP %></td>
                            <td style="padding:11px 8px;color:var(--text-muted);"><%= medioP %></td>
                            <td style="padding:11px 8px;text-align:right;font-weight:600;color:var(--green);">-$<%= nf.format(valP) %></td>
                        </tr>
                        <%      }
                                rsP.close(); psP.close();
                                if (!hayP) { %>
                        <tr><td colspan="3" style="padding:24px;text-align:center;color:var(--text-muted);">No tienes pagos registrados</td></tr>
                        <%      }
                                }
                                rsPId.close(); psPId.close();
                            }
                            conP.close();
                        } catch (Exception ePe) { %>
                        <tr><td colspan="3" style="padding:24px;text-align:center;color:var(--text-muted);">Error al cargar datos</td></tr>
                        <% } %>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- ══ SECCIÓN: PRODUCTOS ══ -->
        <div id="sec-productos" class="section">
            <div class="panel">
                <div class="panel-title">Catálogo de Productos</div>
                <table style="width:100%;border-collapse:collapse;font-size:13px;">
                    <thead>
                        <tr style="border-bottom:1px solid var(--border);">
                            <th style="padding:10px 8px;text-align:left;color:var(--text-muted);font-weight:500;">#</th>
                            <th style="padding:10px 8px;text-align:left;color:var(--text-muted);font-weight:500;">Producto</th>
                            <th style="padding:10px 8px;text-align:right;color:var(--text-muted);font-weight:500;">Precio</th>
                            <th style="padding:10px 8px;text-align:center;color:var(--text-muted);font-weight:500;">Stock</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                        try {
                            Class.forName("com.mysql.cj.jdbc.Driver");
                            Connection conPr = DriverManager.getConnection(
                                "jdbc:mysql://localhost:3307/Neins?useSSL=false&serverTimezone=America/Bogota",
                                "root", "");
                            Statement stPr = conPr.createStatement();
                            ResultSet rsPr = stPr.executeQuery("SELECT * FROM Productos ORDER BY nombre");
                            int numPr = 1;
                            boolean hayPr = false;
                            while (rsPr.next()) {
                                hayPr = true;
                                int stockPr = rsPr.getInt("stock");
                        %>
                        <tr style="border-bottom:1px solid var(--border);">
                            <td style="padding:11px 8px;color:var(--text-muted);"><%= numPr++ %></td>
                            <td style="padding:11px 8px;font-weight:500;"><%= rsPr.getString("nombre") %></td>
                            <td style="padding:11px 8px;text-align:right;color:var(--gold);font-weight:600;">$<%= nf.format(rsPr.getDouble("precio")) %></td>
                            <td style="padding:11px 8px;text-align:center;">
                                <span style="padding:3px 10px;border-radius:20px;font-size:11px;font-weight:600;
                                    background:<%= stockPr > 0 ? "rgba(76,175,125,.15)" : "rgba(224,82,82,.15)" %>;
                                    color:<%= stockPr > 0 ? "var(--green)" : "var(--red)" %>">
                                    <%= stockPr > 0 ? stockPr + " uds" : "Agotado" %>
                                </span>
                            </td>
                        </tr>
                        <%  }
                            rsPr.close(); stPr.close(); conPr.close();
                            if (!hayPr) { %>
                        <tr><td colspan="4" style="padding:24px;text-align:center;color:var(--text-muted);">No hay productos disponibles</td></tr>
                        <% } } catch (Exception ePr) { %>
                        <tr><td colspan="4" style="padding:24px;text-align:center;color:var(--text-muted);">Error al cargar productos</td></tr>
                        <% } %>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- ══ SECCIÓN: NOTIFICACIONES ══ -->
        <div id="sec-notif" class="section">
            <div class="panel">
                <div class="panel-title">Notificaciones</div>
                <% if (tieneMoras) { %>
                <div style="background:rgba(224,82,82,.1);border:1px solid rgba(224,82,82,.3);border-radius:10px;padding:16px;color:var(--red);font-size:14px;margin-bottom:12px;">
                    ⚠️ Tienes fiados vencidos. Por favor contacta a tu distribuidor para ponerte al día.
                </div>
                <% } else { %>
                <div style="background:rgba(76,175,125,.1);border:1px solid rgba(76,175,125,.3);border-radius:10px;padding:16px;color:var(--green);font-size:14px;">
                    ✅ Todo en orden. No tienes notificaciones pendientes.
                </div>
                <% } %>
            </div>
        </div>

        <!-- ══ SECCIÓN: MI PERFIL ══ -->
        <div id="sec-perfil" class="section">
            <div class="panel" style="max-width:480px;">
                <div class="panel-title">Mi Perfil</div>
                <div style="display:flex;flex-direction:column;gap:14px;">
                    <div style="display:flex;flex-direction:column;gap:4px;">
                        <label style="font-size:11px;color:var(--text-muted);letter-spacing:1px;text-transform:uppercase;">Nombre</label>
                        <div style="background:var(--bg3);border:1px solid var(--border);border-radius:8px;padding:11px 14px;font-size:14px;"><%= nombreCliente %></div>
                    </div>
                    <div style="display:flex;flex-direction:column;gap:4px;">
                        <label style="font-size:11px;color:var(--text-muted);letter-spacing:1px;text-transform:uppercase;">Correo</label>
                        <div style="background:var(--bg3);border:1px solid var(--border);border-radius:8px;padding:11px 14px;font-size:14px;"><%= session.getAttribute("correo") != null ? session.getAttribute("correo") : "—" %></div>
                    </div>
                    <div style="display:flex;flex-direction:column;gap:4px;">
                        <label style="font-size:11px;color:var(--text-muted);letter-spacing:1px;text-transform:uppercase;">Rol</label>
                        <div style="background:var(--bg3);border:1px solid var(--border);border-radius:8px;padding:11px 14px;font-size:14px;color:var(--gold);">Cliente</div>
                    </div>
                </div>
            </div>
        </div>

    </div><!-- /content -->
</div><!-- /main -->

<script>
    function showSection(name, clickedEl) {
        // Ocultar todas las secciones
        document.querySelectorAll('.section').forEach(s => s.classList.remove('active'));
        // Mostrar la sección pedida
        const el = document.getElementById('sec-' + name);
        if (el) el.classList.add('active');

        // Actualizar nav: quitar active de todos y ponerlo en el que se clickeó
        document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
        if (clickedEl) clickedEl.classList.add('active');
    }
</script>

    <script src="../Scripts/premium-ui.js"></script>
</body>
</html>



