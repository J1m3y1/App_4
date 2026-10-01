import io.socket.client.Ack;
import io.socket.client.IO;
import io.socket.client.Socket;
import io.socket.emitter.Emitter;
import org.json.JSONObject;

public class Client{
    public static void main(String[] args) throws Exception {
        Socket socket = IO.socket("http://localhost:3000");

        socket.on(Socket.EVENT_CONNECT, new Emitter.Listener() {
            @Override
            public void call(Object... args) {
                System.out.println("Connected to the Gomoku server.");
                socket.emit("create_game", new JSONObject(), new Ack() {
                    @Override
                    public void call(Object... response) {
                        System.out.println("Server response: " + response[0]);
                        socket.disconnect();
                    }
                });
            }
        });

        socket.on(Socket.EVENT_CONNECT_ERROR, new Emitter.Listener() {
            @Override
            public void call(Object... args) {
                System.err.println("Could not connect to http://localhost:3000: " + args[0]);
                socket.disconnect();
            }
        });

        socket.connect();
    }
}