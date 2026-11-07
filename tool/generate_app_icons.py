import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / 'assets' / 'images' / 'app_logo.png'
BG_COLOR = (59, 88, 201)  # #3B58C9 — fond bleu de l'app


def _compose_logo(size: int, padding_ratio: float, background: tuple[int, int, int, int]):
    logo = Image.open(SRC).convert('RGBA')
    canvas = Image.new('RGBA', (size, size), background)

    padding = int(size * padding_ratio)
    max_w = size - 2 * padding
    max_h = size - 2 * padding

    logo_w, logo_h = logo.size
    scale = min(max_w / logo_w, max_h / logo_h)
    new_w = max(1, int(logo_w * scale))
    new_h = max(1, int(logo_h * scale))
    resized = logo.resize((new_w, new_h), Image.Resampling.LANCZOS)

    x = (size - new_w) // 2
    y = (size - new_h) // 2
    canvas.paste(resized, (x, y), resized)
    return canvas


def make_icon(size: int, padding_ratio: float = 0.1) -> Image.Image:
    return _compose_logo(size, padding_ratio, BG_COLOR + (255,)).convert('RGB')


def make_splash_icon(size: int, padding_ratio: float = 0.12) -> Image.Image:
    return _compose_logo(size, padding_ratio, (0, 0, 0, 0))


def save_icon(path: Path, size: int, padding_ratio: float = 0.1) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    make_icon(size, padding_ratio).save(path)


def generate_android() -> None:
    android_res = ROOT / 'android' / 'app' / 'src' / 'main' / 'res'
    sizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
    }
    for folder, size in sizes.items():
        save_icon(android_res / folder / 'ic_launcher.png', size)

    android_res.mkdir(parents=True, exist_ok=True)
    make_splash_icon(280).save(android_res / 'drawable' / 'splash_logo.png')
    make_splash_icon(288).save(android_res / 'drawable' / 'splash_icon.png')


def generate_from_contents(contents_path: Path, padding_ratio: float = 0.1) -> None:
    with contents_path.open(encoding='utf-8') as file:
        data = json.load(file)

    out_dir = contents_path.parent
    generated: dict[str, int] = {}

    for image in data.get('images', []):
        filename = image.get('filename')
        if not filename:
            continue

        base_size = float(str(image['size']).split('x')[0])
        scale = int(str(image['scale']).replace('x', ''))
        pixel_size = int(base_size * scale)

        if filename not in generated:
            save_icon(out_dir / filename, pixel_size, padding_ratio)
            generated[filename] = pixel_size


def generate_web() -> None:
    web_icons = ROOT / 'web' / 'icons'
    save_icon(web_icons / 'Icon-192.png', 192)
    save_icon(web_icons / 'Icon-512.png', 512)
    save_icon(web_icons / 'Icon-maskable-192.png', 192, padding_ratio=0.18)
    save_icon(web_icons / 'Icon-maskable-512.png', 512, padding_ratio=0.18)


def generate_windows() -> None:
    ico_path = ROOT / 'windows' / 'runner' / 'resources' / 'app_icon.ico'
    ico_path.parent.mkdir(parents=True, exist_ok=True)
    icons = [make_icon(size) for size in (16, 32, 48, 64, 128, 256)]
    icons[0].save(
        ico_path,
        format='ICO',
        sizes=[(icon.width, icon.height) for icon in icons],
        append_images=icons[1:],
    )


def main() -> None:
    generate_android()
    generate_from_contents(
        ROOT / 'ios' / 'Runner' / 'Assets.xcassets' / 'AppIcon.appiconset' / 'Contents.json',
    )
    generate_from_contents(
        ROOT / 'macos' / 'Runner' / 'Assets.xcassets' / 'AppIcon.appiconset' / 'Contents.json',
    )
    generate_web()
    generate_windows()
    print('Generated app icons from assets/images/app_logo.png')


if __name__ == '__main__':
    main()
