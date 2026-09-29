# WigglesMultiplayer
Ein Wiggles Multiplayer-/Coopprojekt aus der Community
![WiggleMPGrafikCrop](https://github.com/itsme12345678910/WigglesMultiplayer/assets/119706537/65400d10-09e0-4ea3-b1c2-4263a7a56ebf)

Anleitung:
  1. IP des Mitspielers in der runServer.bat eintragen
  2. In data/mp_config.tcl bei beiden Spielern mp_address auf 127.0.0.1 setzen, bei genau einem Spieler mp_role auf host, beim anderen auf client (ohne Eintrag in mp_address läuft Wiggles wie das normale Einzelspieler-Spiel)
  3. runServer.bat bei beiden Spieler ausführen
  4. Wiggles bei beiden Spielern starten (der Ladebildschirm wartet, bis die Verbindung steht)
  5. Dieselbe Map bei beiden Spielern gleichzeitig starten
  6. Die beiden Client sollten verbunden sein und das was auf dem einen Client befohlen wird sollte auf beiden umgesetzt werden (aktuell nur Coop!). Zufallsbewegungen von Zwergen und Tieren würfelt nur der Host, der Client übernimmt sie.

Voraussetzungen:
- Angepasste .tcl, .dll und .jar Dateien aus dem Projekt in den eigenen Wiggles Ordner kopiert
- Java installiert und java/bin Pfad in den Systemumgebungsvariablen hinterlegt damit der Java Server gestartet werden kann
- Beide Client müssen über zueinander Verbindungen aufbauen können (Firewall Zugriff erlaubt, IP sichtbar (am besten mit ipconfig und ping über die cmd vorher kurz testen)) - IPv4 oder IPv6 möglich!

Bekannte Probleme:
- Das Spiel überträgt noch nicht alle möglichen Aktionen
- Das Spiel läuft out of Sync (Quasi nicht wirklich länger spielbar im aktuellen Stand!)

Hinweise zur Entwicklung:
- Die .tcl-Dateien des Spiels sind in Windows-1252 (cp1252) kodiert. Editoren oder Tools, die sie als UTF-8 speichern, zerstören die Umlaute.
- Zufallsstellen in Klassen-Scripts laufen über data/Scripts/misc/mp_sync.tcl und werden so nur vom Host gewürfelt, z. B. [irandom 14] -> [mp_irandom schluessel standardwert 14].
- Quellen der tcl83.dll liegen unter tcl8.3.2/. Gebaut wird mit nmake -f makefile.vc; nmake -f makefile.vc LOGCOMMANDS=1 baut die Debug-DLL, die jeden ausgeführten Befehl in die Datei commandsExecuted schreibt (nur für Reverse Engineering, nicht für den Mod).
