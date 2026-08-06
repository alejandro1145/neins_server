<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="Controlador.Conexion" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.NumberFormat" %>
<%@ page import="java.time.LocalDate" %>
<%@ page import="java.time.temporal.ChronoUnit" %>
<%!
    static String h(String value) {
        if (value == null) return "";
        return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }
    static String money(NumberFormat nf, double value) {
        return "$" + nf.format(Math.round(value));
    }
    static String initials(String name) {
        if (name == null || name.trim().isEmpty()) return "CL";
        String[] parts = name.trim().split("\\s+");
        String first = parts[0].substring(0, 1);
        String second = parts.length > 1 ? parts[1].substring(0, 1) : "";
        return (first + second).toUpperCase();
    }
%>
<%
    if (session.getAttribute("usuario") == null) {
        response.sendRedirect(request.getContextPath() + "/Vista/Login.jsp");
        return;
    }
    String rol = (String) session.getAttribute("rol");
    if ("administrador".equalsIgnoreCase(rol)) {
        response.sendRedirect(request.getContextPath() + "/Vista/MenuAdmin.jsp");
        return;
    }

    NumberFormat nf = NumberFormat.getIntegerInstance(new Locale("es", "CO"));
    String ctx = request.getContextPath();
    int idUsuario = session.getAttribute("id_usuario") instanceof Integer ? (Integer) session.getAttribute("id_usuario") : -1;
    String nombreCliente = String.valueOf(session.getAttribute("usuario") != null ? session.getAttribute("usuario") : "Cliente");
    String correoCliente = String.valueOf(session.getAttribute("correo") != null ? session.getAttribute("correo") : "");
    String telefonoCliente = "";
    String fotoPerfil = "";
    int idCliente = -1;
    // El cupo siempre lo aprueba el administrador: un cliente nuevo inicia en $0.
    double cupoTotal = 0;
    double totalDeuda = 0;
    double totalComprado = 0;
    int comprasRealizadas = 0;
    int pagosRealizados = 0;
    int productosFavoritos = 0;
    boolean tieneMoras = false;
    String miembroDesde = "12 Ene 2024";
    String ultimaCompraNombre = "Sin compras registradas";
    String ultimaCompraFecha = "";
    double ultimaCompraValor = 0;
    List<Map<String, String>> productos = new ArrayList<>();
    List<Map<String, String>> fiados = new ArrayList<>();
    List<Map<String, String>> pagos = new ArrayList<>();
    List<Map<String, String>> actividad = new ArrayList<>();
    List<Map<String, String>> alertas = new ArrayList<>();

    Connection con = null;
    try {
        con = new Conexion().getConnection();
        PreparedStatement psU = con.prepareStatement(
            "SELECT u.nombre, u.apellidos, u.correo, u.telefono, u.foto_perfil, DATE(u.fecha_acepto_terminos) AS fecha_alta, c.id_cliente, c.cupo_credito " +
            "FROM Usuarios u LEFT JOIN clientes c ON c.id_usuario = u.id_usuarios WHERE u.id_usuarios = ?");
        psU.setInt(1, idUsuario);
        ResultSet rsU = psU.executeQuery();
        if (rsU.next()) {
            nombreCliente = (rsU.getString("nombre") + " " + rsU.getString("apellidos")).trim();
            correoCliente = rsU.getString("correo") != null ? rsU.getString("correo") : correoCliente;
            telefonoCliente = rsU.getString("telefono") != null ? rsU.getString("telefono") : "";
            fotoPerfil = rsU.getString("foto_perfil") != null ? rsU.getString("foto_perfil") : "";
            idCliente = rsU.getInt("id_cliente");
            if (rsU.wasNull()) idCliente = -1;
            cupoTotal = rsU.getDouble("cupo_credito");
            java.sql.Date alta = rsU.getDate("fecha_alta");
            if (alta != null) miembroDesde = new java.text.SimpleDateFormat("dd MMM yyyy", new Locale("es", "CO")).format(alta);
            session.setAttribute("usuario", nombreCliente);
            session.setAttribute("nombre", nombreCliente);
            session.setAttribute("correo", correoCliente);
        }
        rsU.close(); psU.close();

        if (idCliente > 0) {
            PreparedStatement psS = con.prepareStatement(
                "SELECT COALESCE(SUM(saldo_pendiente),0) deuda, COUNT(*) compras, COALESCE(SUM(valor),0) comprado, " +
                "SUM(CASE WHEN saldo_pendiente > 0 AND fecha_limite_pago < CURDATE() THEN 1 ELSE 0 END) moras " +
                "FROM Fiado WHERE id_cliente = ?");
            psS.setInt(1, idCliente);
            ResultSet rsS = psS.executeQuery();
            if (rsS.next()) {
                totalDeuda = rsS.getDouble("deuda");
                comprasRealizadas = rsS.getInt("compras");
                totalComprado = rsS.getDouble("comprado");
                tieneMoras = rsS.getInt("moras") > 0;
            }
            rsS.close(); psS.close();

            PreparedStatement psPagoCount = con.prepareStatement("SELECT COUNT(*) FROM Pagos WHERE id_cliente = ?");
            psPagoCount.setInt(1, idCliente);
            ResultSet rsPagoCount = psPagoCount.executeQuery();
            if (rsPagoCount.next()) pagosRealizados = rsPagoCount.getInt(1);
            rsPagoCount.close(); psPagoCount.close();

            PreparedStatement psF = con.prepareStatement(
                "SELECT fecha_fiado, fecha_limite_pago, valor, saldo_pendiente, estado FROM Fiado WHERE id_cliente = ? ORDER BY fecha_fiado DESC LIMIT 20");
            psF.setInt(1, idCliente);
            ResultSet rsF = psF.executeQuery();
            while (rsF.next()) {
                Map<String, String> row = new HashMap<>();
                row.put("fecha", String.valueOf(rsF.getDate("fecha_fiado")));
                row.put("limite", String.valueOf(rsF.getDate("fecha_limite_pago")));
                row.put("valor", money(nf, rsF.getDouble("saldo_pendiente") > 0 ? rsF.getDouble("saldo_pendiente") : rsF.getDouble("valor")));
                boolean vencido = rsF.getDouble("saldo_pendiente") > 0 && rsF.getDate("fecha_limite_pago") != null && rsF.getDate("fecha_limite_pago").before(new java.util.Date());
                row.put("estado", rsF.getDouble("saldo_pendiente") <= 0 ? "Pagado" : vencido ? "Vencido" : "Pendiente");
                fiados.add(row);
            }
            rsF.close(); psF.close();

            PreparedStatement psP = con.prepareStatement(
                "SELECT p.fecha_pago, p.monto, COALESCE(mp.descripcion_medio_pago, 'Sin medio') medio FROM Pagos p " +
                "LEFT JOIN medio_pago mp ON mp.id_medio_pago = p.id_medio_pago WHERE p.id_cliente = ? ORDER BY p.fecha_pago DESC LIMIT 20");
            psP.setInt(1, idCliente);
            ResultSet rsP = psP.executeQuery();
            while (rsP.next()) {
                Map<String, String> row = new HashMap<>();
                row.put("fecha", String.valueOf(rsP.getDate("fecha_pago")));
                row.put("medio", rsP.getString("medio"));
                row.put("valor", money(nf, rsP.getDouble("monto")));
                pagos.add(row);
            }
            rsP.close(); psP.close();

            PreparedStatement psLast = con.prepareStatement(
                "SELECT f.fecha_fiado, f.valor, COALESCE(MIN(p.nombre), 'Compra a crédito') producto " +
                "FROM Fiado f LEFT JOIN Detalle_Fiado df ON df.id_fiado = f.id_fiado " +
                "LEFT JOIN Productos p ON p.id_productos = df.id_productos WHERE f.id_cliente = ? " +
                "GROUP BY f.id_fiado, f.fecha_fiado, f.valor ORDER BY f.fecha_fiado DESC LIMIT 1");
            psLast.setInt(1, idCliente);
            ResultSet rsLast = psLast.executeQuery();
            if (rsLast.next()) {
                ultimaCompraNombre = rsLast.getString("producto");
                ultimaCompraFecha = String.valueOf(rsLast.getDate("fecha_fiado"));
                ultimaCompraValor = rsLast.getDouble("valor");
            }
            rsLast.close(); psLast.close();

            PreparedStatement psAlertas = con.prepareStatement(
                "SELECT tipo, descripcion, fecha_alerta, leida FROM Alertas WHERE id_usuarios_destino = ? ORDER BY fecha_alerta DESC LIMIT 10");
            psAlertas.setInt(1, idUsuario);
            ResultSet rsAlertas = psAlertas.executeQuery();
            while (rsAlertas.next()) {
                Map<String, String> alerta = new HashMap<>();
                alerta.put("tipo", rsAlertas.getString("tipo"));
                alerta.put("descripcion", rsAlertas.getString("descripcion"));
                alerta.put("fecha", String.valueOf(rsAlertas.getTimestamp("fecha_alerta")));
                alerta.put("leida", String.valueOf(rsAlertas.getBoolean("leida")));
                alertas.add(alerta);
            }
            rsAlertas.close(); psAlertas.close();
        }

        Statement st = con.createStatement();
        ResultSet rsProd = st.executeQuery("SELECT id_productos, nombre, precio, stock FROM Productos WHERE estado = 1 ORDER BY nombre");
        while (rsProd.next()) {
            Map<String, String> p = new HashMap<>();
            p.put("id", String.valueOf(rsProd.getInt("id_productos")));
            p.put("nombre", rsProd.getString("nombre"));
            p.put("precio", String.valueOf(rsProd.getDouble("precio")));
            p.put("precioFmt", money(nf, rsProd.getDouble("precio")));
            p.put("stock", String.valueOf(rsProd.getInt("stock")));
            productos.add(p);
        }
        rsProd.close(); st.close();
    } catch (Exception e) {
        request.setAttribute("panelError", "No se pudo conectar a la base de datos. Revisa MySQL y el archivo SQL.");
    } finally {
        try { if (con != null) con.close(); } catch (Exception ignored) {}
    }

    double cupoDisponible = Math.max(cupoTotal - totalDeuda, 0);
    int porcentajeUso = cupoTotal > 0 ? (int)Math.round((totalDeuda / cupoTotal) * 100) : 0;
    String estadoCuenta = tieneMoras ? "Con mora" : "Al día";
    String active = request.getParameter("section") != null ? request.getParameter("section") : "resumen";
    if (!Arrays.asList("resumen", "fiados", "pagos", "productos", "notificaciones", "perfil").contains(active)) active = "resumen";
    String compra = request.getParameter("compra") != null ? request.getParameter("compra") : "";
    String perfil = request.getParameter("perfil") != null ? request.getParameter("perfil") : "";
    int notificaciones = tieneMoras ? 1 : 0;
    for (Map<String, String> alerta : alertas) if (!"true".equals(alerta.get("leida"))) notificaciones++;
    String primerNombre = nombreCliente.split("\\s+").length > 0 ? nombreCliente.split("\\s+")[0] : "Cliente";
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Una Pa' La Sed - Cartera Digital</title>
    <link rel="stylesheet" href="../Estilos/global.css">
