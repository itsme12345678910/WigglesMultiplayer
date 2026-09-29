import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.ArrayList;
import java.util.List;

/**
 * Eine Multiplayer-Sitzung des Launchers: schreibt data/mp_config.tcl, startet den WigglesServer als
 * eigenen Prozess und auf Wunsch das Spiel.
 *
 * Hat der Host einen Spielstand gewaehlt, uebertraegt der Server ihn an den Client. Beide Spiele laden ihn
 * dann direkt beim Programmstart ueber data/userstartup.tcl (gameload funktioniert nur dort, im laufenden
 * Spiel haengt es sich auf). Der Client startet sein Spiel erst, wenn der Spielstand angekommen ist.
 *
 * Damit ein spaeterer normaler Spielstart wieder Einzelspieler mit Hauptmenue ist, werden die Adresse in
 * mp_config.tcl und userstartup.tcl wieder entfernt, sobald das Spiel sie gelesen hat (erste Verbindung
 * des Spiels zum Server), spaetestens beim Beenden der Sitzung.
 */
public class MultiplayerSession {

    public static final String ROLE_HOST = "host";
    public static final String ROLE_CLIENT = "client";

    /** Unter diesem Namen laden beide Spiele den Spielstand des Hosts (reiner ASCII-Pfad fuer gameload). */
    static final String MULTIPLAYER_SAVE = "data/gamesave/save_Multiplayer.sav";
    private static final String USER_STARTUP = "data/userstartup.tcl";
    private static final String USER_STARTUP_MARKER = "# Angelegt vom Wiggles Multiplayer Launcher";

    public static class Settings {
        public String peerAddress;
        public int listenPort;
        public int peerPort;
        public int gamePort;
        public String role;
        /** Nur Host: Spielstand, den beide laden, oder null fuer das Hauptmenue */
        public Path saveGame;
    }

    public interface Listener {
        void log(String line);

        void status(String text);

        /** Die Sitzung ist beendet (Stoppen, Spiel beendet oder Server abgestuerzt). */
        void stopped();
    }

    private final Path gameDir;
    private final Path configFile;
    private final Path userStartupFile;
    private final List<String> serverCommand;
    private final Listener listener;

    private Process server;
    private Process game;
    private Settings settings;
    private List<String> gameCommand;
    private boolean configActive;
    private boolean userStartupActive;
    private boolean gameStarted;
    private boolean synced;
    private boolean running;

    /**
     * @param serverCommand Befehl zum Starten des Servers ohne dessen Argumente,
     *                      z. B. [javaw, -cp, WigglesServer.jar, mainClass]
     */
    public MultiplayerSession(Path gameDir, List<String> serverCommand, Listener listener) {
        this.gameDir = gameDir;
        this.configFile = gameDir.resolve("data").resolve("mp_config.tcl");
        this.userStartupFile = gameDir.resolve(USER_STARTUP);
        this.serverCommand = serverCommand;
        this.listener = listener;
    }

    public synchronized boolean isRunning() {
        return running;
    }

    public synchronized boolean isGameRunning() {
        return game != null && game.isAlive();
    }

    /** @param gameCommand Befehl zum Starten des Spiels oder null, wenn der Spieler es selbst startet */
    public synchronized void start(Settings settings, List<String> gameCommand) throws IOException {
        if (running) {
            return;
        }
        prepareUserStartup();
        this.settings = settings;
        this.gameCommand = gameCommand;
        boolean host = ROLE_HOST.equals(settings.role);
        Path multiplayerSave = gameDir.resolve(MULTIPLAYER_SAVE);
        // Beide laden den Spielstand unter demselben reinen ASCII-Namen, Umlaute im Namen stoeren so nicht
        if (host && settings.saveGame != null
                && !(Files.exists(multiplayerSave) && Files.isSameFile(settings.saveGame, multiplayerSave))) {
            Files.copy(settings.saveGame, multiplayerSave, StandardCopyOption.REPLACE_EXISTING);
        }
        writeConfig(configFile, "127.0.0.1", settings.gamePort, settings.role);
        configActive = true;
        running = true;
        gameStarted = false;
        synced = false;
        try {
            List<String> command = new ArrayList<>(serverCommand);
            command.add(String.valueOf(settings.listenPort));
            command.add(String.valueOf(settings.gamePort));
            command.add(settings.peerAddress);
            command.add(String.valueOf(settings.peerPort));
            if (host) {
                command.add("-host");
                command.add(settings.saveGame != null ? MULTIPLAYER_SAVE : "none");
            } else {
                command.add("-client");
                command.add(MULTIPLAYER_SAVE);
            }
            ProcessBuilder serverBuilder = new ProcessBuilder(command);
            // remoteCommand wird relativ zum Arbeitsverzeichnis geschrieben, also im Spielordner starten
            serverBuilder.directory(gameDir.toFile());
            serverBuilder.redirectErrorStream(true);
            Process serverProcess = serverBuilder.start();
            server = serverProcess;
            startDaemon(() -> readServerOutput(serverProcess), "server-output");
            listener.status("Warte auf Mitspieler " + settings.peerAddress + ":" + settings.peerPort + " ...");

            if (host) {
                if (settings.saveGame != null) {
                    writeUserStartup(MULTIPLAYER_SAVE);
                }
                startGame();
            }
            // Der Client startet sein Spiel, sobald er vom Host weiss, ob ein Spielstand geladen wird
        } catch (IOException e) {
            stop();
            throw e;
        }
    }

