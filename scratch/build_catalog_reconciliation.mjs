import fs from 'node:fs/promises';
import { SpreadsheetFile, Workbook } from '@oai/artifact-tool';

const root = process.cwd();
const rows = JSON.parse(await fs.readFile(`${root}/scratch/catalog_reconciliation.json`, 'utf8'));
const candidates = JSON.parse(await fs.readFile(`${root}/scratch/new_product_candidates.json`, 'utf8'));
const outputDir = `${root}/outputs/catalog_reconciliation`;
await fs.mkdir(outputDir, { recursive: true });

const workbook = Workbook.create();
const summary = workbook.worksheets.add('Resumen');
const sheet = workbook.worksheets.add('Conciliación');
const candidatesSheet = workbook.worksheets.add('Nuevos candidatos');

summary.getRange('A1:D1').merge();
summary.getRange('A1').values = [['Conciliación oficial: Excel + fotografías']];
summary.getRange('A1:D1').format = {
  fill: '#1959AD', font: { bold: true, color: '#FFFFFF', size: 14 },
  horizontalAlignment: 'center', verticalAlignment: 'center',
};
summary.getRange('A3:B6').values = [
  ['Productos oficiales (Excel)', rows.length],
  ['Conservar código de fábrica', rows.filter(r => r.estado === 'CONSERVAR CÓDIGO DE FÁBRICA').length],
  ['Revisar coincidencia', rows.filter(r => r.estado === 'REVISAR COINCIDENCIA').length],
  ['Generar QR interno', rows.filter(r => r.estado === 'GENERAR QR INTERNO').length],
];
summary.getRange('A3:A6').format = { fill: '#EAF2FF', font: { bold: true } };
summary.getRange('A3:B6').format.borders = { preset: 'all', style: 'thin', color: '#D1D5DB' };
summary.getRange('A8:D10').merge();
summary.getRange('A8').values = [[
  'Regla: un código de fábrica se conserva únicamente cuando nombre/tipo y especificaciones no se contradicen. Las coincidencias incompletas quedan para revisión; si no hay evidencia se propone QR interno.'
]];
summary.getRange('A8:D10').format = { fill: '#FFF7E6', wrapText: true, verticalAlignment: 'center' };
summary.getRange('A:A').format.columnWidth = 34;
summary.getRange('B:B').format.columnWidth = 18;
summary.getRange('C:D').format.columnWidth = 18;
summary.getRange('A1:D1').format.rowHeight = 28;
summary.showGridLines = false;

const columns = [
  ['ITEM', 'item'], ['ALMACÉN', 'almacen'], ['TIPO', 'tipo_oficial'],
  ['PRODUCTO OFICIAL', 'producto_oficial'], ['UNIDAD', 'unidad'], ['STOCK EXCEL', 'stock_excel'],
  ['FOTO', 'foto_referencia'], ['ARCHIVO FOTO', 'archivo_foto'], ['CÓDIGO FÁBRICA PROPUESTO', 'codigo_fabrica_propuesto'],
  ['TIPO DE CÓDIGO', 'tipo_codigo'], ['MARCA', 'marca_propuesta'], ['MODELO', 'modelo_propuesto'],
  ['SUBTIPO', 'subtipo_propuesto'], ['ATRIBUTOS / DATOS FOTO', 'atributos_foto'],
  ['ESPECIFICACIONES COINCIDENTES', 'especificaciones_coincidentes'], ['CONFLICTO', 'conflicto_especificaciones'],
  ['CONFIANZA', 'confianza'], ['ESTADO', 'estado'], ['QR INTERNO PROPUESTO', 'qr_interno_propuesto'], ['NOTA', 'nota'],
];
sheet.getRangeByIndexes(0, 0, 1, columns.length).values = [columns.map(([name]) => name)];
sheet.getRangeByIndexes(1, 0, rows.length, columns.length).values = rows.map(row => columns.map(([, key]) => {
  const value = row[key] ?? '';
  return (key === 'codigo_fabrica_propuesto' && /^\d/.test(String(value))) ? `'${value}` : value;
}));
const used = sheet.getRangeByIndexes(0, 0, rows.length + 1, columns.length);
sheet.getRangeByIndexes(0, 0, 1, columns.length).format = {
  fill: '#1959AD', font: { bold: true, color: '#FFFFFF' }, wrapText: true,
  horizontalAlignment: 'center', verticalAlignment: 'center',
};
used.format.borders = { preset: 'insideHorizontal', style: 'thin', color: '#E5E7EB' };
sheet.getRange(`Q2:Q${rows.length + 1}`).format.numberFormat = '0.000';
sheet.getRange(`F2:F${rows.length + 1}`).format.numberFormat = '#,##0';
sheet.getRange(`R2:R${rows.length + 1}`).conditionalFormats.add('containsText', { text: 'CONSERVAR', format: { fill: '#DCFCE7', font: { color: '#166534', bold: true } } });
sheet.getRange(`R2:R${rows.length + 1}`).conditionalFormats.add('containsText', { text: 'REVISAR', format: { fill: '#FEF3C7', font: { color: '#92400E', bold: true } } });
sheet.getRange(`R2:R${rows.length + 1}`).conditionalFormats.add('containsText', { text: 'GENERAR', format: { fill: '#EAF2FF', font: { color: '#1D4ED8', bold: true } } });
sheet.freezePanes.freezeRows(1);
sheet.getRange(`A1:T${rows.length + 1}`).format.wrapText = true;
const widths = [8,16,13,42,10,12,8,34,26,15,20,26,26,52,24,24,11,28,28,42];
widths.forEach((width, index) => sheet.getRangeByIndexes(0, index, rows.length + 1, 1).format.columnWidth = width);
sheet.getRange(`A1:T1`).format.rowHeight = 38;
sheet.showGridLines = false;

