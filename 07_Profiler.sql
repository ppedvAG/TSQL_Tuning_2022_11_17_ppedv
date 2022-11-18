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
--Datenbank für Workload auswählen (Demo)
--Datenbank auswählen (Demo)

--Auswählen was verbessert werden soll
--Indizes, filtered Indizes, Columnstore Indizes oder Partitionen
--Start Analysis

--Ergebnisse auswählen die man implementieren möchte -> Select recommendation
--Action -> Apply recommendations