    /** Beendet den Server und raeumt die Startdateien auf. Ein laufendes Spiel bleibt offen. */
    public void stop() {
        synchronized (this) {
            if (!running) {
                return;
            }
            running = false;
            resetStartFiles();
            if (server != null) {
                server.destroy();
                server = null;
            }
        }
        listener.status("Gestoppt");
        listener.stopped();
    }

    private synchronized void startGame() throws IOException {
        if (!running || gameStarted) {
            return;
        }
        gameStarted = true;
        if (gameCommand == null) {
            listener.status("Bereit - jetzt Wiggles starten");
            return;
        }
        if (isGameRunning()) {
            return;
        }
        ProcessBuilder gameBuilder = new ProcessBuilder(gameCommand);
        gameBuilder.directory(gameDir.toFile());
        gameBuilder.redirectErrorStream(true);
        Process gameProcess = gameBuilder.start();
        game = gameProcess;
        startDaemon(() -> watchGame(gameProcess), "game-watch");
    }

    private void readServerOutput(Process process) {
        try (BufferedReader in = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
            String line;
            while ((line = in.readLine()) != null) {
                listener.log(line);
                onServerLine(line);
            }
        } catch (IOException e) {
            // Prozess beendet
        }
        boolean unexpected;
        synchronized (this) {
            unexpected = running && server == process;
        }
        if (unexpected) {
            listener.log("WigglesServer wurde unerwartet beendet");
            stop();
        }
    }

    private void onServerLine(String line) {
        if (line.startsWith("[proxy] Verbunden mit")) {
            if (!isSynced()) {
                listener.status("Mit Mitspieler verbunden ...");
            }
        } else if (line.startsWith("[save] Sende Spielstand")) {
            listener.status("Sende Spielstand an den Mitspieler ...");
        } else if (line.startsWith("[save] Spielstand gesendet") || line.startsWith("[save] Kein Spielstand gewaehlt")) {
            listener.status("Warte, bis beide Spiele geladen haben ...");
        } else if (line.startsWith("[save] Empfange Spielstand ")) {
            listener.status("Empfange Spielstand vom Host ... " + line.substring("[save] Empfange Spielstand ".length()));
        } else if (line.startsWith("[save] Spielstand empfangen")) {
            startGameAfterSave(true);
        } else if (line.startsWith("[save] Kein Spielstand vom Host")) {
            startGameAfterSave(false);
        } else if (line.startsWith("[save] WARNUNG")) {
            listener.status("Beide Spieler sind Host - einer muss Client sein!");
        } else if (line.startsWith("[save] FEHLER")) {
            listener.status("Spielstand-Uebertragung fehlgeschlagen, siehe Log");
        } else if (line.startsWith("[proxy] Verbindung angenommen")) {
            // Das Spiel verbindet sich erst, nachdem es mp_config.tcl und userstartup.tcl gelesen hat
            synchronized (this) {
                resetStartFiles();
            }
            if (!isSynced()) {
                listener.status("Wiggles ist bereit, warte auf den Mitspieler ...");
            }
        } else if (line.startsWith("[sync] Beide Spiele bereit")) {
            synchronized (this) {
                synced = true;
            }
            listener.status("Verbunden – viel Spaß!");
        } else if (line.startsWith("[proxy] Senden fehlgeschlagen")) {
            listener.status("Verbindung zum Mitspieler verloren, verbinde neu ...");
        } else if (line.contains("Konnte nicht auf Port")) {
            listener.status("Port belegt – läuft schon ein WigglesServer?");
        }
    }

    private void startGameAfterSave(boolean withSave) {
        try {
            synchronized (this) {
                if (!running || gameStarted) {
                    return;
                }
                if (withSave) {
                    writeUserStartup(MULTIPLAYER_SAVE);
                }
            }
            listener.status(withSave ? "Spielstand empfangen, starte Wiggles ..." : "Kein Spielstand vom Host, starte Wiggles ...");
            startGame();
        } catch (IOException e) {
            listener.log("FEHLER: Wiggles konnte nicht gestartet werden: " + e.getMessage());
            listener.status("Start von Wiggles fehlgeschlagen");
        }
    }

    private synchronized boolean isSynced() {
        return synced;
    }

    private void watchGame(Process process) {
        drain(process.getInputStream());
        try {
            process.waitFor();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return;
        }
        listener.log("Wiggles wurde beendet");
        stop();
    }