const candidateColumns = [
  ['FOTO', 'foto'], ['PRODUCTO PROPUESTO', 'producto_propuesto'], ['CATEGORÍA', 'categoria'],
  ['MARCA', 'marca'], ['MODELO', 'modelo'], ['CÓDIGO DE FÁBRICA', 'codigo_fabrica'],
  ['DATOS TÉCNICOS', 'datos_tecnicos'], ['ESTADO', 'estado'], ['MOTIVO', 'motivo'],
];
candidatesSheet.getRangeByIndexes(0, 0, 1, candidateColumns.length).values = [candidateColumns.map(([name]) => name)];
candidatesSheet.getRangeByIndexes(1, 0, candidates.length, candidateColumns.length).values = candidates.map(row => candidateColumns.map(([, key]) => {
  const value = row[key] ?? '';
  return (key === 'codigo_fabrica' && /^\d/.test(String(value))) ? `'${value}` : value;
}));
candidatesSheet.getRange(`A1:I${candidates.length + 1}`).format.wrapText = true;
candidatesSheet.getRange('A1:I1').format = { fill: '#1959AD', font: { bold: true, color: '#FFFFFF' }, horizontalAlignment: 'center' };
candidatesSheet.getRange(`A1:I${candidates.length + 1}`).format.borders = { preset: 'insideHorizontal', style: 'thin', color: '#E5E7EB' };
candidatesSheet.getRange(`H2:H${candidates.length + 1}`).format = { fill: '#FEF3C7', font: { color: '#92400E', bold: true } };
[8, 28, 15, 20, 24, 24, 60, 26, 48].forEach((width, index) => candidatesSheet.getRangeByIndexes(0, index, candidates.length + 1, 1).format.columnWidth = width);
candidatesSheet.freezePanes.freezeRows(1);
candidatesSheet.showGridLines = false;

const check = await workbook.inspect({ kind: 'table', range: 'Conciliación!A1:T8', include: 'values', tableMaxRows: 8, tableMaxCols: 20 });
console.log(check.ndjson);
const preview = await workbook.render({ sheetName: 'Resumen', range: 'A1:D10', scale: 1.5, format: 'png' });
await fs.writeFile(`${outputDir}/preview.png`, new Uint8Array(await preview.arrayBuffer()));
const candidatesPreview = await workbook.render({ sheetName: 'Nuevos candidatos', range: 'A1:I12', scale: 1, format: 'png' });
await fs.writeFile(`${outputDir}/candidates_preview.png`, new Uint8Array(await candidatesPreview.arrayBuffer()));
const output = await SpreadsheetFile.exportXlsx(workbook);
await output.save(`${outputDir}/conciliacion_catalogo_actualizada.xlsx`);
