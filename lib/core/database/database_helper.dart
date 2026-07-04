import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'seed_data.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = await getDatabasePath();
    return await openDatabase(
      path,
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<String> getDatabasePath() async {
    return join(await getDatabasesPath(), 'inventario.db');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 6) {
      // Recrear tablas completas por el cambio en serialNumber y currency
      await db.execute('DROP TABLE IF EXISTS movements');
      await db.execute('DROP TABLE IF EXISTS products');
      await db.execute('DROP TABLE IF EXISTS categories');
      await db.execute('DROP TABLE IF EXISTS warehouses');
      await db.execute('DROP TABLE IF EXISTS projects');
      await db.execute('DROP TABLE IF EXISTS users');
      
      await _onCreate(db, newVersion);
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabla Usuarios
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        isActive INTEGER DEFAULT 1,
        is_synced INTEGER DEFAULT 0,
        last_updated TEXT
      )
    ''');

    // Tabla Categorías
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        isActive INTEGER DEFAULT 1,
        is_synced INTEGER DEFAULT 0,
        last_updated TEXT
      )
    ''');

    // Tabla Almacenes
    await db.execute('''
      CREATE TABLE warehouses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        location TEXT,
        isActive INTEGER DEFAULT 1,
        is_synced INTEGER DEFAULT 0,
        last_updated TEXT
      )
    ''');

    // Tabla Proyectos
    await db.execute('''
      CREATE TABLE projects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        startDate TEXT,
        endDate TEXT,
        status TEXT,
        is_synced INTEGER DEFAULT 0,
        last_updated TEXT
      )
    ''');

    // Tabla Productos
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE NOT NULL,
        serialNumber TEXT UNIQUE,
        name TEXT NOT NULL,
        categoryId INTEGER,
        stock INTEGER DEFAULT 0,
        minStock INTEGER DEFAULT 0,
        unit TEXT,
        price REAL DEFAULT 0.0,
        currency TEXT DEFAULT 'PEN',
        isActive INTEGER DEFAULT 1,
        is_synced INTEGER DEFAULT 0,
        last_updated TEXT,
        FOREIGN KEY (categoryId) REFERENCES categories (id)
      )
    ''');

    // Tabla Movimientos
    await db.execute('''
      CREATE TABLE movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER NOT NULL,
        warehouseId INTEGER NOT NULL,
        projectId INTEGER,
        userId INTEGER NOT NULL,
        type TEXT NOT NULL, 
        quantity INTEGER NOT NULL,
        date TEXT NOT NULL,
        notes TEXT,
        is_synced INTEGER DEFAULT 0,
        last_updated TEXT,
        FOREIGN KEY (productId) REFERENCES products (id),
        FOREIGN KEY (warehouseId) REFERENCES warehouses (id),
        FOREIGN KEY (projectId) REFERENCES projects (id),
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Insertar datos de prueba base (Admin user)
    await db.execute('''
      INSERT INTO users (name, email, password, role) 
      VALUES ('Admin', 'admin@test.com', '123', 'admin')
    ''');
    
    // Sembrar datos de prueba para nuevas instalaciones
    await insertSeedData(db);
  }
}
