import * as SQLite from 'expo-sqlite';
import { mockProducts } from '../data/mockInventory';

export async function initDatabase(db: SQLite.SQLiteDatabase) {
  // Crear tablas (preparadas para sync offline-first)
  await db.execAsync(`
    PRAGMA journal_mode = WAL;
    
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL,
      role TEXT NOT NULL,
      active INTEGER DEFAULT 1,
      sync_status TEXT DEFAULT 'pending'
    );

    CREATE TABLE IF NOT EXISTS categories (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      sync_status TEXT DEFAULT 'pending'
    );

    CREATE TABLE IF NOT EXISTS warehouses (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      sync_status TEXT DEFAULT 'pending'
    );

    CREATE TABLE IF NOT EXISTS products (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      category_id TEXT,
      warehouse_id TEXT,
      barcode TEXT,
      unit TEXT,
      stock REAL DEFAULT 0,
      min_stock REAL DEFAULT 0,
      currency TEXT,
      unit_cost REAL DEFAULT 0,
      sync_status TEXT DEFAULT 'pending'
    );

    CREATE TABLE IF NOT EXISTS projects (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      client TEXT,
      sync_status TEXT DEFAULT 'pending'
    );

    CREATE TABLE IF NOT EXISTS movements (
      id TEXT PRIMARY KEY,
      type TEXT NOT NULL,
      product_id TEXT NOT NULL,
      quantity REAL NOT NULL,
      warehouse_id TEXT,
      project_id TEXT,
      user_id TEXT,
      date TEXT NOT NULL,
      sync_status TEXT DEFAULT 'pending'
    );
  `);

  // Seed de datos
  const productCount = await db.getFirstAsync<{count: number}>('SELECT COUNT(*) as count FROM products');
  if (productCount && productCount.count < mockProducts.length) {
    console.log("Seeding products from mock data...");
    let sql = "";
    for (const product of mockProducts) {
      const id = product.id;
      const name = (product.name || '').replace(/'/g, "''");
      const cat = (product.category || 'Sin Categoria').replace(/'/g, "''");
      const warehouse = (product.warehouse || 'General').replace(/'/g, "''");
      const barcode = (product.barcode || '').replace(/'/g, "''");
      const unit = (product.unit || 'UND').replace(/'/g, "''");
      const stock = product.stock || 0;
      const minStock = product.minStock || 0;
      const currency = (product.currency || 'PEN').replace(/'/g, "''");
      const unitCost = product.unitCost || 0;
      
      sql += `INSERT OR IGNORE INTO products (id, name, category_id, warehouse_id, barcode, unit, stock, min_stock, currency, unit_cost, sync_status) VALUES ('${id}', '${name}', '${cat}', '${warehouse}', '${barcode}', '${unit}', ${stock}, ${minStock}, '${currency}', ${unitCost}, 'synced');\n`;
    }
    await db.execAsync(sql);
    console.log("Seeding products completed.");
  }

  // Seed de movimientos
  const movementCount = await db.getFirstAsync<{count: number}>('SELECT COUNT(*) as count FROM movements');
  const { mockMovements } = require('../data/mockInventory');
  if (movementCount && movementCount.count < mockMovements.length) {
    console.log("Seeding movements from mock data...");
    
    let movSql = "";
    const uniqueProjects = ['Instalacion paneles Santa Anita', 'Reposicion almacen', 'Mantenimiento bombeo solar'];
    for (const projName of uniqueProjects) {
      const pid = projName.toLowerCase().replace(/\s+/g, '-');
      movSql += `INSERT OR IGNORE INTO projects (id, name, sync_status) VALUES ('${pid}', '${projName}', 'synced');\n`;
    }

    for (const mov of mockMovements) {
      const prod = mockProducts.find(p => p.name.toLowerCase() === mov.productName.toLowerCase());
      const prodId = prod ? prod.id : 'unknown';
      const projId = mov.project.toLowerCase().replace(/\s+/g, '-');
      const dateStr = new Date().toISOString();
      
      movSql += `INSERT OR IGNORE INTO movements (id, type, product_id, quantity, project_id, date, sync_status) VALUES ('${mov.id}', '${mov.type}', '${prodId}', ${mov.quantity}, '${projId}', '${dateStr}', 'synced');\n`;
    }
    await db.execAsync(movSql);
    console.log("Seeding movements completed.");
  }

  // PATCH: Corregir movimientos huérfanos por el bug de mayúsculas en la v1
  await db.execAsync(`
    UPDATE movements SET product_id = 'prod-015' WHERE id = 'mov-002' AND product_id = 'unknown';
    UPDATE movements SET product_id = 'prod-024' WHERE id = 'mov-003' AND product_id = 'unknown';
  `);

  // Seed Admin user si la tabla de usuarios está vacía
  const userCount = await db.getFirstAsync<{count: number}>('SELECT COUNT(*) as count FROM users');
  if (userCount && userCount.count === 0) {
    console.log("Seeding default admin user...");
    await db.runAsync(
      `INSERT INTO users (id, name, email, password, role, active, sync_status) 
      VALUES (?, ?, ?, ?, ?, ?, 'synced')`,
      ['user-001', 'Administrador', 'admin@proenergim.com', '123456', 'Admin', 1]
    );
  }
}
