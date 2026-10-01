import java.io.DataInputStream;
import java.ioIOException;
import java.io.InputStream;
import java.net.ServerSocket;
import java.net.socket;

public class Server {
    public static void main(String [] args) throws IOException{
        ServerSocket serverSocket = new ServerSocket(12345);
        System.out.println("Server is awaiting connections...")

        Socket socket = serverSocket.accept();
        System.out.println("Client connected: " + socket.getInetAddress().getHostAddress()); //DIFF

        InputStream inputStream = socket.getInputStream();
        DataInputStream dataInputStream = new DataInputStream(inputStream);

        String message = dataInputStream.readUTF();
        System.out.println("Received message from client:" + message);

        System.out.println("Closing connection...");
        serverSocket.close();

    }
}