</head>
<body class="client-shell" data-section="<%= h(active) %>">
<aside class="client-sidebar">
    <a class="brand-block" href="#" data-section-target="resumen" aria-label="Ir al resumen">
        <span class="brand-mark"></span>
        <strong>UNA PA' LA SED</strong>
        <small>CARTERA DIGITAL</small>
    </a>
    <nav class="client-nav" aria-label="Navegación cliente">
        <button type="button" class="nav-action" data-section-target="resumen">▦ <span>Mi resumen</span></button>
        <button type="button" class="nav-action" data-section-target="fiados">▤ <span>Mis fiados</span></button>
        <button type="button" class="nav-action" data-section-target="pagos">▭ <span>Mis pagos</span></button>
        <button type="button" class="nav-action" data-section-target="productos">▰ <span>Productos</span></button>
        <button type="button" class="nav-action" data-section-target="notificaciones">⌂ <span>Notificaciones</span><b><%= notificaciones %></b></button>
        <button type="button" class="nav-action" data-section-target="perfil">♙ <span>Mi perfil</span></button>
    </nav>
    <a class="logout-action" href="<%= ctx %>/LogoutServlet">↪ Cerrar sesión</a>
    <div class="sidebar-promo">
        <img src="../Imagenes/promo-premium.jpg" alt="Selección de licores premium">
        <div class="sidebar-promo-copy">
            <strong>Selección Premium</strong>
            <span>Los mejores licores para brindar como se debe</span>
        </div>
    </div>
