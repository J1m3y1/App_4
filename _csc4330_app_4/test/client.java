import io.socket.client.Ack;
import io.socket.client.IO;
import io.socket.client.Socket;
import org.json.JSONObject;

import java.util.Locale;
import java.util.Scanner;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;

public class Client {
    private static JSONObject emitWithAck(Socket socket, String event, JSONObject payload)
            throws Exception {
        CountDownLatch acknowledgement = new CountDownLatch(1);
        AtomicReference<JSONObject> response = new AtomicReference<>();
        AtomicReference<Exception> parseError = new AtomicReference<>();

        socket.emit(event, payload, new Ack() {
            @Override
            public void call(Object... args) {
                try {
                    if (args.length == 0 || args[0] == null) {
                        throw new IllegalStateException("The server returned an empty response");
                    }
                    response.set(new JSONObject(args[0].toString()));
                } catch (Exception error) {
                    parseError.set(error);
                } finally {
                    acknowledgement.countDown();
                }
            }
        });

        if (!acknowledgement.await(8, TimeUnit.SECONDS)) {
            throw new IllegalStateException("Timed out waiting for the server response");
        }
        if (parseError.get() != null) throw parseError.get();

        JSONObject result = response.get();
        if (!result.optBoolean("ok")) {
            JSONObject error = result.optJSONObject("error");
            throw new IllegalStateException(
                    error == null ? "The server rejected the request" : error.optString("message"));
        }
        return result;
    }

    private static JSONObject readSession(Scanner input, Socket socket) throws Exception {
        System.out.print("Create or join a game? [c/j]: ");
        String choice = input.nextLine().trim().toLowerCase(Locale.ROOT);
        if (choice.equals("c")) {
            return emitWithAck(socket, "create_game", new JSONObject());
        }
        if (choice.equals("j")) {
            System.out.print("Room code: ");
            String roomCode = input.nextLine().trim().toUpperCase(Locale.ROOT);
            JSONObject session = emitWithAck(
                    socket,
                    "join_game",
                    new JSONObject().put("roomCode", roomCode));
            return session.put("roomCode", roomCode);
        }
        throw new IllegalArgumentException("Enter c to create a game or j to join one");
    }

    public static void main(String[] args) throws Exception {
        Socket socket = IO.socket("http://localhost:3000");
        CountDownLatch connected = new CountDownLatch(1);

        socket.on(Socket.EVENT_CONNECT, argsFromSocket -> {
            System.out.println("Connected to the Gomoku server.");
            connected.countDown();
        });
        socket.on(Socket.EVENT_CONNECT_ERROR, argsFromSocket -> {
            System.err.println("Could not connect to http://localhost:3000: " + argsFromSocket[0]);
        });
        socket.on("player_joined", argsFromSocket ->
                System.out.println("Player joined: " + argsFromSocket[0]));
        socket.on("move_made", argsFromSocket ->
                System.out.println("Move update: " + argsFromSocket[0]));
        socket.on("game_over", argsFromSocket ->
                System.out.println("Game over: " + argsFromSocket[0]));
        socket.on("player_disconnected", argsFromSocket ->
                System.out.println("Player disconnected: " + argsFromSocket[0]));

        socket.connect();
        if (!connected.await(10, TimeUnit.SECONDS)) {
            socket.disconnect();
            throw new IllegalStateException("Timed out connecting to the server");
        }

        try (Scanner input = new Scanner(System.in)) {
            JSONObject session = readSession(input, socket);
            String roomCode = session.optString("roomCode");
            if (roomCode.isEmpty()) {
                System.out.println("Joined room using the supplied code.");
            } else {
                System.out.println("Room code: " + roomCode);
            }
            System.out.println("You are " + session.getString("color") + ".");
            System.out.println("Enter: move <row> <column>, resign, or quit. Coordinates start at 0.");

            while (input.hasNextLine()) {
                System.out.print("> ");
                String[] command = input.nextLine().trim().split("\\s+");
                if (command.length == 0 || command[0].isEmpty()) continue;
                if (command[0].equalsIgnoreCase("quit")) break;

                if (command[0].equalsIgnoreCase("resign")) {
                    emitWithAck(socket, "resign", new JSONObject()
                            .put("roomCode", roomCode)
                            .put("playerToken", session.getString("playerToken")));
                    continue;
                }

                if (command.length == 3 && command[0].equalsIgnoreCase("move")) {
                    try {
                        JSONObject move = new JSONObject()
                                .put("roomCode", roomCode)
                                .put("playerToken", session.getString("playerToken"))
                                .put("row", Integer.parseInt(command[1]))
                                .put("col", Integer.parseInt(command[2]));
                        emitWithAck(socket, "move", move);
                    } catch (NumberFormatException error) {
                        System.out.println("Rows and columns must be whole numbers.");
                    } catch (IllegalStateException error) {
                        System.out.println(error.getMessage());
                    }
                    continue;
                }

                System.out.println("Use: move <row> <column>, resign, or quit.");
            }
        } finally {
            socket.disconnect();
        }
    }
}