    /** Entfernt eine userstartup.tcl aus einer abgebrochenen Sitzung; eine fremde bleibt unangetastet. */
    private void prepareUserStartup() throws IOException {
        if (!Files.exists(userStartupFile)) {
            return;
        }
        if (!isOwnUserStartup()) {
            throw new IOException(USER_STARTUP + " existiert bereits und stammt nicht vom Launcher.\n"
                    + "Bitte umbenennen oder loeschen, der Launcher braucht die Datei fuer den Spielstand.");
        }
        Files.delete(userStartupFile);
    }

    private boolean isOwnUserStartup() throws IOException {
        List<String> lines = Files.readAllLines(userStartupFile, StandardCharsets.ISO_8859_1);
        return !lines.isEmpty() && lines.get(0).equals(USER_STARTUP_MARKER);
    }

    private void writeUserStartup(String saveGame) throws IOException {
        String content = USER_STARTUP_MARKER + "\r\n"
                + "# Laedt beim Programmstart den Multiplayer-Spielstand statt des Hauptmenues.\r\n"
                + "# Der Launcher loescht die Datei wieder, sobald Wiggles verbunden ist.\r\n"
                + "gameload " + saveGame + "\r\n";
        Files.write(userStartupFile, content.getBytes(StandardCharsets.ISO_8859_1));
        userStartupActive = true;
    }

    private void resetStartFiles() {
        if (userStartupActive) {
            try {
                if (Files.exists(userStartupFile) && isOwnUserStartup()) {
                    Files.delete(userStartupFile);
                }
                userStartupActive = false;
            } catch (IOException e) {
                listener.log("FEHLER: Kann " + userStartupFile + " nicht loeschen: " + e.getMessage());
            }
        }
        if (configActive) {
            try {
                writeConfig(configFile, "", settings.gamePort, settings.role);
                configActive = false;
            } catch (IOException e) {
                listener.log("FEHLER: Kann " + configFile + " nicht zuruecksetzen: " + e.getMessage());
            }
        }
    }

    /** Schreibt data/mp_config.tcl; eine leere Adresse bedeutet Einzelspieler. */
    public static void writeConfig(Path file, String address, int port, String role) throws IOException {
        String[] lines = {
                "# Multiplayer-Konfiguration der Wiggles-Mod",
                "#",
                "# Solange mp_address leer ist, laeuft Wiggles wie das normale Einzelspieler-Spiel.",
                "# Ist eine Adresse eingetragen, wartet das Spiel beim Start, bis der WigglesServer",
                "# erreichbar und mit dem Mitspieler verbunden ist.",
                "#",
                "# Der Launcher (WigglesMultiplayer.bat) traegt die Werte beim Starten selbst ein und leert",
                "# mp_address wieder, sobald das Spiel verbunden ist. Von Hand wird die Datei nur gebraucht,",
                "# wenn der Server ueber runServer.bat gestartet wird.",
                "#",
                "#   mp_address  Adresse des eigenen WigglesServers, normalerweise 127.0.0.1",
                "#   mp_port     Proxy-Port des WigglesServers (zweite Zahl in runServer.bat)",
                "#   mp_role     host    erzeugt die Zufallsbewegungen von Zwergen und Tieren und schickt sie mit",
                "#               client  uebernimmt die Zufallsbewegungen vom Host und wuerfelt nie selbst",
                "#                       (ohne Host bewegt sich dann nichts zufaellig)",
                "#               Genau ein Spieler muss host sein.",
                "",
                "set mp_address \"" + address + "\"",
                "set mp_port " + port,
                "set mp_role " + role,
        };
        StringBuilder content = new StringBuilder();
        for (String line : lines) {
            content.append(line).append("\r\n");
        }
        Files.write(file, content.toString().getBytes(StandardCharsets.ISO_8859_1));
    }

    private static void drain(InputStream in) {
        byte[] buffer = new byte[4096];
        try {
            while (in.read(buffer) >= 0) {
                // Ausgabe des Spiels wird nicht gebraucht, muss aber gelesen werden
            }
        } catch (IOException e) {
            // Prozess beendet
        }
    }

    private static void startDaemon(Runnable runnable, String name) {
        Thread thread = new Thread(runnable, name);
        thread.setDaemon(true);
        thread.start();
    }

    /** Befehl, der diesen WigglesServer in einem eigenen Prozess ohne Konsolenfenster startet. */
    public static List<String> ownServerCommand() {
        String javaBin = System.getProperty("java.home") + File.separator + "bin" + File.separator;
        String java = new File(javaBin + "javaw.exe").exists() ? javaBin + "javaw.exe" : javaBin + "java";
        List<String> command = new ArrayList<>();
        command.add(java);
        // Der Server laeuft im Spielordner, relative Eintraege des Klassenpfads muessen absolut werden
        List<String> classPath = new ArrayList<>();
        for (String entry : System.getProperty("java.class.path").split(File.pathSeparator)) {
            classPath.add(new File(entry).getAbsolutePath());
        }
        command.add("-cp");
        command.add(String.join(File.pathSeparator, classPath));
        command.add("mainClass");
        return command;
    }
}
