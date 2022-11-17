CREATE PARTITION FUNCTION pfDatum(datetime)
AS
RANGE LEFT FOR VALUES ('20190101', '20200101', '20210101'); --20181231 wäre besser weil Grenzen sind inklusiv

CREATE PARTITION SCHEME datumScheme
AS
PARTITION pfDatum TO (Bis2020, Bis2021, Bis2022, BisHeute); --Bis2020 sollte Bis2019 sein

CREATE TABLE Rechnungsdaten (id int identity, rechnungsdatum datetime, betrag float) ON datumScheme(rechnungsdatum);

DECLARE @i int = 0;
WHILE @i < 3000
BEGIN
	INSERT INTO Rechnungsdaten VALUES
	(DATEADD(DAY, FLOOR(RAND()*1460), '20180101'), RAND() * 1000);
	SET @i += 1;
END

SELECT * FROM Rechnungsdaten ORDER BY rechnungsdatum;

GO
DROP TABLE Archiv20182019;
GO
CREATE TABLE Archiv20182019 (id int identity, rechnungsdatum datetime, betrag float) ON Bis2020;

ALTER TABLE Rechnungsdaten SWITCH PARTITION 1 TO Archiv20182019;

--Gibt eine Übersicht welche Datensätze in welchen Partitionen sind
SELECT
$partition.pfDatum(rechnungsdatum) AS PNummer,
COUNT(*) AS Anzahl,
MIN(rechnungsdatum) AS KleinerDS,
MAX(rechnungsdatum) AS GroessterDS
FROM Rechnungsdaten
GROUP BY $partition.pfDatum(rechnungsdatum);

--Partitionsinformationen auf der Datenbank einsehen
SELECT OBJECT_NAME(object_id), * FROM sys.dm_db_partition_stats;