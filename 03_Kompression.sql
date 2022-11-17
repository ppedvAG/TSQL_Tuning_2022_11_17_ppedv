--Kompression
--für Client komplett transparent (bei SELECT wird dekomprimiert, User sieht nichts)
--Tabellen -> Zeilen- und Seitenkompression
--40%-60% Platzersparnis

USE Demo;

--Große Tabelle erzeugen
SELECT  c.CustomerID
		, c.CompanyName
		, c.ContactName
		, c.ContactTitle
		, c.City
		, c.Country
		, o.EmployeeID
		, o.OrderDate
		, o.freight
		, o.shipcity
		, o.shipcountry
		, o.OrderID
		, od.ProductID
		, od.UnitPrice
		, od.Quantity
		, p.ProductName
		, e.LastName
		, e.FirstName
		, e.birthdate
into dbo.KundenUmsatz
FROM	Northwind.dbo.Customers c
		INNER JOIN Northwind.dbo.Orders o ON c.CustomerID = o.CustomerID
		INNER JOIN Northwind.dbo.Employees e ON o.EmployeeID = e.EmployeeID
		INNER JOIN Northwind.dbo.[Order Details] od ON o.orderid = od.orderid
		INNER JOIN Northwind.dbo.Products p ON od.productid = p.productid

INSERT INTO KundenUmsatz
SELECT * FROM KundenUmsatz
GO 9 --Viele Daten erzeugen

SELECT COUNT(*) FROM KundenUmsatz;

SET STATISTICS time, io ON;
SELECT * FROM KundenUmsatz;
--2.6s CPU, 20,4s Gesamt
--41334 Reads

--Kompression:
--Row: 322MB -> 179MB (45%)
--Page: 322MB -> 85MB (75%)

SELECT * FROM KundenUmsatz;
--Row-Compression
--3.3s, 20.6s Gesamt
--22868 Reads

SELECT * FROM KundenUmsatz;
--Page-Compression
--4.6s, 20.6s Gesamt
--10714 Reads

--Bestimmte Partition komprimieren
ALTER TABLE pTable REBUILD PARTITION = 1 WITH(DATA_COMPRESSION = ROW);

SELECT count(*)*8/1024 AS 'Data Cache Size(MB)', db_name(database_id)
FROM sys.dm_os_buffer_descriptors
GROUP BY db_name(database_id) ,database_id
ORDER BY 'Data Cache Size(MB)' DESC