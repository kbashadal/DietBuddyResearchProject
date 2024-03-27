import 'package:flutter_dotenv/flutter_dotenv.dart';

Future loadEnv() async {
  // Assuming your .env file is in the root of your project
  // and your Dart code is being run from the project root.
  // Adjust the path as necessary.
  const envPath = 'assets/.env';
  await dotenv.load(fileName: envPath);
  print('Env file path: $envPath');
  print('OPENAI_API_TOKEN: ${dotenv.env['OPENAI_API_TOKEN']}');
  print('Environment variables loaded successfully');
}
