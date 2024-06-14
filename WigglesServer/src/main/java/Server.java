import java.io.*;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.List;

public class Server implements Runnable {

    public enum Mode {
        proxy, incoming, log
    }

    private int serverPort;
    private Mode mode;
    private List commandList;
    private String targetIP;
    private int targetPort;
    TCPClient client;

    public void run(){
        try {
            ServerSocket serverSocket = new ServerSocket(serverPort);
            Socket socket = serverSocket.accept();
            String cCommand = "";
            while (!socket.isClosed()) {
                InputStream input = socket.getInputStream();
                BufferedInputStream bin = new BufferedInputStream(input);
                while (bin.available() > 0) {
                    cCommand = cCommand + (char) bin.read();
                }
                if (cCommand != "" && mode == Mode.incoming) {
                    //Prüfen ob es der eigene Command ist der wieder zurückgeschickt wurde
                    if(!commandList.contains(cCommand)) {
                        createCommandFile(cCommand);
                    }
                    //Files.move(Paths.get("C:/Program Files (x86)/GOG Galaxy/Games/Diggles The Myth of Fenris/lager/remoteCommand"), Paths.get("C:/Program Files (x86)/GOG Galaxy/Games/Diggles The Myth of Fenris/remoteCommand"), StandardCopyOption.REPLACE_EXISTING);
                }
                System.out.print(cCommand);
                if(cCommand != "" && mode == Mode.proxy){
                    if(!commandList.isEmpty())commandList.remove(0);
                    commandList.add(cCommand);
                    client.send(cCommand);
                }
                cCommand = "";
            }
        } catch (Exception e){

        }
        run();
    }

    public Server(int serverPort, Mode mode, List commandList, String targetIP, int targetPort) throws Exception{
        this.serverPort = serverPort;
        this.mode = mode;
        this. commandList = commandList;
        this.targetIP = targetIP;
        this.targetPort = targetPort;
        if(mode == Mode.proxy)
        client = new TCPClient(targetIP, targetPort);
    }

    public boolean createCommandFile(String command) throws Exception {
        String fileLocation = "remoteCommand";
        File commandFile = new File(fileLocation);
        if(!commandFile.createNewFile()){
            commandFile.delete();
            commandFile.createNewFile();
        }
        PrintWriter out = new PrintWriter(fileLocation);
        out.println(command);
        out.close();
        return true;
    }
}
