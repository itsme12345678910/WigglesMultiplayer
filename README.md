# WigglesMultiplayer
Ein Wiggles Multiplayer-/Coopprojekt aus der Community
![WiggleMPGrafikCrop](https://github.com/itsme12345678910/WigglesMultiplayer/assets/119706537/65400d10-09e0-4ea3-b1c2-4263a7a56ebf)

Anleitung:
  1. WigglesMultiplayer.bat bei beiden Spielern starten (oder WigglesServer.jar doppelklicken)
  2. Im Launcher die IP-Adresse des Mitspielers eintragen (die eigene zeigt der Launcher oben an), bei genau einem Spieler Host, beim anderen Client wählen und auf Starten klicken
  3. Der Launcher startet den WigglesServer und Wiggles; das Spiel wartet im Ladebildschirm, bis beide verbunden sind
  4. Dieselbe Map bei beiden Spielern gleichzeitig starten
  5. Was auf dem einen Client befohlen wird, wird auf beiden umgesetzt (aktuell nur Coop!). Zufallsbewegungen von Zwergen und Tieren würfelt nur der Host, der Client übernimmt sie.

Für den Einzelspieler Wiggles ganz normal starten. Der Launcher trägt die Verbindung nur für den Start aus dem Launcher in data/mp_config.tcl ein.

Ohne Launcher: IP des Mitspielers in runServer.bat eintragen und ausführen, in data/mp_config.tcl mp_address auf 127.0.0.1 und mp_role auf host bzw. client setzen, dann Wiggles starten (danach mp_address wieder leeren).

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
