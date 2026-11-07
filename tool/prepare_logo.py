from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = next(
    (
        path
        for path in (
            ROOT / 'assets' / 'images' / 'Logo_FRAP_blanc_sur_fond_bleu_marine.png',
            Path(
                r'C:\Users\ftshizubu\.cursor\projects\d-FP-mobile-fp\assets'
                r'\c__Users_ftshizubu_AppData_Roaming_Cursor_User_workspaceStorage_'
                r'e4155a9bb2c591e77e23d89c9b330e39_images_Logo_FRAP_blanc_sur_fond_'
                r'bleu_marine-5d2c9876-893e-4148-bf1a-9bfdba6135f8.png'
            ),
        )
        if path.exists()
    ),
    None,
)
TARGET = ROOT / 'assets' / 'images' / 'app_logo.png'


def prepare_logo(source: Path, target: Path) -> None:
    image = Image.open(source).convert('RGBA')
    pixels = []

    for red, green, blue, alpha in image.getdata():
        peak = max(red, green, blue)
        if peak <= 28:
            pixels.append((255, 255, 255, 0))
        elif peak >= 220:
            pixels.append((255, 255, 255, 255))
        else:
            edge_alpha = int((peak - 28) / (220 - 28) * 255)
            pixels.append((255, 255, 255, max(0, min(255, edge_alpha))))

    image.putdata(pixels)
    bounds = image.getbbox()
    if bounds:
        image = image.crop(bounds)

    target.parent.mkdir(parents=True, exist_ok=True)
    image.save(target)
    print(f'Prepared {target} from {source} ({image.size[0]}x{image.size[1]})')


if __name__ == '__main__':
    if SOURCE is None:
        raise SystemExit('Logo source file not found.')
    prepare_logo(SOURCE, TARGET)
