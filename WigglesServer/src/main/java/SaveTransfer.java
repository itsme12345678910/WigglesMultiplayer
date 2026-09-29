import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.Arrays;
import java.util.Base64;
import java.util.zip.CRC32;

/**
 * Uebertraegt den Spielstand des Hosts an den Client, ueber dieselbe Verbindung wie die Befehle.
 *
 * Protokoll (zeilenweise):
 *   #MPSAVE none              der Host hat keinen Spielstand gewaehlt
 *   #MPSAVE <Groesse>         danach Base64-Zeilen mit dem Inhalt,
 *   #MPSAVE_END <CRC32 hex>   zum Schluss die Pruefsumme
 */
public final class SaveTransfer {

    static final String HEADER = "#MPSAVE ";
    static final String NONE = HEADER + "none";
    static final String END = "#MPSAVE_END ";
    private static final int CHUNK = 48 * 1024;

    private SaveTransfer() {
    }

    /**
     * Host: schickt den Spielstand (null = keiner) an den Mitspieler.
     *
     * @return false, wenn die Verbindung dabei abgebrochen ist; dann spaeter erneut versuchen
     */
    static boolean send(TCPClient client, Path file) {
        if (file == null) {
            if (!client.trySend(NONE, false)) {
                return false;
            }
            System.out.println("[save] Kein Spielstand gewaehlt, der Mitspieler startet mit dem Hauptmenue");
            return true;
        }
        long size;
        try {
            size = Files.size(file);
        } catch (IOException e) {
            System.out.println("[save] FEHLER: Spielstand " + file + " nicht lesbar: " + e.getMessage());
            return client.trySend(NONE, false);
        }
        System.out.println("[save] Sende Spielstand " + file.getFileName() + " (" + size / 1024 + " KB)");
        CRC32 crc = new CRC32();
        try (InputStream in = Files.newInputStream(file)) {
            if (!client.trySend(HEADER + size, false)) {
                return false;
            }
            byte[] buffer = new byte[CHUNK];
            int read;
            while ((read = in.read(buffer)) > 0) {
                crc.update(buffer, 0, read);
                String line = Base64.getEncoder().encodeToString(Arrays.copyOf(buffer, read));
                if (!client.trySend(line, false)) {
                    return false;
                }
            }
        } catch (IOException e) {
            System.out.println("[save] FEHLER beim Lesen von " + file + ": " + e.getMessage());
            return false;
        }
        if (!client.trySend(END + Long.toHexString(crc.getValue()), false)) {
            return false;
        }
        System.out.println("[save] Spielstand gesendet");
        return true;
    }

    /** Nimmt einen Spielstand vom Mitspieler entgegen. */
    static class Receiver {

        private final Path target;
        private final boolean isHost;

        /**
         * @param target Zieldatei beim Client, null beim Host oder ohne Rolle (Spielstaende werden verworfen)
         * @param isHost true beim Host: ein ankommender Spielstand heisst, dass beide Host sind
         */
        Receiver(Path target, boolean isHost) {
            this.target = target;
            this.isHost = isHost;
        }

        /** Liest nach der Kopfzeile den Rest der Uebertragung aus in. */
        void receive(String header, BufferedReader in) throws IOException {
            String argument = header.substring(HEADER.length()).trim();
            if (argument.equals("none")) {
                if (target != null) {
                    System.out.println("[save] Kein Spielstand vom Host, Start mit dem Hauptmenue");
                } else if (isHost) {
                    warnBothHost();
                }
                return;
            }
            if (target == null) {
                if (isHost) {
                    warnBothHost();
                }
                skipTransfer(in);
                return;
            }
            long size;
            try {
                size = Long.parseLong(argument);
            } catch (NumberFormatException e) {
                System.out.println("[save] FEHLER: ungueltige Kopfzeile: " + header);
                skipTransfer(in);
                return;
            }
            Files.createDirectories(target.toAbsolutePath().getParent());
            Path temp = target.resolveSibling(target.getFileName() + ".part");
            CRC32 crc = new CRC32();
            long received = 0;
            int lastTenth = -1;
            boolean complete = false;
            try (OutputStream out = Files.newOutputStream(temp)) {
                String line;
                while ((line = in.readLine()) != null) {
                    if (line.startsWith(END)) {
                        String expected = line.substring(END.length()).trim();
                        complete = received == size && expected.equalsIgnoreCase(Long.toHexString(crc.getValue()));
                        break;
                    }
                    byte[] data;
                    try {
                        data = Base64.getDecoder().decode(line);
                    } catch (IllegalArgumentException e) {
                        break;
                    }
                    out.write(data);
                    crc.update(data);
                    received += data.length;
                    int percent = size == 0 ? 100 : (int) (received * 100 / size);
                    if (percent / 10 != lastTenth) {
                        lastTenth = percent / 10;
                        System.out.println("[save] Empfange Spielstand " + percent + "%");
                    }
                }
            }
            if (!complete) {
                Files.deleteIfExists(temp);
                System.out.println("[save] FEHLER: Spielstand unvollstaendig oder beschaedigt empfangen");
                return;
            }
            Files.move(temp, target, StandardCopyOption.REPLACE_EXISTING);
            System.out.println("[save] Spielstand empfangen: " + target + " (" + size / 1024 + " KB)");
        }

        private static void skipTransfer(BufferedReader in) throws IOException {
            String line;
            while ((line = in.readLine()) != null && !line.startsWith(END)) {
                // verwerfen
            }
        }

        private static void warnBothHost() {
            System.out.println("[save] WARNUNG: Der Mitspieler ist auch Host. Genau ein Spieler muss Host sein.");
        }
    }
}