</aside>

<main class="client-main">
    <header class="client-topbar">
        <div>
            <h1>Hola, <%= h(nombreCliente) %> <span>👋</span></h1>
            <p>Bienvenido a tu cartera digital</p>
        </div>
        <button type="button" class="notify-pill" data-section-target="notificaciones">♢ Notificaciones <b><%= notificaciones %></b></button>
    </header>

    <% if (request.getAttribute("panelError") != null) { %>
        <div class="notice error"><%= h(String.valueOf(request.getAttribute("panelError"))) %></div>
    <% } %>
    <% if ("ok".equals(compra)) { %><div class="notice ok">Compra registrada como fiado. Inventario y deuda actualizados.</div><% } %>
    <% if ("error".equals(compra)) { %><div class="notice error">No se pudo confirmar la compra. Revisa stock disponible.</div><% } %>
    <% if ("cupo".equals(compra)) { %><div class="notice error">No tienes cupo disponible suficiente. Solicita al administrador la aprobación o ajuste de tu crédito.</div><% } %>
    <% if ("carrito".equals(compra)) { %><div class="notice error">Agrega al menos un producto antes de confirmar.</div><% } %>
    <% if ("ok".equals(perfil)) { %><div class="notice ok">Perfil actualizado correctamente.</div><% } %>
    <% if ("error".equals(perfil)) { %><div class="notice error">No se pudo actualizar el perfil.</div><% } %>

    <section id="section-resumen" class="client-section">
        <div class="summary-grid">
            <article class="hero-card">
                <p>Total que debes</p>
                <strong><%= money(nf, totalDeuda) %></strong>
                <span>Estado: <b><%= estadoCuenta %></b> <i>✓</i></span>
                <em><%= tieneMoras ? "Tienes facturas pendientes" : "No tienes facturas pendientes" %></em>
                <button type="button" data-section-target="fiados">Ver detalle →</button>
            </article>
            <article class="metric-card purple"><span>▣</span><p>Disponible para fiar</p><strong><%= money(nf, cupoDisponible) %></strong><small>de tu límite total</small><button type="button" data-section-target="productos">Ver detalle →</button></article>
            <article class="metric-card blue"><span>⬡</span><p>Límite total de crédito</p><strong><%= money(nf, cupoTotal) %></strong><small>Tu cupo aprobado</small><button type="button" data-section-target="perfil">Ver detalle →</button></article>
            <article class="metric-card green"><span>▣</span><p>Estado de cuenta</p><strong><%= estadoCuenta %> ✓</strong><small><%= tieneMoras ? "Requiere pago" : "Sin mora" %></small></article>
        </div>
        <div class="content-grid">
            <article class="wide-panel credit-panel">
                <h2>Uso de tu crédito</h2>
                <div class="credit-body">
                    <div class="donut" style="--value:<%= porcentajeUso %>"><strong><%= porcentajeUso %>%</strong><small>utilizado</small></div>
                    <div>
                        <h3><%= porcentajeUso < 40 ? "¡Excelente!" : porcentajeUso < 80 ? "Vas bien" : "Atención" %></h3>
                        <p>Tienes <%= porcentajeUso < 40 ? "un excelente manejo" : "actividad registrada" %> de tu crédito.</p>
                        <dl><div><dt>Límite total</dt><dd><%= money(nf, cupoTotal) %></dd></div><div><dt>Utilizado</dt><dd><%= money(nf, totalDeuda) %></dd></div><div><dt>Disponible</dt><dd><%= money(nf, cupoDisponible) %></dd></div></dl>
                    </div>
                </div>
            </article>
            <article class="wide-panel empty-panel">
                <h2>Actividad reciente</h2>
                <% if (fiados.isEmpty() && pagos.isEmpty()) { %>
                    <div class="empty-state"><span>▤✓</span><h3>No tienes movimientos recientes</h3><p>Tus compras y pagos aparecerán aquí.</p></div>
                <% } else { %>
                    <div class="mini-list">
                        <% for (int i = 0; i < Math.min(4, fiados.size()); i++) { Map<String, String> f = fiados.get(i); %>
                            <button type="button" data-section-target="fiados"><span>Fiado <%= h(f.get("fecha")) %></span><b><%= h(f.get("valor")) %></b></button>
                        <% } %>
                        <% for (int i = 0; i < Math.min(2, pagos.size()); i++) { Map<String, String> p = pagos.get(i); %>
                            <button type="button" data-section-target="pagos"><span>Pago <%= h(p.get("fecha")) %></span><b>-<%= h(p.get("valor")) %></b></button>
                        <% } %>
                    </div>
                <% } %>
            </article>
        </div>
        <h2 class="section-caption">Recomendaciones para ti</h2>
        <div class="recommend-grid">
            <button type="button" data-section-target="productos"><span>▢</span><b>Explora nuestro catálogo</b><small>Descubre nuevos productos y ofertas.</small><em>Ver catálogo →</em></button>
            <button type="button" data-section-target="productos" data-filter-favorites="true"><span>★</span><b>Consulta tus productos favoritos</b><small>Encuéntralos fácilmente.</small><em>Ver favoritos →</em></button>
            <button type="button" data-section-target="pagos"><span>◷</span><b>Revisa tu historial</b><small>Consulta tus compras y pagos anteriores.</small><em>Ver historial →</em></button>
        </div>
    </section>

    <section id="section-fiados" class="client-section">
        <div class="stack-panels">
            <article class="wide-panel">
                <h2>MIS FIADOS</h2>
                <% if (fiados.isEmpty()) { %>
                    <div class="empty-state tall"><span>▤✓</span><h3>¡Estás al día!</h3><p>No tienes fiados registrados en este momento.</p><button type="button" data-section-target="productos">▢ Ir al catálogo de productos →</button></div>
                <% } else { %>
                    <table><thead><tr><th>Fecha</th><th>Límite pago</th><th>Valor</th><th>Estado</th></tr></thead><tbody>
                    <% for (Map<String, String> f : fiados) { %><tr><td><%= h(f.get("fecha")) %></td><td><%= h(f.get("limite")) %></td><td><%= h(f.get("valor")) %></td><td><span class="status <%= "Vencido".equals(f.get("estado")) ? "bad" : "ok" %>"><%= h(f.get("estado")) %></span></td></tr><% } %>
                    </tbody></table>
                <% } %>
            </article>
        </div>
    </section>

    <section id="section-pagos" class="client-section">
        <div class="stack-panels">
            <article class="wide-panel">
                <h2>MIS PAGOS</h2>
                <% if (pagos.isEmpty()) { %>
                    <div class="empty-state tall"><span>▣✓</span><h3>¡Todo en orden!</h3><p>No tienes pagos registrados en este momento.</p><small>Cuando realices un pago, aparecerá aquí tu historial.</small></div>
                <% } else { %>
                    <table><thead><tr><th>Fecha pago</th><th>Medio</th><th>Valor</th></tr></thead><tbody>
                    <% for (Map<String, String> p : pagos) { %><tr><td><%= h(p.get("fecha")) %></td><td><%= h(p.get("medio")) %></td><td class="paid">-<%= h(p.get("valor")) %></td></tr><% } %>
                    </tbody></table>
                <% } %>
            </article>
        </div>
    </section>

    <section id="section-productos" class="client-section">
        <div class="shop-grid">
            <article class="catalog-panel wide-panel">
                <h2>CATÁLOGO DE PRODUCTOS</h2>
                <div class="catalog-tools">
                    <label><span>⌕</span><input id="productSearch" type="search" placeholder="Buscar productos, marcas o categorías..."></label>
                    <select id="stockFilter" aria-label="Filtrar productos"><option value="all">Filtrar</option><option value="available">Disponibles</option><option value="low">Poco stock</option><option value="favorites">Favoritos</option></select>
                </div>
                <div class="product-grid">
                    <% for (Map<String, String> p : productos) {
                        int stock = Integer.parseInt(p.get("stock"));
                        String nombre = p.get("nombre");
                    %>
                    <article class="product-card" data-name="<%= h(nombre.toLowerCase()) %>" data-stock="<%= stock %>" data-id="<%= h(p.get("id")) %>">
                        <button type="button" class="favorite-btn" aria-label="Marcar favorito">♡</button>
                        <% String nombreLower = nombre.toLowerCase();
                           String fotoProducto = nombreLower.contains("aguila lata") || nombreLower.contains("águila lata") ? "catalog-aguila-lata.png"
                                : nombreLower.contains("aguila") || nombreLower.contains("águila") ? "catalog-aguila-six.png"
                                : nombreLower.contains("corona x6") || nombreLower.contains("corona extra") ? "catalog-corona-six.png"
                                : nombreLower.contains("coronita") ? "catalog-coronita.png"
                                : nombreLower.contains("poker x24") ? "catalog-poker-x24.png"
                                : nombreLower.contains("poker x6") ? "catalog-poker-six.png"
                                : nombreLower.contains("poker") ? "catalog-poker-lata.png"
                                : nombreLower.contains("buchanan") ? "catalog-buchanans.png"
                                : nombreLower.contains("don julio") ? "catalog-don-julio.png"
                                : nombreLower.contains("jose cuervo") || nombreLower.contains("josé cuervo") ? "catalog-jose-cuervo.png"
                                : nombreLower.contains("nectar") || nombreLower.contains("néctar") ? "catalog-nectar.png"
                                : nombreLower.contains("caldas") ? "catalog-caldas.png"
                                : nombreLower.contains("rosado") ? "catalog-rosado.png"
                                : nombreLower.contains("aguardiente") ? "catalog-aguardiente.png"
                                : nombreLower.contains("medellin") || nombreLower.contains("medellín") ? "catalog-ron-medellin.png"
                                : nombreLower.contains("vino") ? "catalog-vino.png"
                                : (nombreLower.contains("whisky") || nombreLower.contains("whiskey") || nombreLower.contains("johnnie") || nombreLower.contains("walker")) ? "catalog-whisky.png"
                                : null;
                           String iconoProducto = nombreLower.contains("cerveza") ? "🍺" : nombreLower.contains("vino") ? "🍷" : nombreLower.contains("ron") || nombreLower.contains("whisky") ? "🥃" : nombreLower.contains("aguardiente") ? "🍾" : "🥂";
                        %>
                        <% if (fotoProducto != null) { %>
                        <div class="bottle-art has-photo"><img class="product-photo" src="../Imagenes/productos/<%= fotoProducto %>" alt="<%= h(nombre) %>"></div>
                        <% } else { %>
                        <div class="bottle-art" aria-label="Imagen genérica de <%= h(nombre) %>"><span><%= iconoProducto %></span></div>
                        <% } %>
                        <h3><%= h(nombre) %></h3>
                        <strong><%= h(p.get("precioFmt")) %></strong>
                        <p>Disponibles: <b><%= stock %> uds</b></p>
                        <button type="button" class="add-cart-btn" data-id="<%= h(p.get("id")) %>" data-name="<%= h(nombre) %>" data-price="<%= h(p.get("precio")) %>" data-stock="<%= stock %>" <%= stock <= 0 ? "disabled" : "" %>>+ Agregar</button>
                    </article>
                    <% } %>
                </div>
                <% if (productos.isEmpty()) { %><div class="empty-state"><span>▢</span><h3>No hay productos disponibles</h3><p>Cuando el admin registre productos aparecerán aquí.</p></div><% } %>
            </article>
            <form class="cart-panel" id="cartForm" method="post" action="<%= ctx %>/ClienteCompraServlet">
                <input type="hidden" name="section" value="productos">
                <header><h2>🛒 MI CARRITO</h2><button type="button" id="clearCart" aria-label="Vaciar carrito">⌄</button></header>
                <div class="cart-list" id="cartList"><div class="empty-cart"><span>🛒</span><h3>Tu carrito está vacío</h3><p>Agrega productos para ver tu resumen de compra.</p></div></div>
                <div id="cartHidden"></div>
                <div class="cart-total"><span>Total</span><strong id="cartTotal">$0</strong></div>
                <button class="checkout-btn" id="checkoutBtn" type="submit" disabled>▣ Confirmar compra</button>
                <small>♧ Compra 100% segura</small>
            </form>
        </div>
    </section>

    <section id="section-notificaciones" class="client-section">
        <article class="wide-panel">
            <h2>NOTIFICACIONES</h2>
            <% if (tieneMoras) { %>
                <div class="notification-card danger"><b>Tienes fiados vencidos</b><p>Revisa la sección Mis fiados y ponte al día con tu distribuidor.</p><button type="button" data-section-target="fiados">Ver fiados →</button></div>
            <% } %>
            <% if (!alertas.isEmpty()) { for (Map<String, String> alerta : alertas) { %>
                <div class="notification-card"><b><%= "nuevo_fiado".equals(alerta.get("tipo")) ? "Fiado registrado" : h(alerta.get("tipo")) %></b><p><%= h(alerta.get("descripcion")) %></p><small><%= h(alerta.get("fecha")) %></small></div>
            <% } } else if (!tieneMoras) { %>
                <div class="empty-state tall"><span>✓</span><h3>Todo en orden</h3><p>No tienes notificaciones pendientes.</p><button type="button" data-section-target="productos">Explorar productos →</button></div>
            <% } %>
        </article>
    </section>

    <section id="section-perfil" class="client-section">
        <article class="profile-panel wide-panel">
            <div class="profile-left">
                <h2>MI PERFIL</h2>
                <p>Administra tu información personal y consulta tu actividad.</p>
                <form method="post" action="<%= ctx %>/PerfilClienteServlet" enctype="multipart/form-data" class="profile-form">
                    <div class="avatar-wrap">
                        <div class="avatar-preview" id="avatarPreview" <%= !fotoPerfil.isEmpty() ? "style=\"background-image:url('" + h(fotoPerfil) + "')\"" : "" %>><%= fotoPerfil.isEmpty() ? h(initials(nombreCliente)) : "" %></div>
                        <label class="outline-btn">Cambiar foto<input id="avatarInput" name="foto" type="file" accept="image/png,image/jpeg"></label>
                        <small>JPG o PNG. Máx 2MB</small>
                    </div>
                    <label>NOMBRE <input name="nombre" value="<%= h(nombreCliente) %>" required></label>
                    <label>CORREO ELECTRÓNICO <input type="email" name="correo" value="<%= h(correoCliente) %>" required></label>
                    <label>TELÉFONO <input name="telefono" value="<%= h(telefonoCliente) %>" required></label>
                    <label>ROL <input value="Cliente" disabled></label>
                    <button type="submit" class="save-btn">Guardar cambios</button>
                </form>
                <div class="security-box"><span>⬡</span><div><b>Tu seguridad es importante</b><p>Actualiza tus datos o cambia tu contraseña desde el centro de seguridad.</p></div><a href="<%= ctx %>/Vista/CambiarClave.jsp">Ir a seguridad →</a></div>
            </div>
            <div class="profile-right">
                <h2>RESUMEN DE TU CUENTA</h2>
                <div class="account-row"><div><small>MIEMBRO DESDE</small><b><%= h(miembroDesde) %></b></div><div><small>ESTADO DE CUENTA</small><b><%= h(estadoCuenta) %> ✓</b><p><%= tieneMoras ? "Con facturas pendientes" : "Sin facturas pendientes" %></p></div></div>
                <h2>TUS ESTADÍSTICAS</h2>
                <div class="stats-boxes">
                    <div><span>▢</span><small>COMPRAS REALIZADAS</small><b><%= comprasRealizadas %></b><p>Total de compras</p></div>
                    <div><span>◉</span><small>TOTAL COMPRADO</small><b><%= money(nf, totalComprado) %></b><p>Valor acumulado</p></div>
                    <div><span>▤</span><small>PAGOS REALIZADOS</small><b><%= pagosRealizados %></b><p>Total de pagos</p></div>
                    <div><span>☆</span><small>PRODUCTOS FAVORITOS</small><b id="favProfileCount"><%= productosFavoritos %></b><p>Productos guardados</p></div>
                </div>
                <h2>ÚLTIMA COMPRA</h2>
                <div class="last-buy"><div class="mini-bottle"></div><div><b><%= h(ultimaCompraNombre) %></b><p><%= ultimaCompraValor > 0 ? money(nf, ultimaCompraValor) + " · " + h(ultimaCompraFecha) : "Sin historial todavía" %></p></div><button type="button" data-section-target="fiados">Ver historial →</button></div>
            </div>
        </article>
    </section>

    <footer>© 2026 Una Pa' La Sed. Todos los derechos reservados.</footer>
</main>
<script src="../Scripts/premium-ui.js"></script>
</body>
</html>
