/*
Normalerweise:
1. Jede Zelle hat einen Wert
2. Jeder Datensatz hat einen PK -> eindeutige Identifikation des Datensatzes
3. Keine Beziehungen zwischen nicht-PK Spalten

Redundanz sollte verringert werden (keine doppelte Speicherung von Daten)
- Beziehungen zwischen Tabellen
PK --> Beziehung --> FK (Fremdschlüssel)

Kundentabelle: 1 Mio. Datensätze
Bestellungstabelle: 2 Mio. Datensätze
Bestellungen -> Beziehung -> Kunden
*/

/*
	8192 Bytes gesamt
	132 Byte Management Daten
	8060 Bytes für tatsächliche Daten

	Max. 700 Datensätze
	Leerer Raum kann existieren
	Seiten werden 1:1 geladen
*/

CREATE DATABASE Demo;
USE Demo;

CREATE TABLE T1 (id int identity, test char(4100));

INSERT INTO T1
SELECT 'xy'
GO 20000 --GO <Zahl>: führt einen Befehl X-mal aus

SELECT COUNT(*) FROM T1;

--DBCC: Database Console Commands
dbcc showcontig('T1');

--Wie groß ist die Tabelle?
--C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA
--4100B * 20000 = 80MB, .mdf File hat aber 200MB

CREATE TABLE T2 (id int identity, test varchar(max));

INSERT INTO T2
SELECT 'xy'
GO 20000

--Durch 700 Datensätze "nur" 93.87%
dbcc showcontig('T2'); --50 Seiten statt 20000 durch varchar

SELECT OBJECT_ID('T1'); --581577110

--DB_ID(), FileID: 0, IndexID: -1, PartitionID: 0, Mode: LIMITED/DETAILED
--Gibt verschiedene Page-Daten über die Tabelle zurück
SELECT * FROM sys.dm_db_index_physical_stats(DB_ID(), 0, -1, 0, 'DETAILED');

--USE Northwind;
--Customers Tabelle: CustomerID ist ein nchar(5) -> 10 Byte pro Datensatz, könnte ein char(5) sein -> 5 Byte pro Datensatz
--INFORMATION_SCHEMA: Gibt verschiedenste Informationen zur Datenbank zurück
SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Customers';
--nvarchar könnte auch in mehreren Spalten optimiert werden (auf varchar)

--Zeigt die Ausführungszeiten und Lesevorgänge einer Abfrage an
SET STATISTICS time, io ON;

USE Demo;

SELECT * FROM T1; --Logische Lesevorgänge: 20000 (weil 20000 Seiten), CPU-Zeit 172ms, Gesamtzeit: 1281ms
--Lesevorgänge möglichst reduzieren, danach Gesamtzeit, danach CPU-Zeit

SELECT * FROM T2; --Logische Lesevorgänge: 50, CPU-Zeit 16ms, Gesamtzeit: 238ms
--Weniger Lesevorgänge -> niedrigere Gesamtzeit

SELECT * FROM T1 WHERE id = 50; --Logische Lesevorgänge: 20000, CPU-Zeit: 31ms, Gesamtzeit: 31ms
--Nicht relevante Datensätze einfach überspringen

SELECT TOP 1 * FROM T1 WHERE id = 50; --Durch TOP 1 wird bei dem ersten Datensatz aufgehört

--Seiten reduzieren
--Besser Datentypen oder durch Redesign
--Bessere Verteilung der Daten, andere Schlüssel, ...

--1 Mio. * 2DS/Seite -> 500000 Seiten -> 4GB
--1 Mio. * 50DS/Seite -> 12500 -> 110MB

SET STATISTICS time, io OFF

CREATE TABLE T3 (id int identity, test nvarchar(max));

INSERT INTO T3
SELECT 'xy'
GO 20000

DBCC showcontig('T3'); --55 Seiten statt 50, 94.32% Seitendichte statt 93.87%, Datensätze wieder zu klein für ~100% Füllung

--Northwind
--CustomerID = nchar(5) -> char(5)
--varchar(50): standardmäßig nur 4B
--nvarchar(50): 2 * 4B = 8B
--text: Deprecated seit 2005

--float: 4B bei kurzen Zahlen, 8B bei langen Zahlen
--decimal(X, Y): je weniger Platz desto weniger Byte

--tinyint: 1B, smallint: 2B, int: 4B, bigint: 8B

USE Northwind;
DBCC showcontig('Customers'); --96.98% (durch breite Datensätze)

SET STATISTICS time, io ON

DBCC showcontig('Orders'); --98.19%

SELECT * FROM Orders WHERE YEAR(OrderDate) = 1997 --22 Lesevorgänge, 101ms Gesamtzeit

SELECT * FROM Orders WHERE OrderDate BETWEEN '19970101' AND '19971231'; --22 Lesevorgänge, ~120ms (dauert etwas länger)

SELECT * FROM Orders WHERE OrderDate >= '19970101' AND OrderDate <= '19971231'; --22 Lesevorgänge, ~120ms (ähnlich wie BETWEEN)