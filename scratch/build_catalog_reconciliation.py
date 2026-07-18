import json
import re
import unicodedata
from difflib import SequenceMatcher
from pathlib import Path

import pandas as pd


ROOT = Path(__file__).resolve().parent.parent
EXCEL = ROOT / 'bd.xlsx'
PHOTOS = Path(
    r'C:\Users\MARI\AppData\Local\Temp\claude\C--Users-MARI-app-inventario-mobil'
    r'\3e6bd6c4-af40-4066-86ee-6878272007a4\scratchpad\catalogo.tsv'
)
OUTPUT = ROOT / 'scratch' / 'catalog_reconciliation.json'
NEW_CANDIDATES_OUTPUT = ROOT / 'scratch' / 'new_product_candidates.json'

# Fotos sin equivalente claro entre los 122 productos oficiales. Se proponen
# para alta, pero no se insertan automáticamente: el administrador confirma
# cada caso antes de incorporarlo al catálogo maestro.
NEW_CANDIDATE_PHOTOS = {
    3: 'Thinner acrílico: no existe ficha equivalente en el Excel.',
    13: 'Hidrolavadora portátil: no existe ficha equivalente en el Excel.',
    17: 'Caja de registro para pozo a tierra: no existe ficha equivalente.',
    35: 'Grasa/lubricante SKF: no existe ficha equivalente.',
    36: 'Espuma de poliuretano 750 ml: no existe ficha equivalente.',
    37: 'Espuma de poliuretano 340 ml: variante que requiere ficha propia.',
    40: 'Solvente dieléctrico: no existe ficha equivalente.',
    43: 'UPS Hikvision: no existe ficha UPS equivalente.',
    70: 'Filtro de ventilador: no existe ficha equivalente.',
    122: 'Crimpadora de terminales: distinta del alicate genérico.',
    125: 'Crimpadora RJ45: herramienta de red, distinta del alicate genérico.',
}


def normalized(value):
    value = unicodedata.normalize('NFKD', str(value)).encode('ascii', 'ignore').decode()
    value = value.upper()
    value = re.sub(r'[^A-Z0-9.]+', ' ', value)
    value = re.sub(r'(\d)([A-Z])', r'\1 \2', value)
    return re.sub(r'\s+', ' ', value).strip()


def meaningful_tokens(value):
    ignored = {
        'DE', 'LA', 'EL', 'Y', 'CON', 'PARA', 'EN', 'SIN', 'POR', 'UN', 'UNA',
        'UND', 'EQUIPO', 'FERRETERIA', 'EPP', 'SOLAR', 'TIPO', 'DEL', 'LOS', 'LAS',
        'CC', 'CA', 'DC', 'AC', 'MONEDA', 'UNIDAD', 'PRODUCTO',
    }
    return {token for token in normalized(value).split() if len(token) > 1 and token not in ignored}


def technical_specs(value):
    return set(re.findall(
        r'\b\d+(?:\.\d+)?\s*(?:KW|W|V|AH|A|MM|M|T|PSI|LTS|LT|DB|AWG|HP)\b',
        normalized(value),
    ))


def specs_by_unit(specifications, unit):
    return {value for value in specifications if value.endswith(f' {unit}')}


def is_support_photo(row):
    details = str(row['datos']).upper()
    return 'NO ES ITEM DE INVENTARIO' in details or 'NO ES PRODUCTO' in details


def canonical_photo_rows(photos):
    """Keep one evidence record per visible code, while retaining no-code photos."""
    result = []
    seen_codes = set()
    for _, photo in photos.sort_values('n').iterrows():
        if is_support_photo(photo):
            continue
        code = str(photo['codigo']).strip()
        if code and code != '-':
            if code in seen_codes:
                continue
            seen_codes.add(code)
        result.append(photo)
    return result


def score_match(product_name, photo):
    photo_text = ' '.join(
        str(photo.get(column, ''))
        for column in ('categoria', 'subtipo', 'marca', 'modelo', 'datos')
    )
    product_tokens = meaningful_tokens(product_name)
    photo_tokens = meaningful_tokens(photo_text)
    shared = product_tokens & photo_tokens
    token_score = len(shared) / max(1, len(product_tokens | photo_tokens))
    sequence_score = SequenceMatcher(None, normalized(product_name), normalized(photo_text)).ratio()
    product_specs = technical_specs(product_name)
    photo_specs = technical_specs(photo_text)
    shared_specs = product_specs & photo_specs
    spec_score = len(shared_specs) / max(1, len(product_specs))

    # Variador e inversor se usan indistintamente en la información histórica.
    subtype = normalized(photo.get('subtipo', ''))
    product_normalized = normalized(product_name)
    family_bonus = 0.0
    if ('INVERSOR' in product_normalized and ('INVERSOR' in subtype or 'VARIADOR' in subtype)):
        family_bonus = 0.12
    elif any(token in product_normalized for token in ('CABLE', 'GUANTE', 'CASCO', 'LENTE', 'PERNO', 'DISYUNTOR')) and any(
        token in subtype for token in ('CABLE', 'GUANTE', 'CASCO', 'LENTE', 'PERNO', 'DISYUNTOR')
    ):
        family_bonus = 0.12

    score = 0.35 * token_score + 0.20 * sequence_score + 0.35 * spec_score + family_bonus
    return score, sorted(shared_specs), len(shared)


