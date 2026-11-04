import 'dart:io';
import 'package:path/path.dart' as p;

void main() async {
  final webDir = Directory(p.join(Directory.current.path, 'build', 'web'));
  if (!webDir.existsSync()) {
    stdout.writeln('Error: build/web directory not found!');
    return;
  }

  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 5050);
  stdout.writeln('====================================================');
  stdout.writeln('Mobile Wholesale ERP Web Server Running!');
  stdout.writeln('URL: http://127.0.0.1:5050');
  stdout.writeln('====================================================');

  await for (HttpRequest request in server) {
    try {
      var reqPath = request.uri.path;
      if (reqPath == '/' || reqPath.isEmpty) {
        reqPath = '/index.html';
      }
      var filePath = p.join(webDir.path, reqPath.startsWith('/') ? reqPath.substring(1) : reqPath);
      var file = File(filePath);
      if (!await file.exists()) {
        file = File(p.join(webDir.path, 'index.html'));
      }

      final ext = p.extension(file.path).toLowerCase();
      final contentType = switch (ext) {
        '.html' => ContentType.html,
        '.js' => ContentType('application', 'javascript', charset: 'utf-8'),
        '.wasm' => ContentType('application', 'wasm'),
        '.json' => ContentType.json,
        '.png' => ContentType('image', 'png'),
        '.jpg' || '.jpeg' => ContentType('image', 'jpeg'),
        '.css' => ContentType('text', 'css', charset: 'utf-8'),
        '.ttf' => ContentType('font', 'ttf'),
        '.otf' => ContentType('font', 'otf'),
        _ => ContentType.binary,
      };

      request.response.headers.contentType = contentType;
      await file.openRead().pipe(request.response);
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();
    }
  }
}
