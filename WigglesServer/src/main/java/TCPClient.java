import java.io.IOException;
import java.io.OutputStream;
import java.net.Socket;
import java.nio.charset.StandardCharsets;

/**
 * Verbindung zum incoming-Port des Servers auf der Gegenseite.
 * Bricht sie ab, wird im Hintergrund neu verbunden; Befehle aus dieser Zeit werden verworfen,
 * damit das Spiel nie beim Senden haengen bleibt.
 */
public class TCPClient {

    private final String targetIP;
    private final int targetPort;

    private Socket socket;
    private OutputStream os;
    private boolean reconnecting;

    /** Wartet, bis der Server auf der Gegenseite erreichbar ist. */
    public TCPClient(String targetIP, int targetPort) {
        this.targetIP = targetIP;
        this.targetPort = targetPort;

        System.out.println("[proxy] Verbinde zu " + targetIP + ":" + targetPort + " ...");
        while (!openSocket()) {
            Server.sleep(1000);
        }
    }

    public synchronized void send(String line) {
        if (os == null) {
            System.out.println("[proxy] Nicht verbunden, verworfen: " + line);
            return;
        }
        try {
            os.write((line + "\n").getBytes(StandardCharsets.ISO_8859_1));
            os.flush();
        } catch (IOException e) {
            System.out.println("[proxy] Senden fehlgeschlagen (" + e.getMessage() + "), verbinde neu ...");
            closeSocket();
            startReconnect();
        }
    }

    // Verbindet ausserhalb der Sperre, damit send() waehrenddessen nicht blockiert
    private boolean openSocket() {
        Socket newSocket;
        OutputStream newOs;
        try {
            newSocket = new Socket(targetIP, targetPort);
            newOs = newSocket.getOutputStream();
        } catch (IOException e) {
            return false;
        }
        synchronized (this) {
            socket = newSocket;
            os = newOs;
        }
        System.out.println("[proxy] Verbunden mit " + targetIP + ":" + targetPort);
        return true;
    }

    private synchronized void closeSocket() {
        try {
            if (socket != null) {
                socket.close();
            }
        } catch (IOException e) {
            // bereits geschlossen
        }
        socket = null;
        os = null;
    }

    private synchronized void startReconnect() {
        if (reconnecting) {
            return;
        }
        reconnecting = true;
        Thread reconnectThread = new Thread(() -> {
            while (!openSocket()) {
                Server.sleep(1000);
            }
            synchronized (TCPClient.this) {
                reconnecting = false;
            }
        });
        reconnectThread.setDaemon(true);
        reconnectThread.start();
    }
}
