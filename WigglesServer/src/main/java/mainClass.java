public class mainClass {

    //arguments serverPort proxyPort targetIP targetPort log
    public static void main(String[] args) {
        if (args.length < 4) {
            System.out.println("Aufruf: java -jar WigglesServer.jar <serverPort> <proxyPort> <targetIP> <targetPort> [log]");
            return;
        }
        int serverPort = Integer.parseInt(args[0]);
        int proxyPort = Integer.parseInt(args[1]);
        String targetIP = args[2];
        int targetPort = Integer.parseInt(args[3]);
        boolean log = args.length > 4 && args[4].equals("log");

        EchoFilter echoFilter = new EchoFilter(1000);

        if (log) {
            System.out.println("Logginmodus aktiviert!");
            new Server(serverPort, Server.Mode.log, echoFilter, null, null).run();
            return;
        }

        CommandFile commandFile = new CommandFile("remoteCommand");
        startThread(commandFile);
        startThread(new Server(serverPort, Server.Mode.incoming, echoFilter, null, commandFile));

        // Der Proxy-Port fuer das Spiel oeffnet erst, wenn die Gegenseite erreichbar ist. Das Spiel
        // wartet beim Start darauf, so sieht der Spieler, dass die Verbindung steht.
        TCPClient client = new TCPClient(targetIP, targetPort);
        new Server(proxyPort, Server.Mode.proxy, echoFilter, client, null).run();
    }

    private static void startThread(Runnable runnable) {
        Thread thread = new Thread(runnable);
        thread.setDaemon(true);
        thread.start();
    }
}
