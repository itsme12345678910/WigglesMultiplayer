import java.io.BufferedReader;
import java.io.IOException;
import java.io.OutputStream;
import java.io.InputStreamReader;
import java.net.ServerSocket;
import java.net.Socket;
import java.nio.charset.StandardCharsets;

/**
 * Nimmt Verbindungen auf einem Port an und verarbeitet jede empfangene Zeile als einen Tcl-Befehl.
 *
 * proxy:    Verbindungen aus dem eigenen Spiel. Wiggles hat pro Objekt einen eigenen Tcl-Interpreter
 *           und jeder Interpreter oeffnet seine eigene Verbindung, deshalb werden beliebig viele
 *           Verbindungen gleichzeitig angenommen. Jede Zeile geht an den Server des Mitspielers.
 * incoming: Verbindung vom Server des Mitspielers. Jede Zeile, die nicht das Echo eines selbst
 *           gesendeten Befehls ist, wird in die Befehlsdatei fuer das eigene Spiel geschrieben.
 * log:      Gibt nur aus, was ankommt.
 */
public class Server implements Runnable {

    public enum Mode {
        proxy, incoming, log
    }

    private final int serverPort;
    private final Mode mode;
    private final EchoFilter echoFilter;
    private final TCPClient client;
    private final CommandFile commandFile;
    private final ReadyBarrier barrier;
    private final SaveTransfer.Receiver saveReceiver;

    public Server(int serverPort, Mode mode, EchoFilter echoFilter, TCPClient client, CommandFile commandFile,
                  ReadyBarrier barrier, SaveTransfer.Receiver saveReceiver) {
        this.serverPort = serverPort;
        this.mode = mode;
        this.echoFilter = echoFilter;
        this.client = client;
        this.commandFile = commandFile;
        this.barrier = barrier;
        this.saveReceiver = saveReceiver;
    }

    public void run() {
        ServerSocket serverSocket = openServerSocket();
        System.out.println("[" + mode + "] Warte auf Verbindungen auf Port " + serverPort);
        while (true) {
            try {
                Socket socket = serverSocket.accept();
                Thread connectionThread = new Thread(() -> handleConnection(socket));
                connectionThread.setDaemon(true);
                connectionThread.start();
            } catch (IOException e) {
                System.out.println("[" + mode + "] accept() fehlgeschlagen: " + e.getMessage());
                sleep(1000);
            }
        }
    }

    private ServerSocket openServerSocket() {
        while (true) {
            try {
                return new ServerSocket(serverPort);
            } catch (IOException e) {
                System.out.println("[" + mode + "] Konnte nicht auf Port " + serverPort + " lauschen ("
                        + e.getMessage() + "), neuer Versuch in 1 s");
                sleep(1000);
            }
        }
    }

    private void handleConnection(Socket socket) {
        String peer = socket.getInetAddress().getHostAddress() + ":" + socket.getPort();
        System.out.println("[" + mode + "] Verbindung angenommen: " + peer);
        // ISO-8859-1 bildet jedes Byte 1:1 ab, so kommen Umlaute (cp1252) unveraendert beim Spiel an
        try (BufferedReader in = new BufferedReader(
                new InputStreamReader(socket.getInputStream(), StandardCharsets.ISO_8859_1))) {
            OutputStream out = socket.getOutputStream();
            String line;
            while ((line = in.readLine()) != null) {
                if (line.trim().isEmpty()) {
                    continue;
                }
                if (mode == Mode.incoming && line.startsWith(SaveTransfer.HEADER)) {
                    saveReceiver.receive(line, in);
                    continue;
                }
                handleLine(line, out);
            }
        } catch (IOException e) {
            System.out.println("[" + mode + "] Verbindung " + peer + " verloren: " + e.getMessage());
        } finally {
            try {
                socket.close();
            } catch (IOException e) {
                // bereits geschlossen
            }
        }
        System.out.println("[" + mode + "] Verbindung geschlossen: " + peer);
    }

    private void handleLine(String line, OutputStream out) {
        switch (mode) {
            case proxy:
                if (line.equals(ReadyBarrier.READY)) {
                    barrier.localReady(out);
                    break;
                }
                echoFilter.sent(line);
                client.send(line);
                System.out.println("[proxy] " + line);
                break;
            case incoming:
                if (line.equals(ReadyBarrier.READY)) {
                    barrier.peerReady();
                    break;
                }
                //Prüfen ob es der eigene Command ist der wieder zurückgeschickt wurde
                if (echoFilter.isEcho(line)) {
                    System.out.println("[incoming] Eigener Command ignoriert: " + line);
                } else {
                    commandFile.add(line);
                    System.out.println("[incoming] " + line);
                }
                break;
            case log:
                System.out.println("[log] " + line);
                break;
        }
    }

    static void sleep(long millis) {
        try {
            Thread.sleep(millis);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
