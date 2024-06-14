import java.io.InputStream;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.OutputStream;
import java.net.Socket;

public class TCPClient {

    private String targetIP;
    private int targetPort;

    private Socket socket;
    private OutputStream os;
    private InputStream is;

    public void send(String msg) throws Exception{
        os.write(msg.getBytes());
        os.flush();

        /* close resources
        ois.close();
        oos.close();
        socket.close(); */
    }

    public TCPClient(String targetIP, int targetPort){
        this.targetIP = targetIP;
        this.targetPort = targetPort;

        while(!openSocket()){
        }
    }

    public boolean openSocket() {
        try {
            socket = new Socket(targetIP, targetPort);
            os = socket.getOutputStream();
            is = socket.getInputStream();
        } catch (Exception e){
            return false;
        }
        return true;
    }
}