def main():
    official = pd.read_excel(EXCEL, sheet_name='BASE DE DATOS ALMACEN')
    photos = pd.read_csv(PHOTOS, sep='\t').fillna('')
    evidence = canonical_photo_rows(photos)
    reconciliation = []

    for _, product in official.iterrows():
        ranked = []
        for photo in evidence:
            score, shared_specs, shared_tokens = score_match(product['PRODUCTO'], photo)
            ranked.append((score, shared_specs, shared_tokens, photo))
        ranked.sort(key=lambda item: item[0], reverse=True)
        score, shared_specs, shared_tokens, best = ranked[0]
        code = str(best['codigo']).strip()
        code_is_available = bool(code and code != '-')
        product_specs = technical_specs(product['PRODUCTO'])
        photo_specs = technical_specs(' '.join(
            str(best.get(column, ''))
            for column in ('subtipo', 'marca', 'modelo', 'datos')
        ))
        expected_voltage = specs_by_unit(product_specs, 'V')
        observed_voltage = specs_by_unit(photo_specs, 'V')
        expected_power = specs_by_unit(product_specs, 'KW') | specs_by_unit(product_specs, 'W')
        observed_power = specs_by_unit(photo_specs, 'KW') | specs_by_unit(photo_specs, 'W')
        has_conflicting_voltage = bool(
            expected_voltage and observed_voltage and not (expected_voltage & observed_voltage)
        )
        has_conflicting_power = bool(
            expected_power and observed_power and not (expected_power & observed_power)
        )

        # A factory code is proposed only with a product-family match plus a
        # shared technical value, or with a very strong textual match.
        can_keep_code = code_is_available and (
            (shared_specs and shared_tokens >= 2 and score >= 0.25) or score >= 0.52
        ) and not has_conflicting_voltage and not has_conflicting_power
        review = score >= 0.18 and not can_keep_code
        if can_keep_code:
            status = 'CONSERVAR CÓDIGO DE FÁBRICA'
            internal_qr = ''
        elif review:
            status = 'REVISAR COINCIDENCIA'
            internal_qr = ''
        else:
            status = 'GENERAR QR INTERNO'
            internal_qr = f"PROENERGIM-{int(product['ITEM']):03d}"

        reconciliation.append({
            'item': int(product['ITEM']),
            'almacen': product['ALMACEN'],
            'tipo_oficial': product['TIPO'],
            'producto_oficial': product['PRODUCTO'],
            'unidad': product['UM'],
            'stock_excel': int(product['UND']) if pd.notna(product['UND']) else 0,
            'foto_referencia': int(best['n']) if status != 'GENERAR QR INTERNO' else '',
            'archivo_foto': best['archivo'] if status != 'GENERAR QR INTERNO' else '',
            'codigo_fabrica_propuesto': code if can_keep_code else '',
            'tipo_codigo': best['tipo_codigo'] if can_keep_code else '',
            'marca_propuesta': best['marca'] if status != 'GENERAR QR INTERNO' else '',
            'modelo_propuesto': best['modelo'] if status != 'GENERAR QR INTERNO' else '',
            'subtipo_propuesto': best['subtipo'] if status != 'GENERAR QR INTERNO' else '',
            'atributos_foto': best['datos'] if status != 'GENERAR QR INTERNO' else '',
            'especificaciones_coincidentes': ', '.join(shared_specs),
            'conflicto_especificaciones': (
                'Voltaje no coincide' if has_conflicting_voltage
                else 'Potencia no coincide' if has_conflicting_power
                else ''
            ),
            'confianza': round(score, 3),
            'estado': status,
            'qr_interno_propuesto': internal_qr,
            'nota': (
                'Código confirmado por tipo/nombre y especificaciones.' if can_keep_code
                else 'Hay una posible foto relacionada; validar antes de asignar código.' if review
                else 'No existe evidencia fotográfica suficiente; generar QR interno.'
            ),
        })

    for row in reconciliation:
        for key, value in row.items():
            if pd.isna(value):
                row[key] = ''
    OUTPUT.write_text(
        json.dumps(reconciliation, ensure_ascii=False, indent=2, allow_nan=False),
        encoding='utf-8',
    )
    candidates = []
    for _, photo in photos[photos['n'].isin(NEW_CANDIDATE_PHOTOS)].iterrows():
        candidates.append({
            'foto': int(photo['n']),
            'producto_propuesto': photo['subtipo'],
            'categoria': photo['categoria'],
            'marca': photo['marca'],
            'modelo': photo['modelo'],
            'codigo_fabrica': '' if str(photo['codigo']).strip() == '-' else photo['codigo'],
            'datos_tecnicos': photo['datos'],
            'estado': 'PENDIENTE DE APROBACIÓN',
            'motivo': NEW_CANDIDATE_PHOTOS[int(photo['n'])],
        })
    NEW_CANDIDATES_OUTPUT.write_text(
        json.dumps(candidates, ensure_ascii=False, indent=2, allow_nan=False),
        encoding='utf-8',
    )
    print(f'Wrote {len(reconciliation)} official records to {OUTPUT}')
    print(pd.Series([row['estado'] for row in reconciliation]).value_counts().to_string())


if __name__ == '__main__':
    main()
