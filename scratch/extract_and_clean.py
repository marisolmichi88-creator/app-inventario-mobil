import re
import base64
from PIL import Image

def main():
    try:
        # 1. Leer el SVG
        with open('assets/icon.svg', 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 2. Buscar la cadena base64 del PNG embebido
        match = re.search(r'base64,([A-Za-z0-9+/=\s]+)', content)
        if not match:
            print("Error: No se encontró la imagen base64 en assets/icon.svg")
            return
        
        # Limpiar espacios en blanco
        base64_str = re.sub(r'\s+', '', match.group(1))
        img_data = base64.b64decode(base64_str)
        
        # 3. Guardar temporalmente y procesar con Pillow
        temp_path = 'assets/logo.png'
        with open(temp_path, 'wb') as f:
            f.write(img_data)
            
        img = Image.open(temp_path)
        img = img.convert('RGBA')
        
        datas = img.getdata()
        newData = []
        
        # Hacer transparente el color negro del fondo si existe
        for item in datas:
            r, g, b, a = item
            if r < 35 and g < 35 and b < 35:
                newData.append((0, 0, 0, 0))
            else:
                newData.append((r, g, b, a))
                
        img.putdata(newData)
        img.save(temp_path, 'PNG')
        print(f"Éxito: Se extrajo el logotipo de assets/icon.svg, se limpió el fondo y se guardó en {temp_path}")
        
    except Exception as e:
        print(f"Error durante el proceso: {e}")

if __name__ == '__main__':
    main()
