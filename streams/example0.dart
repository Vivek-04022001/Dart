void main() async {
  await for (final number in numbers()) {
    print(number);
  }
}

Stream<int> numbers() async* {
  for (int i = 1; i <= 5000; i++) {
    await Future.delayed(Duration(milliseconds: 10));
    yield i;
  }
}
