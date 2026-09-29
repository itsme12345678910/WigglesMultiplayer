import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

/**
 * Uebergibt empfangene Befehle an das eigene Spiel ueber die Datei "remoteCommand" im Spielordner.
 *
 * Die tcl83.dll liest die Datei beim naechsten Tcl_EvalEx komplett ein, fuehrt sie aus und loescht sie.
 * Damit dabei nichts verloren geht oder doppelt ausgefuehrt wird, wird die Datei nie beschrieben,
 * solange sie existiert: Neue Befehle werden gesammelt und erst, wenn das Spiel die vorige Datei
 * abgeholt hat, per Umbenennen als vollstaendige neue Datei bereitgestellt.
 */
public class CommandFile implements Runnable {

    private final Path target;
    private final Path temp;
    private final StringBuilder pending = new StringBuilder();

    public CommandFile(String fileName) {
        target = Paths.get(fileName);
        temp = Paths.get(fileName + ".tmp");
        // Reste einer frueheren Sitzung wuerde das Spiel sonst beim naechsten Start ausfuehren
        try {
            Files.deleteIfExists(target);
            Files.deleteIfExists(temp);
        } catch (IOException e) {
            System.out.println("[incoming] Alte Befehlsdatei nicht loeschbar: " + e.getMessage());
        }
    }

    public synchronized void add(String line) {
        pending.append(line).append('\n');
        notifyAll();
    }

    public void run() {
        while (true) {
            String batch = takeBatchWhenGameIsReady();
            try {
                // Nur \n als Zeilenende: die DLL liest im Textmodus und rechnet mit der Dateigroesse
                Files.write(temp, batch.getBytes(StandardCharsets.ISO_8859_1));
                // Ohne REPLACE_EXISTING: schlaegt fehl, falls die Datei doch existiert
                Files.move(temp, target);
            } catch (IOException e) {
                System.out.println("[incoming] FEHLER: Kann " + target + " nicht schreiben: " + e);
                putBack(batch);
                Server.sleep(100);
            }
        }
    }

    // Wartet auf neue Befehle und darauf, dass das Spiel die vorige Datei abgeholt hat
    private String takeBatchWhenGameIsReady() {
        while (true) {
            synchronized (this) {
                while (pending.length() == 0) {
                    try {
                        wait();
                    } catch (InterruptedException e) {
                        Thread.currentThread().interrupt();
                    }
                }
                if (!Files.exists(target)) {
                    String batch = pending.toString();
                    pending.setLength(0);
                    return batch;
                }
            }
            Server.sleep(5);
        }
    }

    private synchronized void putBack(String batch) {
        pending.insert(0, batch);
    }
}
