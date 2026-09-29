import java.util.LinkedList;

/**
 * Merkt sich die zuletzt an die Gegenseite gesendeten Befehle.
 *
 * Fuehrt die Gegenseite einen empfangenen Befehl aus, schicken ihre Scripts ihn zurueck. Dieses Echo
 * darf hier nicht erneut ausgefuehrt werden, sonst pendeln Befehle endlos hin und her. Jeder gesendete
 * Befehl hebt genau ein Echo auf, so wird ein spaeter legitim wiederholter gleicher Befehl nicht verworfen.
 * Es werden mehrere Befehle gemerkt, weil zwischen Befehl und Echo weitere Befehle gesendet werden
 * koennen (z. B. Zufallsbewegungen vom Host, die nie zurueckkommen).
 */
public class EchoFilter {

    private final LinkedList<String> sentLines = new LinkedList<>();
    private final int capacity;

    public EchoFilter(int capacity) {
        this.capacity = capacity;
    }

    public synchronized void sent(String line) {
        sentLines.addLast(line);
        if (sentLines.size() > capacity) {
            sentLines.removeFirst();
        }
    }

    /** Liefert true und vergisst den Befehl, wenn line das Echo eines gesendeten Befehls ist. */
    public synchronized boolean isEcho(String line) {
        return sentLines.remove(line);
    }
}
