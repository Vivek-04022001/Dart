import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

/*
This code creates an interactive program where the user can type messages, and the program responds based on predefined questions and answers. The processing of these responses happens in a separate isolate, keeping the main thread free to handle user input and output.

*/

void main(List<String> args) async {
  // Initialize the new islate for handling response.
  // Responder class handles the creation and communication with the isolate. It encapsulates all the logic needed to work with the isolate.
  final responder = await Responder.create();

// do-while loop repeatedly prompts the user for input until the user types 'exit'.
  do {
    stdout.write('Say something (or type exit): ');
    final line = stdin.readLineSync(encoding: utf8);
    switch (line?.trim().toLowerCase()) {
      case null:
        continue;
      case 'exit':
        exit(0);
      default:
        final msg = await responder.getMessage(line!);
        print(msg);
    }
  } while (true);
}

class Responder {
  final ReceivePort rp; // Used to receive the messages from the isolate.
  final Stream<dynamic>
      broadcastRp; // Broadcast stream to ReceivePort for multiple subscriptions.
  final SendPort
      communicatorSendPort; // SendPort to send messages to the Isolate.

  Responder({
    required this.rp,
    required this.broadcastRp,
    required this.communicatorSendPort,
  });

  static Future<Responder> create() async {
    final rp = ReceivePort();
    // Spawns a new isolate and runs the _communicator function in it. The rp.sendPort is passed to the isolate so it can communicate with the main thread.
    Isolate.spawn(
      _communicator,
      rp.sendPort,
    );

//broadcastRp.first waits for the first message from the isolate, which is the SendPort for communication with the isolate.
    final broadcastRp = rp.asBroadcastStream();
    final SendPort communicatorSendPort = await broadcastRp.first;

    return Responder(
      rp: rp,
      broadcastRp: broadcastRp,
      communicatorSendPort: communicatorSendPort,
    );
  }

  Future<String> getMessage(String forGreeting) async {
    // Sends the user's input to the isolate.
    communicatorSendPort.send(forGreeting);

    return broadcastRp
        .takeWhile(
            (element) => element is String) // filters for string messages
        .cast<String>() // Casts messages to String
        .take(1) // Take the first matching messsage
        .first; // returns it as a future
  }
}

void _communicator(SendPort sp) async {
  final rp = ReceivePort(); // Create a ReceivePort for this isolate.
  sp.send(rp.sendPort); // Send the isolate's SendPort to the  main isolate

// Listen for String messages.
  final messages = rp.takeWhile((element) => element is String).cast<String>();

  await for (final message in messages) {
    for (final entry in messagesAndResponses.entries) {
      if (entry.key.trim().toLowerCase() == message.trim().toLowerCase()) {
        sp.send(entry
            .value); // Send the corresponding response back to the main isolate.
        continue;
      }
    }
  }
}

const messagesAndResponses = {
  '': 'Ask me a question like "How are you?"',
  'Hello': 'Hi',
  'How are you?': 'Fine',
  'What are you doing?': 'Learning about Isolates in Dart!',
  'Are you having fun?': 'Yeah sure!',
};
