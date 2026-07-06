from PIL import Image

def main():
    try:
        # Abrir la imagen extraída
        img = Image.open('assets/logo.png')
        img = img.convert('RGBA')
        
        datas = img.getdata()
        newData = []
        
        for item in datas:
            r, g, b, a = item
            # Si el color es negro o muy cercano al negro, hacerlo transparente
            if r < 35 and g < 35 and b < 35:
                newData.append((0, 0, 0, 0))
            else:
                newData.append((r, g, b, a))
                
        img.putdata(newData)
        img.save('assets/logo.png', 'PNG')
        print("Éxito: Se ha procesado el logotipo y removido el fondo negro a transparente.")
    except Exception as e:
        print(f"Error al procesar la imagen: {e}")

if __name__ == '__main__':
    main()
