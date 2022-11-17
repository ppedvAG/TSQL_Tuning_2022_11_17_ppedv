/*
	Dateigruppen:
	[PRIMARY]: Hauptgruppe, enthält Systemdatenbanken, Tabellen kommen standardmäßig auf PRIMARY, kann nicht entfernt werden (.mdf)
	Nebengruppen: Datenbankobjekte können auch auf Nebengruppen gelegt werden (.ndf)
*/

USE Demo;

CREATE TABLE XYZ (id int);

CREATE TABLE XYZ1 (id int) ON [PRIMARY]; --Auf Primärgruppe legen, nur sinnvoll wenn die Primärgruppe nicht die Standardgruppe ist

CREATE TABLE XYZ2 (id int) ON [AKTIV]; --Tabelle auf andere Gruppe legen

--Rechtsklick auf Datenbank -> Properties -> Filegroups -> Add
ALTER DATABASE Demo ADD FILEGROUP [AKTIV]; --Filegroup erstellen

--Rechtsklick auf Datenbank -> Properties -> File -> Add
ALTER DATABASE Demo ADD FILE
(
	NAME='DemoAktiv',
	FILENAME='C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\DemoAktiv.ndf',
	SIZE=8192KB,
	FILEGROWTH=16MB
);

--Wie bewegt man eine Tabelle auf eine andere FileGroup?
--Tabelle auf der anderen Seite erstellen und Daten bewegen
CREATE TABLE Test (id int) ON [AKTIV];

INSERT INTO Test SELECT id FROM T1; --Alle Daten bewegen mittels INSERT INTO -> SELECT

DROP TABLE T1;

--Salamitaktik
--Aufteilung von großer Tabelle auf mehrere kleine Tabellen

CREATE TABLE Umsatz
(
	Datum date,
	Umsatz float
);

DECLARE @i int = 0; --Testtabellen befüllen
WHILE @i < 1000
BEGIN
	INSERT INTO Umsatz VALUES
	(DATEADD(DAY, FLOOR(RAND()*365), '20190101'), RAND() * 1000);
	SET @i += 1;
END

SET STATISTICS time, io ON;

SELECT * FROM Umsatz WHERE MONTH(Datum) = '1'; --Estimated Operator Cost: 0.91

CREATE TABLE Umsatz2021
(
	Datum date,
	Umsatz float
);

DECLARE @i2 int = 0; --Testtabellen befüllen
WHILE @i2 < 100000
BEGIN
	INSERT INTO Umsatz2021 VALUES
	(DATEADD(DAY, FLOOR(RAND()*365), '20210101'), RAND() * 1000);
	SET @i2 += 1;
END

SELECT * FROM Umsatz WHERE YEAR(Datum) = 2020; --Ganze Tabelle anschauen
GO

DROP VIEW UmsatzGesamt;
GO
CREATE VIEW UmsatzGesamt
AS
SELECT * FROM Umsatz2019
UNION ALL --UNION ALL: Keine Duplikate filtern, spart CPU-Zeit
SELECT * FROM Umsatz2020
UNION ALL
SELECT * FROM Umsatz2021
GO

SELECT * FROM UmsatzGesamt WHERE YEAR(Datum) = 2020; --28% Scan auf alle 3 Tabellen (bringt nix)

--CHECK Constraint
--Überprüft vor INSERT/UPDATE ob ein Datensatz korrekt ist anhand einer/mehrere Bedingungen
--z.B.: Check Umsatz2020 ob Datensatz auch Jahr 2020 hat

ALTER TABLE Umsatz2019 ADD CONSTRAINT CHK_Year2019 CHECK (YEAR(Datum) = 2019); --Check Constraints hinzufügen
ALTER TABLE Umsatz2020 ADD CONSTRAINT CHK_Year2020 CHECK (YEAR(Datum) = 2020);
ALTER TABLE Umsatz2021 ADD CONSTRAINT CHK_Year2021 CHECK (YEAR(Datum) = 2021);

ALTER TABLE Umsatz2019 ADD ID int identity(0, 1) primary key; --IDs im nachhinein hinzugefügt
ALTER TABLE Umsatz2020 ADD ID int identity(1000000, 1) primary key;
ALTER TABLE Umsatz2021 ADD ID int identity(2000000, 1) primary key;

SELECT * FROM UmsatzGesamt WHERE YEAR(Datum) = 2020;

USE Demo;
ALTER TABLE Umsatz2019 DROP CONSTRAINT PK__Umsatz20__3214EC271AA13713;
ALTER TABLE Umsatz2019 DROP COLUMN ID;
ALTER TABLE Umsatz2020 DROP CONSTRAINT PK__Umsatz20__3214EC2785FE764E;
ALTER TABLE Umsatz2020 DROP COLUMN ID;
ALTER TABLE Umsatz2021 DROP CONSTRAINT PK__Umsatz20__3214EC27D8A41792;
ALTER TABLE Umsatz2021 DROP COLUMN ID;