import java.io.IOException;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;

/**
 * Sorgt dafuer, dass beide Spiele gleichzeitig loslegen.
 *
 * Das Spiel meldet nach dem Laden in setupmpconnection.tcl "#MPREADY" an seinen Server und wartet auf
 * "#MPGO". Der Server gibt die Meldung an den Mitspieler weiter und antwortet erst, wenn beide Spiele
 * bereit sind. Das Spiel wiederholt die Meldung regelmaessig, verlorene Meldungen sind also kein Problem.
 */
public class ReadyBarrier {

    static final String READY = "#MPREADY";
    static final String GO = "#MPGO";

    private TCPClient client;
    private boolean localReady;
    private boolean peerReady;
    private boolean announced;
    private final List<OutputStream> waiting = new ArrayList<>();

    synchronized void setClient(TCPClient client) {
        this.client = client;
    }

    /** Das eigene Spiel ist geladen und wartet auf die Antwort ueber game. */
    void localReady(OutputStream game) {
        TCPClient peer;
        synchronized (this) {
            if (!localReady) {
                System.out.println("[sync] Eigenes Spiel bereit, warte auf den Mitspieler");
            }
            localReady = true;
            waiting.add(game);
            peer = client;
        }
        if (peer != null) {
            peer.trySend(READY, false);
        }
        release();
    }

    /** Das Spiel des Mitspielers ist bereit. */
    void peerReady() {
        TCPClient answerTo = null;
        synchronized (this) {
            // Einmal antworten, falls der Mitspieler unsere Meldung verpasst hat, als er noch nicht verbunden war
            if (!peerReady && localReady) {
                answerTo = client;
            }
            peerReady = true;
        }
        if (answerTo != null) {
            answerTo.trySend(READY, false);
        }
        release();
    }

    private void release() {
        List<OutputStream> games;
        synchronized (this) {
            if (!localReady || !peerReady) {
                return;
            }
            games = new ArrayList<>(waiting);
            waiting.clear();
            if (!announced) {
                announced = true;
                System.out.println("[sync] Beide Spiele bereit, Start");
            }
        }
        for (OutputStream game : games) {
            try {
                game.write((GO + "\n").getBytes(StandardCharsets.ISO_8859_1));
                game.flush();
            } catch (IOException e) {
                // Das Spiel hat die Verbindung schon geschlossen und fragt erneut
            }
        }
    }
}
