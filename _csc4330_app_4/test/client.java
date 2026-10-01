import java.io.DataOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.net.socket;

public class Client{
    public static void main(String [] args) throws IOException{
        Socket socket = new Socket("localhost", 12345);
        System.out.println("Connected!!");

        OutputStream outputStream = socket.getOutputStream();
        DataOutputStream dataOutputStream = new DataOutputStream(outputStream);
        System.out.println("Sending message to server...");

        dataOutputStream.writeUTF("Hello from client!");
        dataOutputStream.flush();

        dataOutputStream.close()
        System.out.println("Closing socket and terminating program...");
        socket.close()
    }

}