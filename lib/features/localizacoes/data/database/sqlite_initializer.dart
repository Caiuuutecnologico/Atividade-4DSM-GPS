import 'sqlite_initializer_stub.dart'
    if (dart.library.io) 'sqlite_initializer_io.dart'
    if (dart.library.js_interop) 'sqlite_initializer_web.dart'
    as platform;

Future<void> initializeSqliteFactory() => platform.initializeSqliteFactory();
