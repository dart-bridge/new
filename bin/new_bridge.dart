import 'dart:io';
import 'dart:async';

enum Color {
  blue,
  red,
  yellow,
  gray,
}

int _colorId(Color color) => {
  Color.blue: 34,
  Color.red: 31,
  Color.yellow: 33,
  Color.gray: 90,
}[color];

String _colorize(String input, Color color) {
  return '\u001b[${_colorId(color)}m$input\u001b[39m';
}

void output(String input, Color color) {
  stdout.write(_colorize(input, color));
}

StreamSubscription _progressSubscription;

void _progress() {
  _progressSubscription = new Stream.periodic(const Duration(seconds: 1)).listen((_) {
    output('.', Color.yellow);
  });
}

void _endProgress() {
  _progressSubscription.cancel();
  stdout.write('\n');
}

main(List<String> arguments) async {

  if (arguments.length != 1) {
    output('Usage: new-bridge <folder-name>\n', Color.red);
    exit(1);
  }

  var name = arguments[0];

  output('Creating $name...\n', Color.blue);

  var result = await Process.run('git', [
    'clone',
    'git://github.com/dart-bridge/bridge',
    name,
  ]);

  if (result.exitCode != 0) {
    output('${result.stderr}\n', Color.red);
    exit(1);
  }

  Directory.current = name;

  try {
    await new Directory('.git').delete(recursive: true);
  } catch (e) {
    output('$e\n', Color.red);
    exit(1);
  }

  output('Getting dependencies', Color.blue);

  _progress();

  try {
    await Process.run('pub', ['get']);
  } catch (e) {
    output('\n••• Couldn\'t run pub get', Color.yellow);
  }

  _endProgress();

  try {
    var pubspec = new File('.gitignore');
    var contents = pubspec.readAsStringSync();
    pubspec.writeAsStringSync(contents.replaceFirst('\npubspec.lock', ''));
  } catch (e) {
    output('••• Couldn\'t edit .gitignore\n', Color.yellow);
  }

  try {
    await new File('.env.development').copy('.env');
  } catch (e) {
    output('••• Couldn\'t copy .env.development to .env\n', Color.yellow);
  }

  output('We\'re in business!\n', Color.blue);
  output('Hint: cd $name && dart bridge start\n', Color.gray);
}