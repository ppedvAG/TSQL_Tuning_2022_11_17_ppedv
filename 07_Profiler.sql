--Profiler: Live mitverfolgen was auf der Datenbank passiert
--Tools -> SQL Server Profiler

--Name: Dateiname
--Template: Default/Tuning
--Save to File: .trc File
--File Rollover aktivieren
--Enable Stop Trace Time: Duration 30min

--Events: SP:StmtStarting, SP:StmtStopping, SP:BatchStarted, SP:BatchCompleted
--Column Filter: DatabaseName Like Name (muss als Spalte aktiviert werden)

SELECT * FROM KundenUmsatz2; --Abfrage ist jetzt im Profiler sichtbar

--Tuning Advisor
--Tools -> Database Engine Tuning Advisor

--braucht ein .trc File (vom Profiler)
--Datenbank f�r Workload ausw�hlen (Demo)
--Datenbank ausw�hlen (Demo)

--Ausw�hlen was verbessert werden soll
--Indizes, filtered Indizes, Columnstore Indizes oder Partitionen
--Start Analysis

--Ergebnisse ausw�hlen die man implementieren m�chte -> Select recommendation
--Action -> Apply recommendations