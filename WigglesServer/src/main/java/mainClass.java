import java.nio.file.Path;
import java.nio.file.Paths;

public class mainClass {

    private static final String USAGE = "Aufruf: java -jar WigglesServer.jar <serverPort> <proxyPort> <targetIP> <targetPort>"
            + " [log | -host <Spielstand|none> | -client <Zieldatei fuer den Spielstand>]";

    //arguments serverPort proxyPort targetIP targetPort [log | -host savegame|none | -client targetfile]
    public static void main(String[] args) {
        // Ohne Argumente (Doppelklick, WigglesMultiplayer.bat) startet der Launcher mit Oberflaeche
        if (args.length == 0) {
            Launcher.main(args);
            return;
        }
        if (args.length < 4) {
            System.out.println(USAGE);
            return;
        }
        int serverPort = Integer.parseInt(args[0]);
        int proxyPort = Integer.parseInt(args[1]);
        String targetIP = args[2];
        int targetPort = Integer.parseInt(args[3]);
        boolean log = false;
        boolean host = false;
        Path hostSave = null;
        Path clientSaveTarget = null;
        for (int i = 4; i < args.length; i++) {
            if (args[i].equals("log")) {
                log = true;
            } else if (args[i].equals("-host") && i + 1 < args.length) {
                host = true;
                String save = args[++i];
                hostSave = save.equals("none") ? null : Paths.get(save);
            } else if (args[i].equals("-client") && i + 1 < args.length) {
                clientSaveTarget = Paths.get(args[++i]);
            } else {
                System.out.println(USAGE);
                return;
            }
        }

        EchoFilter echoFilter = new EchoFilter(1000);

        if (log) {
            System.out.println("Logginmodus aktiviert!");
            new Server(serverPort, Server.Mode.log, echoFilter, null, null, null, null).run();
            return;
        }

        ReadyBarrier barrier = new ReadyBarrier();
        CommandFile commandFile = new CommandFile("remoteCommand");
        startThread(commandFile);
        startThread(new Server(serverPort, Server.Mode.incoming, echoFilter, null, commandFile, barrier,
                new SaveTransfer.Receiver(clientSaveTarget, host)));

        // Der Proxy-Port fuer das Spiel oeffnet erst, wenn die Gegenseite erreichbar ist. Das Spiel
        // wartet beim Start darauf, so sieht der Spieler, dass die Verbindung steht.
        TCPClient client = new TCPClient(targetIP, targetPort);
        barrier.setClient(client);
        if (host) {
            // Der Client startet sein Spiel erst, wenn er weiss, ob und welcher Spielstand geladen wird
            while (!SaveTransfer.send(client, hostSave)) {
                Server.sleep(1000);
            }
        }
        new Server(proxyPort, Server.Mode.proxy, echoFilter, client, null, barrier, null).run();
    }

    private static void startThread(Runnable runnable) {
        Thread thread = new Thread(runnable);
        thread.setDaemon(true);
        thread.start();
    }
}
