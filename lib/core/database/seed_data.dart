import 'package:sqflite/sqflite.dart';

Future<void> insertSeedData(Database db) async {
    // Data from Excel
    await db.insert('categories', {'id': 10, 'name': 'EQUIPO', 'description': 'Migrado de Excel'});
    await db.insert('categories', {'id': 11, 'name': 'EPP', 'description': 'Migrado de Excel'});
    await db.insert('categories', {'id': 12, 'name': 'FERRETERIA ', 'description': 'Migrado de Excel'});
    await db.insert('categories', {'id': 13, 'name': 'FERRETERIA', 'description': 'Migrado de Excel'});
    await db.insert('warehouses', {'id': 10, 'name': 'IMPORTADOS', 'location': 'Sede Principal'});
    await db.insert('warehouses', {'id': 11, 'name': 'LAS MERCEDES ', 'location': 'Sede Principal'});
    await db.insert('warehouses', {'id': 12, 'name': 'ALMACEN 2', 'location': 'Sede Principal'});
    await db.insert('products', {
      'code': 'PROD-0001',
      'name': 'INVERSOR DE FRECUENCIA SOLAR HIBRIDO 2.2 KW MONOFASICO 220 V',
      'categoryId': 10,
      'stock': 92,
      'minStock': 5,
      'unit': 'UND',
      'price': 60.0,
      'currency': 'USD'
    });
    await db.insert('products', {
      'code': 'PROD-0002',
      'name': 'INVERSOR DE FRECUENCIA SOLAR HIBRIDO 5.5 KW MONOFASICO 220 V',
      'categoryId': 10,
      'stock': 32,
      'minStock': 5,
      'unit': 'UND',
      'price': 198.0,
      'currency': 'USD'
    });
    await db.insert('products', {
      'code': 'PROD-0003',
      'name': 'INVERSOR DE FRECUENCIA SOLAR HIBRIDO 5.5 KW TRIFASICO 380 V',
      'categoryId': 10,
      'stock': 32,
      'minStock': 5,
      'unit': 'UND',
      'price': 128.0,
      'currency': 'USD'
    });
    await db.insert('products', {
      'code': 'PROD-0004',
      'name': 'INVERSOR DE FRECUENCIA SOLAR HIBRIDO 11 KW TRIFASICO 380 V',
      'categoryId': 10,
      'stock': 28,
      'minStock': 5,
      'unit': 'UND',
      'price': 170.0,
      'currency': 'USD'
    });
    await db.insert('products', {
      'code': 'PROD-0005',
      'name': 'INVERSOR DE FRECUENCIA SOLAR HIBRIDO 22 KW TRIFASICO 380 V',
      'categoryId': 10,
      'stock': 6,
      'minStock': 5,
      'unit': 'UND',
      'price': 303.0,
      'currency': 'USD'
    });
    await db.insert('products', {
      'code': 'PROD-0006',
      'name': 'INVERSOR DE FRECUENCIA SOLAR HIBRIDO 55 KW TRIFASICO 380 V',
      'categoryId': 10,
      'stock': 5,
      'minStock': 5,
      'unit': 'UND',
      'price': 650.0,
      'currency': 'USD'
    });
    await db.insert('products', {
      'code': 'PROD-0007',
      'name': 'INVERSOR DE FRECUENCIA SOLAR HIBRIDO 75 KW TRIFASICO 380 V',
      'categoryId': 10,
      'stock': 4,
      'minStock': 5,
      'unit': 'UND',
      'price': 850.0,
      'currency': 'USD'
    });
    await db.insert('products', {
      'code': 'PROD-0008',
      'name': 'INVERSOR DE FRECUENCIA SOLAR HIBRIDO 110 KW TRIFASICO 380 V',
      'categoryId': 10,
      'stock': 5,
      'minStock': 5,
      'unit': 'UND',
      'price': 1160.0,
      'currency': 'USD'
    });
    await db.insert('products', {
      'code': 'PROD-0009',
      'name': 'INVERSOR DE FRECUENCIA SOLAR HIBRIDO 200 KW TRIFASICO 380 V',
      'categoryId': 10,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 2070.0,
      'currency': 'USD'
    });
    await db.insert('products', {
      'code': 'PROD-0010',
      'name': 'DISYUNTOR DE CC , 2 POLOS, 600V CC. 16 A',
      'categoryId': 10,
      'stock': 360,
      'minStock': 5,
      'unit': 'UND',
      'price': 4.4,
      'currency': 'USD'
    });
    await db.insert('products', {
      'code': 'PROD-0011',
      'name': 'DISYUNTOR DE CAJA MOLDEADA DE CC, 2 POLOS, 320 A',
      'categoryId': 10,
      'stock': 12,
      'minStock': 5,
      'unit': 'UND',
      'price': 35.2,
      'currency': 'USD'
    });
    await db.insert('products', {
      'code': 'PROD-0012',
      'name': 'DISYUNTOR DE CAJA MOLDEADA DE CC, 2 POLOS, 500 A',
      'categoryId': 10,
      'stock': 12,
      'minStock': 5,
      'unit': 'UND',
      'price': 59.1,
      'currency': 'USD'
    });
    await db.insert('products', {
      'code': 'PROD-0013',
      'name': 'DISYUNTOR DE CAJA MOLDEADA DE CC, 2 POLOS, 800 A',
      'categoryId': 10,
      'stock': 8,
      'minStock': 5,
      'unit': 'UND',
      'price': 90.7,
      'currency': 'USD'
    });
    await db.insert('products', {
      'code': 'PROD-0014',
      'name': 'SUPRESOR DE PICOS DE CC, 2 POLOS, 40 kA, 800 V CC',
      'categoryId': 10,
      'stock': 120,
      'minStock': 5,
      'unit': 'UND',
      'price': 3.9,
      'currency': 'USD'
    });
    await db.insert('products', {
      'code': 'PROD-0015',
      'name': 'CONECTOR MC4 DE 6 MM 1000 V CC',
      'categoryId': 10,
      'stock': 1000,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.5,
      'currency': 'USD'
    });
    await db.insert('products', {
      'code': 'PROD-0016',
      'name': 'Repuestos (2,2 kW, 5,5 kW, 11 kW)',
      'categoryId': 10,
      'stock': 0,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.04,
      'currency': 'USD'
    });
    await db.insert('products', {
      'code': 'PROD-0017',
      'name': 'CHALECO DRILL AMARILLO S-XL CON CINTA REFLECTIVA /BORDADO',
      'categoryId': 11,
      'stock': 50,
      'minStock': 5,
      'unit': 'UND',
      'price': 28.0
    });
    await db.insert('products', {
      'code': 'PROD-0018',
      'name': 'GORRO  DRILL SIN TAPANUCA CON BORDADO',
      'categoryId': 11,
      'stock': 50,
      'minStock': 5,
      'unit': 'UND',
      'price': 11.0
    });
    await db.insert('products', {
      'code': 'PROD-0019',
      'name': 'SOMBRERO SAFARI DRILL TAPANUCA BEIGE',
      'categoryId': 11,
      'stock': 50,
      'minStock': 5,
      'unit': 'UND',
      'price': 4.0
    });
    await db.insert('products', {
      'code': 'PROD-0020',
      'name': 'GUANTEHILO AMARILLO STREELPRO',
      'categoryId': 11,
      'stock': 50,
      'minStock': 5,
      'unit': 'UND',
      'price': 2.92
    });
    await db.insert('products', {
      'code': 'PROD-0021',
      'name': 'LENTES TRASNPARENTES LENTE SPY LUNA CLARA STEELPRO',
      'categoryId': 11,
      'stock': 50,
      'minStock': 5,
      'unit': 'UND',
      'price': 2.91
    });
    await db.insert('products', {
      'code': 'PROD-0022',
      'name': 'TAPON AUDITIVOS AUDITIVO EN BOLSITA SEGLPRO',
      'categoryId': 11,
      'stock': 100,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.6
    });
    await db.insert('products', {
      'code': 'PROD-0023',
      'name': 'MARCARILLA 7502 CON FILTRO 2097 ASA',
      'categoryId': 11,
      'stock': 3,
      'minStock': 5,
      'unit': 'UND',
      'price': 30.0
    });
    await db.insert('products', {
      'code': 'PROD-0024',
      'name': 'CASCO JOCKEY STEELPRO AZUL',
      'categoryId': 11,
      'stock': 20,
      'minStock': 5,
      'unit': 'UND',
      'price': 15.5
    });
    await db.insert('products', {
      'code': 'PROD-0025',
      'name': 'BLUSA OXFORD CELESTE TALLA L',
      'categoryId': 11,
      'stock': 3,
      'minStock': 5,
      'unit': 'UND',
      'price': 30.0
    });
    await db.insert('products', {
      'code': 'PROD-0026',
      'name': 'POLO MANGA LARGA ESTAMPADO PECHO Y ESPALDA',
      'categoryId': 11,
      'stock': 50,
      'minStock': 5,
      'unit': 'UND',
      'price': 11.0
    });
    await db.insert('products', {
      'code': 'PROD-0027',
      'name': 'ESCALERA MULTIUSO DE 12 PASOS ',
      'categoryId': 12,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 530.0
    });
    await db.insert('products', {
      'code': 'PROD-0028',
      'name': 'ESCALERA MULTIUSO DE 24 PASOS',
      'categoryId': 12,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 820.0
    });
    await db.insert('products', {
      'code': 'PROD-0029',
      'name': 'PERNOS DE DOS GROSORES DOS CAJAS',
      'categoryId': 12,
      'stock': 2,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0030',
      'name': 'CODO CLASE 10 CON ROSCA',
      'categoryId': 12,
      'stock': 2,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0031',
      'name': 'CODO',
      'categoryId': 12,
      'stock': 2,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0032',
      'name': 'VARIADOR',
      'categoryId': 12,
      'stock': 2,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0033',
      'name': 'CODOS',
      'categoryId': 12,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0034',
      'name': 'CODITO',
      'categoryId': 12,
      'stock': 3,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0035',
      'name': 'CODO',
      'categoryId': 12,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0036',
      'name': 'PEGAMENTO',
      'categoryId': 12,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0037',
      'name': 'CODO',
      'categoryId': 12,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0038',
      'name': 'VENTILADOR',
      'categoryId': 12,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0039',
      'name': 'PONCHOS',
      'categoryId': 11,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0040',
      'name': 'TECLE',
      'categoryId': 12,
      'stock': 2,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0041',
      'name': 'FOCOS',
      'categoryId': 12,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0042',
      'name': 'PERNOS',
      'categoryId': 12,
      'stock': 3,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0043',
      'name': 'PERNO',
      'categoryId': 12,
      'stock': 62,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0044',
      'name': 'TARUGOS',
      'categoryId': 12,
      'stock': 19,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0045',
      'name': 'TARUGOS',
      'categoryId': 12,
      'stock': 75,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0046',
      'name': 'TIRAFONES',
      'categoryId': 12,
      'stock': 84,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0047',
      'name': 'CINTILLOS',
      'categoryId': 12,
      'stock': 2,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0048',
      'name': 'TARUGITOS',
      'categoryId': 12,
      'stock': 59,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0049',
      'name': 'CINTILLOS',
      'categoryId': 12,
      'stock': 12,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0050',
      'name': 'PANELES',
      'categoryId': 10,
      'stock': 75,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0051',
      'name': 'CHAPA',
      'categoryId': 12,
      'stock': 107,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0052',
      'name': 'SOPLADORA',
      'categoryId': 12,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0053',
      'name': 'LLAVE ESTRILPOL',
      'categoryId': 12,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0054',
      'name': 'SOPLADORA',
      'categoryId': 12,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0055',
      'name': 'TALADRO',
      'categoryId': 12,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0056',
      'name': 'CABLE',
      'categoryId': 12,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0057',
      'name': 'DISCOS',
      'categoryId': 12,
      'stock': 2,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0058',
      'name': 'ALICATE',
      'categoryId': 12,
      'stock': 13,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0059',
      'name': 'ESCUADRA',
      'categoryId': 12,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0060',
      'name': 'TALADRO',
      'categoryId': 12,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0061',
      'name': 'MOLADORA',
      'categoryId': 12,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0062',
      'name': 'NIVELADORA',
      'categoryId': 12,
      'stock': 2,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0063',
      'name': 'BANDEJA REJILLA BF2R-100X65 EZ1000 - L=3M BASOR',
      'categoryId': 12,
      'stock': 30,
      'minStock': 5,
      'unit': 'UND',
      'price': 59.93
    });
    await db.insert('products', {
      'code': 'PROD-0064',
      'name': 'POLEA',
      'categoryId': 12,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0065',
      'name': 'SIERRA',
      'categoryId': 12,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0066',
      'name': 'CAMARA',
      'categoryId': 12,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0067',
      'name': 'BATERIA',
      'categoryId': 12,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0068',
      'name': 'MEMORIAS',
      'categoryId': 12,
      'stock': 3,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0069',
      'name': 'CLAVOS',
      'categoryId': 12,
      'stock': 13,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0070',
      'name': 'COMPRESORA',
      'categoryId': 12,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0071',
      'name': 'ABRASADERA',
      'categoryId': 12,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0072',
      'name': 'PUNTERAS',
      'categoryId': 12,
      'stock': 0,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0073',
      'name': 'SOLDADORA',
      'categoryId': 12,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0074',
      'name': 'NIVEL DE MANO',
      'categoryId': 12,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0075',
      'name': 'ESCUADRAS',
      'categoryId': 12,
      'stock': 2,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0076',
      'name': 'CABLE',
      'categoryId': 12,
      'stock': 250,
      'minStock': 5,
      'unit': 'METROS',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0077',
      'name': 'PANELES',
      'categoryId': 12,
      'stock': 4,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0078',
      'name': 'SOGA',
      'categoryId': 12,
      'stock': 0,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0079',
      'name': 'LLAVES',
      'categoryId': 12,
      'stock': 11,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0080',
      'name': 'VERNNIER',
      'categoryId': 12,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0081',
      'name': 'CONTROLADOR',
      'categoryId': 12,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0082',
      'name': 'SPD',
      'categoryId': 12,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0083',
      'name': 'ANTENA',
      'categoryId': 12,
      'stock': 3,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0084',
      'name': 'MODULOS',
      'categoryId': 12,
      'stock': 2,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0085',
      'name': 'TESTEADOR',
      'categoryId': 12,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0086',
      'name': 'MEGAMETRO',
      'categoryId': 12,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0087',
      'name': 'VARIADOR',
      'categoryId': 12,
      'stock': 2,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0088',
      'name': 'INVERSOR',
      'categoryId': 12,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0089',
      'name': 'IMPULSOR',
      'categoryId': 12,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0090',
      'name': 'IMPULSOR',
      'categoryId': 12,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0091',
      'name': 'PANELES SOLARES',
      'categoryId': 10,
      'stock': 2,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0092',
      'name': 'KIT SOLAR',
      'categoryId': 10,
      'stock': 3,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0093',
      'name': 'CAMARA',
      'categoryId': 10,
      'stock': 5,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0094',
      'name': 'CAMARA',
      'categoryId': 10,
      'stock': 5,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0095',
      'name': 'REGILLAS',
      'categoryId': 12,
      'stock': 4,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0096',
      'name': 'PANEL',
      'categoryId': 10,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0097',
      'name': 'TESTEADOR',
      'categoryId': 12,
      'stock': 2,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0098',
      'name': 'CENSORES',
      'categoryId': 12,
      'stock': 10,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0099',
      'name': 'VENTILADOR',
      'categoryId': 12,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0100',
      'name': 'PINZAS',
      'categoryId': 12,
      'stock': 2,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0101',
      'name': 'REFLECTOR',
      'categoryId': 12,
      'stock': 2,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0102',
      'name': 'RELET TERMICA',
      'categoryId': 12,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0103',
      'name': 'CONECTORES',
      'categoryId': 12,
      'stock': 466,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0104',
      'name': 'MOTOR',
      'categoryId': 12,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0105',
      'name': 'TELUROMETRO',
      'categoryId': 12,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0106',
      'name': 'INERSOR MUST',
      'categoryId': 12,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0107',
      'name': 'REFLECTOR SOLAR',
      'categoryId': 10,
      'stock': 2,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0108',
      'name': 'REFLECTOR SOLAR',
      'categoryId': 10,
      'stock': 3,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0109',
      'name': 'COMPRESORA',
      'categoryId': 13,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 0.0
    });
    await db.insert('products', {
      'code': 'PROD-0110',
      'name': 'ARNES DE SEGURIDAD LINEA DE VIDA',
      'categoryId': 11,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 115.0
    });
    await db.insert('products', {
      'code': 'PROD-0111',
      'name': 'PROTECTORES FACIALES',
      'categoryId': 11,
      'stock': 6,
      'minStock': 5,
      'unit': 'UND',
      'price': 12.0
    });
    await db.insert('products', {
      'code': 'PROD-0112',
      'name': 'LENTES OSCUROS',
      'categoryId': 11,
      'stock': 6,
      'minStock': 5,
      'unit': 'UND',
      'price': 2.9
    });
    await db.insert('products', {
      'code': 'PROD-0113',
      'name': 'MANDILES DE CUERO',
      'categoryId': 11,
      'stock': 2,
      'minStock': 5,
      'unit': 'UND',
      'price': 15.0
    });
    await db.insert('products', {
      'code': 'PROD-0114',
      'name': 'FAJAS',
      'categoryId': 11,
      'stock': 6,
      'minStock': 5,
      'unit': 'UND',
      'price': 14.0
    });
    await db.insert('products', {
      'code': 'PROD-0115',
      'name': 'CORTAVIENTOS',
      'categoryId': 11,
      'stock': 6,
      'minStock': 5,
      'unit': 'UND',
      'price': 2.0
    });
    await db.insert('products', {
      'code': 'PROD-0116',
      'name': 'PANTALONES T36',
      'categoryId': 11,
      'stock': 10,
      'minStock': 5,
      'unit': 'UND',
      'price': 32.0
    });
    await db.insert('products', {
      'code': 'PROD-0117',
      'name': 'PANTALONES T32',
      'categoryId': 11,
      'stock': 10,
      'minStock': 5,
      'unit': 'UND',
      'price': 32.0
    });
    await db.insert('products', {
      'code': 'PROD-0118',
      'name': 'PANTALONES T34',
      'categoryId': 11,
      'stock': 8,
      'minStock': 5,
      'unit': 'UND',
      'price': 38.0
    });
    await db.insert('products', {
      'code': 'PROD-0119',
      'name': 'POLERAS T-XL',
      'categoryId': 11,
      'stock': 6,
      'minStock': 5,
      'unit': 'UND',
      'price': 8.0
    });
    await db.insert('products', {
      'code': 'PROD-0120',
      'name': 'LINTERNA LED TACTICA DE 15 WATTS COD OP -8112',
      'categoryId': 13,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 90.0
    });
    await db.insert('products', {
      'code': 'PROD-0121',
      'name': 'BLOQUEADOR SOLAR SUGAR SUN 1 LITRO',
      'categoryId': 11,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 65.0
    });
    await db.insert('products', {
      'code': 'PROD-0122',
      'name': 'BOTIQUIN DE PLASTICO GRANDE IMPLEMENTADO',
      'categoryId': 11,
      'stock': 1,
      'minStock': 5,
      'unit': 'UND',
      'price': 24.0
    });
}