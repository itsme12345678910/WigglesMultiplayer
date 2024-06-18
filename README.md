# WigglesMultiplayer
Ein Wiggles Multiplayer-/Coopprojekt aus der Community
![WiggleMPGrafikCrop](https://github.com/itsme12345678910/WigglesMultiplayer/assets/119706537/65400d10-09e0-4ea3-b1c2-4263a7a56ebf)

Anleitung:
  1. IP des Mitspielers in der runServer.bat eintragen
  2. runServer.bat bei beiden Spieler ausführen
  3. Wiggles bei beiden Spielern starten
  4. Dieselbe Map bei beiden Spielern gleichzeitig starten
  5. Die beiden Client sollten verbunden sein und das was auf dem einen Client befohlen wird sollte auf beiden umgesetzt werden (aktuell nur Coop!) 

Voraussetzungen:
- Angepasste .tcl, .dll und .jar Dateien aus dem Projekt in den eigenen Wiggles Ordner kopiert
- Java installiert und java/bin Pfad in den Systemumgebungsvariablen hinterlegt damit der Java Server gestartet werden kann
- Beide Client müssen über zueinander Verbindungen aufbauen können (Firewall Zugriff erlaubt, IP sichtbar (am besten mit ipconfig und ping über die cmd vorher kurz testen)) - IPv4 oder IPv6 möglich!

Bekannte Probleme:
- Das Spiel überträgt noch nicht alle möglichen Aktionen
- Das Spiel läuft out of Sync (Quasi nicht wirklich länger spielbar im aktuellen Stand!)
