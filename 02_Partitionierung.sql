USE Demo;

--Partition Functions
--Werden verwendet um Daten auf Partitionen aufzuteilen
--Benötigt ein Partitionsschema
CREATE PARTITION FUNCTION pfZahl(int)
AS
RANGE LEFT FOR VALUES (100, 200); --Ranges festlegen von links (0-100, 101-200, 201-unendlich)

--Partitionsfunktion testen
SELECT $partition.pfZahl(50); --Partition 1
SELECT $partition.pfZahl(150); --Partition 2
SELECT $partition.pfZahl(250); --Partition 3

--Partitionsschema: Legt fest auf welche File Groups ein Datensatz gelegt wird
--Benötigt eine Partitionsfunktion
--Benötigt eine File Group + File pro Range
CREATE PARTITION SCHEME schZahl
AS
PARTITION pfZahl TO (Bis100, Bis200, ab200);

--Mit ON <Partitionsschema>(<Spalte>) Tabelle auf ein Schema legen
CREATE TABLE pTable (id int identity, partitionNumber int, test char(5000)) ON schZahl(partitionNumber); --PartitionNumber nur testweise, ID wäre sinnvoller

DECLARE @i int = 0;
WHILE @i < 20000
BEGIN
	INSERT INTO pTable VALUES (@i, 'XY');
	SET @i += 1;
END

SET STATISTICS time, io ON;

SELECT * FROM pTable WHERE partitionNumber = 150; --0ms/0ms da 150 in der mittleren Partition ist

SELECT * FROM pTable WHERE id = 150; --15ms/18ms da id nicht die Partitionierungsspalte ist

SELECT * FROM pTable WHERE partitionNumber = 1500; --16ms/12ms da 1500 in der großen Partition ist

--Neue Grenze einfügen
--Davor neue FileGroup + File erstellen
--Bei File FileGroup setzen

ALTER PARTITION SCHEME schZahl NEXT USED bis5000; -------bis100------bis200-------bis5000------

ALTER PARTITION FUNCTION pfZahl() SPLIT RANGE(5000); --Neue Range hinzufügen (100, 200, 5000)

SELECT $partition.pfZahl(6000); --Partition 4

ALTER PARTITION FUNCTION pfZahl() MERGE RANGE(100); --Teil einer Range entfernen (hier 100) -> (200, 5000)

CREATE TABLE archiv (id int identity, partitionNumber int, test char(5000)) ON bis200;

ALTER TABLE pTable SWITCH PARTITION 1 TO archiv; --Alles von Partition 1 in pTable in das Archiv bewegen

SELECT * FROM pTable; --200 bis Ende
SELECT * FROM archiv; --0-200 unsortiert

INSERT INTO pTable VALUES (10, 'XYZ');