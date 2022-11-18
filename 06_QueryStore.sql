--Query Store: Erstellt Statistiken zu ausgeführten Abfragen
--Speichert CPU-Zeit, Gesamtzeit, Reads, ...
--Speichert auch die Pläne zu den Abfragen

--Rechtsklick auf die Datenbank -> Query Store -> Operation Mode: Read/Write
--Neuer Query Store Ordner mit vorgegebenen Statistiken

USE Demo;

--Queries als Tabellen ansehen
SELECT Txt.query_text_id, Txt.query_sql_text, Pl.plan_id, Qry.*  
FROM sys.query_store_plan AS Pl 
JOIN sys.query_store_query AS Qry ON Pl.query_id = Qry.query_id  
JOIN sys.query_store_query_text AS Txt ON Qry.query_text_id = Txt.query_text_id;

EXEC sys.sp_query_store_remove_query 5;

SELECT * FROM KundenUmsatz2; --Neue Query im Query Store anzeigen

--Alle gespeicherten Pläne anzeigen
--XML anklicken um Pläne anzuschauen
SELECT UseCounts, Cacheobjtype, Objtype, TEXT, query_plan
FROM sys.dm_exec_cached_plans 
CROSS APPLY sys.dm_exec_sql_text(plan_handle)
CROSS APPLY sys.dm_exec_query_plan(plan_handle);