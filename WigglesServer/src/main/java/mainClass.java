import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class mainClass {

    //arguments serverPort proxyPort targetIP targetPort log
    public static void main(String[] args){

        List<String> commandList = Collections.synchronizedList(new ArrayList<String>());

        boolean log = false;

        try{
            String logStat = args[4];
            if(logStat.equals("log"))
            log = true;
        } catch (Exception e){

        }

        try {
            if(!log) {
                Server incoming = new Server(Integer.valueOf(args[0]), Server.Mode.incoming, commandList, args[2], Integer.valueOf(args[3]));
                Thread incomingThread = new Thread(incoming);
                incomingThread.start();
                Server proxy = new Server(Integer.valueOf(args[1]), Server.Mode.proxy, commandList, args[2], Integer.valueOf(args[3]));
                Thread proxyThread = new Thread(proxy);
                proxyThread.start();
            } else {
                System.out.println("Logginmodus aktiviert!");
                Server logging = new Server(Integer.valueOf(args[0]), Server.Mode.log, commandList, args[2], Integer.valueOf(args[3]));
                logging.run();
            }
        } catch (Exception e){
            System.out.println(e);
        }
    }

}
