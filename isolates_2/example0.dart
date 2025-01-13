import 'dart:isolate';

void main() async {
  // 1. Create a ReceivePort to receive messages from the spawned isolate
  ReceivePort rp = ReceivePort();

  // 2. Spawn an isolate and pass the SendPort of the ReceivePort to the isolate
  // The isolate will run the computeTask function
  await Isolate.spawn(computeTask, rp.sendPort);

  // 3. Listen to the messages from the spawned isolate
  // When a message is received, print it and close the ReceivePort
  rp.listen((message) {
    print('Message from isolate: $message');
    rp.close();
  });
}

// This function will be run in a separate isolate
void computeTask(SendPort sp) async {
  int sum = 0;
  // Compute the sum of the first 10,000,000 integers
  for (int i = 0; i < 10000000; i++) {
    sum += i;
  }

  // Send the result back to the main isolate
  sp.send('Sum: $sum');
}
