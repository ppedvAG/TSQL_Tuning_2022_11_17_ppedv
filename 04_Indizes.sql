USE Demo;

SELECT * FROM KundenUmsatz; --Table Scan da kein Index vorhanden

/*
Heap: Tabelle in unsortierer Form (alle Daten)

Non-Clustered Index (NCIX):
Baumstruktur (von oben nach unten)
Maximal 1000 Stück pro Tabelle
Sollte auf Spalten verwendet werden die oft mit WHERE gesucht werden

Clustered Index (CIX):
Maximal 1 pro Tabelle
Am besten auf ID Spalte
Wird immer automatisch sortiert, bei INSERT wird der Datensatz automatisch an der richtigen Stelle eingefügt
Sollte vermieden werden auf Tabellen mit hohem IO -> viele Sortierungen

Table Scan: Suche die ganze Tabelle
Index Scan: Durchsuche den ganzen Index
Index Seek: bestimmte Daten suchen (beste)
*/

USE Northwind;

--Clustered Index
SELECT * FROM Orders; --Clustered Index Scan (Kosten: 0.0182)
SELECT * FROM Orders WHERE OrderID = 10248; --Clustered Index Seek (Kosten: 0.0032)
INSERT INTO Customers (CustomerID, CompanyName) VALUES ('PPEDV', 'PPEDV'); --Clustered Index Insert (Kosten: 0.05 da Sortierung)

SET STATISTICS time, io ON;

USE Demo;

SELECT * INTO KundenUmsatz2 FROM KundenUmsatz;

ALTER TABLE KundenUmsatz2 ADD ID int identity;

SELECT * FROM KundenUmsatz2 WHERE ID = 30; --Table Scan da kein Index (Kosten: 31)
--Datenbank gibt Hinweis einen Index hinzuzufügen

SELECT * FROM KundenUmsatz2 WHERE ID = 30; --Clustered Index Seek (Kosten: 0.0032)
--Ohne Clustered Index: Lesevorgänge: 42166, CPU: 252ms, Gesamtzeit: 92ms
--Mit Clustered Index: Lesevorgänge: 3, CPU: 0ms, Gesamtzeit: 31ms

SELECT * FROM KundenUmsatz2; --ID Spalte jetzt sortiert

--Indizes + Ebenen von den Indizes einer Tabelle anschauen
SELECT * FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('KundenUmsatz2'), NULL, NULL, 'DETAILED');

--Alle Indizes der Datenbank anschauen
SELECT OBJECT_NAME(OBJECT_ID), * FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'DETAILED');

SELECT * FROM KundenUmsatz2 WHERE freight > 50; --Clustered Index Scan (Kosten: 32.4)
--Neuen Index anlegen mit Freight als Indexspalte und allen inkludierten Spalten

SELECT * FROM KundenUmsatz2 WHERE freight > 50; --Index Seek (Kosten: 16.6);

SELECT ID FROM KundenUmsatz2 WHERE ID = 10; --Index Seek

SELECT ID, CustomerID FROM KundenUmsatz2 WHERE ID = 100; --Sollte Lookup machen

SELECT ID, CustomerID FROM KundenUmsatz2 WHERE ID = 100; --CustomerID zu Index hinzugefügt -> Kein Lookup mehr

SELECT * FROM KundenUmsatz2 WHERE freight > 50; --Table Scan da birthdate nicht in NCIX_Freight inkludiert

SELECT freight, birthdate FROM KundenUmsatz2 WHERE freight > 50; --Datenbank geht jetzt über den neuen Index, weil dieser "leichter" ist

SELECT freight, birthdate FROM KundenUmsatz2 WHERE freight > 1000;
--Alle Spalten bei Included Columns entfernt -> Seek + Lookup über CIX (6289 Reads, 3ms)
--Mit Birthdate als Spalte beim Index -> Index Seek ohne Lookup (11 Reads, 1ms)
--Lookup ohne Clustered Index -> Seek + Heap Lookup (2057 Reads, 91ms)

--Zusammengesetzter Index (NCIX_ID_CustomerID)
SELECT * FROM KundenUmsatz2 WHERE ID > 50 AND CustomerID LIKE 'A%'; --CIX wird weiterhin verwendet (Kosten: 31)

SELECT ID, CustomerID FROM KundenUmsatz2 WHERE ID > 50 AND CustomerID LIKE 'A%'; --Neuer Index wird verwendet (Kosten: 0.10)

SELECT ID, CustomerID FROM KundenUmsatz2 WHERE ID > 1100000 AND CustomerID LIKE 'A%'; --CIX wird verwendet weil wenige Daten im Ergebnis sind

SELECT CustomerID FROM KundenUmsatz2 WHERE CustomerID LIKE 'A%' AND ID > 50;
SELECT CustomerID FROM KundenUmsatz2 WHERE ID > 50 AND CustomerID LIKE 'A%';
GO

--Indizierte View
CREATE VIEW IxDemo
AS
SELECT Country, COUNT(*) AS Anz
FROM KundenUmsatz2
GROUP BY Country
GO

SELECT * FROM IxDemo; --Table Scan
GO

ALTER VIEW IxDemo WITH SCHEMABINDING --WITH SCHEMABINDING: Verhindert Änderung der Tabellen hinter der View, Fehlermeldung bei Änderung der originalen Tabelle
AS
SELECT Country, COUNT_BIG(*) AS Anz --COUNT_BIG statt COUNT notwendig
FROM dbo.KundenUmsatz2 --dbo davor schreiben, weil WITH SCHEMABINDUNG
GROUP BY Country
GO

--Jetzt kann ich einen Index erstellen
SELECT * FROM IxDemo; --Index Scan
SELECT * FROM IxDemo WHERE Country = 'UK'; --Index Seek

SELECT Country, COUNT_BIG(*) AS Anz
FROM KundenUmsatz2
GROUP BY Country; --Index wurde übernommen

--Columnstore Index:
--Speichert eine Spalte als "eigene Tabelle"
--Kann genau eine Spalte sehr effizient durchsuchen

SELECT ID FROM KundenUmsatz2; --kein Index, Table Scan
--Reads: 42166, CPU: 375ms, Gesamt: 3675ms

SELECT ID FROM KundenUmsatz2; --normaler Index, Index Scan
--Reads: 42239, CPU: 469ms, Gesamt: 4784ms (dauert länger, da Index Seiten auch geholt werden müssen -> bessere Performance bei genauem Seek)

SELECT ID FROM KundenUmsatz2; --Columnstore Index (Non-Clustered)
--Reads: 1507, CPU: 218ms, Gesamt: 5225ms

SELECT ID FROM KundenUmsatz2; --ColumnStore Index + Normaler Index
--Datenbank wählt aus welcher Index für die Aufgabe effizienter ist
--Datenbank hat ColumnStore Index ausgewählt

--Index für bestimmte Abfrage erstellen
select lastname, year(orderdate), month(orderdate), sum(unitprice*quantity)
from KundenUmsatz2
where shipcountry = 'USA' 
group by lastname, year(orderdate), month(orderdate)
order by 1,2,3;

--Indizes warten
--Indizes werden über Zeit veraltet (durch Insert, Update, Delete)
--Index aktualisieren, 2 Möglichkeiten
--Reorganize: Index neu sortieren ohne Neuaufbau
--Rebuild: Von Grund auf neu aufbauen