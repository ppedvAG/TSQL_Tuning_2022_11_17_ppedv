--MAXDOP
--Maximum Degree of Parallelism

--ab einem Kostenschwellwert wird die Abfrage parallelisiert
--Standard: 5

--MAXDOP konfigurierbar auf 3 Ebenen: Server, DB, Query
--Query > DB > Server

SET STATISTICS time, io ON

SELECT freight, birthdate FROM KundenUmsatz2 WHERE freight > 1000;
--4 CPU-Kerne: 186ms CPU, 109ms Gesamt
--8 CPU-Kerne: 156ms CPU, 94ms Gesamt

--Im Plan sichtbar mit 2 Gelben Pfeilen auf der Abfrage
--Number of Executions: Anzahl Kerne
--Bei SELECT ganz links: Degree of Parallelism

SELECT * FROM KundenUmsatz2 OPTION (MAXDOP 8); --Keine Parallelisierung erzwungen
--Reads: 41819, CPU: 1593ms, Gesamt: 13071ms

SELECT Country, SUM(freight) FROM KundenUmsatz2 GROUP BY Country; --Parallelisiert da Kosten von 32, MAXDOP 8
--CPU: 267ms, Gesamt: 71ms

SELECT Country, SUM(freight) FROM KundenUmsatz2 GROUP BY Country OPTION (MAXDOP 1); --Keine Parallelisierung
--CPU: 172ms, Gesamt 215ms
--Dauert länger

SELECT Country, SUM(freight) FROM KundenUmsatz2 GROUP BY Country OPTION (MAXDOP 4);
--CPU: 202ms, Gesamt 88ms

SELECT *, YEAR(OrderDate), CONCAT_WS(' ', FirstName, LastName)
FROM KundenUmsatz2
WHERE Country IN(SELECT Country FROM KundenUmsatz2 WHERE Country LIKE 'A%');
--CPU: 735ms, Gesamt: 1416ms

SELECT *, YEAR(OrderDate), CONCAT_WS(' ', FirstName, LastName)
FROM KundenUmsatz2
WHERE Country IN(SELECT Country FROM KundenUmsatz2 WHERE Country LIKE 'A%')
OPTION (MAXDOP 4);
--CPU: 469ms, Gesamt: 1382ms

SELECT *, YEAR(OrderDate), CONCAT_WS(' ', FirstName, LastName)
FROM KundenUmsatz2
WHERE Country IN(SELECT Country FROM KundenUmsatz2 WHERE Country LIKE 'A%')
OPTION (MAXDOP 1);
--CPU: 266ms, Gesamt 1648ms