USE Neins;

-- Ejecuta este archivo una sola vez en la base que ya usa tu aplicación.
-- Los precios están en pesos colombianos y pueden modificarse desde Productos.
INSERT INTO Productos (nombre, precio, stock, stock_minimo, id_categoria)
SELECT 'Cerveza Aguila Lata 330ml', 4500.00, 48, 12, 2
WHERE NOT EXISTS (SELECT 1 FROM Productos WHERE nombre='Cerveza Aguila Lata 330ml');
INSERT INTO Productos (nombre, precio, stock, stock_minimo, id_categoria)
SELECT 'Cerveza Aguila Six Pack', 21000.00, 18, 6, 2
WHERE NOT EXISTS (SELECT 1 FROM Productos WHERE nombre='Cerveza Aguila Six Pack');
INSERT INTO Productos (nombre, precio, stock, stock_minimo, id_categoria)
SELECT 'Coronita Extra 210ml', 11000.00, 24, 6, 2
WHERE NOT EXISTS (SELECT 1 FROM Productos WHERE nombre='Coronita Extra 210ml');
INSERT INTO Productos (nombre, precio, stock, stock_minimo, id_categoria)
SELECT 'Corona Extra Six Pack', 55000.00, 10, 4, 2
WHERE NOT EXISTS (SELECT 1 FROM Productos WHERE nombre='Corona Extra Six Pack');
INSERT INTO Productos (nombre, precio, stock, stock_minimo, id_categoria)
SELECT 'Cerveza Poker Lata 330ml', 4000.00, 48, 12, 2
WHERE NOT EXISTS (SELECT 1 FROM Productos WHERE nombre='Cerveza Poker Lata 330ml');
INSERT INTO Productos (nombre, precio, stock, stock_minimo, id_categoria)
SELECT 'Cerveza Poker x6', 20000.00, 20, 6, 2
WHERE NOT EXISTS (SELECT 1 FROM Productos WHERE nombre='Cerveza Poker x6');
INSERT INTO Productos (nombre, precio, stock, stock_minimo, id_categoria)
SELECT 'Buchanan''s Master 750ml', 260000.00, 6, 2, 1
WHERE NOT EXISTS (SELECT 1 FROM Productos WHERE nombre='Buchanan''s Master 750ml');
INSERT INTO Productos (nombre, precio, stock, stock_minimo, id_categoria)
SELECT 'Aguardiente Rosado 750ml', 32000.00, 12, 4, 4
WHERE NOT EXISTS (SELECT 1 FROM Productos WHERE nombre='Aguardiente Rosado 750ml');
INSERT INTO Productos (nombre, precio, stock, stock_minimo, id_categoria)
SELECT 'Aguardiente Nectar Club 750ml', 37000.00, 10, 4, 4
WHERE NOT EXISTS (SELECT 1 FROM Productos WHERE nombre='Aguardiente Nectar Club 750ml');
INSERT INTO Productos (nombre, precio, stock, stock_minimo, id_categoria)
SELECT 'Jose Cuervo Especial 375ml', 55000.00, 8, 3, 6
WHERE NOT EXISTS (SELECT 1 FROM Productos WHERE nombre='Jose Cuervo Especial 375ml');
INSERT INTO Productos (nombre, precio, stock, stock_minimo, id_categoria)
SELECT 'Tequila Don Julio 70 700ml', 350000.00, 4, 2, 6
WHERE NOT EXISTS (SELECT 1 FROM Productos WHERE nombre='Tequila Don Julio 70 700ml');
INSERT INTO Productos (nombre, precio, stock, stock_minimo, id_categoria)
SELECT 'Ron Viejo de Caldas 750ml', 50000.00, 12, 4, 5
WHERE NOT EXISTS (SELECT 1 FROM Productos WHERE nombre='Ron Viejo de Caldas 750ml');
