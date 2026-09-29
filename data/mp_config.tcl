# Multiplayer-Konfiguration der Wiggles-Mod
#
# Solange mp_address leer ist, laeuft Wiggles wie das normale Einzelspieler-Spiel.
# Ist eine Adresse eingetragen, wartet das Spiel beim Start, bis der WigglesServer (runServer.bat)
# erreichbar und mit dem Mitspieler verbunden ist.
#
#   mp_address  Adresse des eigenen WigglesServers, normalerweise 127.0.0.1
#   mp_port     Proxy-Port des WigglesServers (zweite Zahl in runServer.bat)
#   mp_role     host    erzeugt die Zufallsbewegungen von Zwergen und Tieren und schickt sie mit
#               client  uebernimmt die Zufallsbewegungen vom Host und wuerfelt nie selbst
#                       (ohne Host bewegt sich dann nichts zufaellig)
#               Genau ein Spieler muss host sein.

set mp_address ""
set mp_port 5593
set mp_role host
