import 'dart:isolate';

void main(List<String> args) async {
  // Example usage of getMessages function
  await for (final message in getMessages()) {
    print('Message from isolate: $message');
  }
}

// Function to get messages from an isolate
Stream<String> getMessages() {
  // Create a ReceivePort to receive messages from the spawned isolate
  final rp = ReceivePort();

  // Spawn an isolate and pass the SendPort of the ReceivePort to the isolate
  // The isolate will run the _getMessages function
  return Isolate.spawn(_getMessages, rp.sendPort)
      .asStream()
      .asyncExpand((_) =>
          rp) // Expand the stream to include messages from the ReceivePort
      .takeWhile((element) =>
          element is String) // Take messages while they are of type String
      .cast(); // Cast the stream to a Stream<String>
}

// This function will be run in a separate isolate
void _getMessages(SendPort sp) async {
  // Periodically send the current date and time as a string to the main isolate
  await for (final now in Stream.periodic(
    Duration(milliseconds: 1000), // Every 1 second
    (_) => DateTime.now()
        .toIso8601String(), // Get the current date and time as a string
  )) {
    sp.send(now); // Send the current date and time to the main isolate
  }
}
