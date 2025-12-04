import os
import subprocess
from pathlib import Path
import argparse
from PIL import Image, ImageOps

IMAGE_EXTENSIONS = ('.png', '.jpg', '.jpeg', '.gif', '.bmp', '.tiff', '.webp')

def find_matching_images(search_terms, base_path, exclude_terms = None):
    exclude_terms = exclude_terms or []
    matched_files = set()
    for root, _, files in os.walk(base_path):
        for file in files:
            if file.lower().endswith(IMAGE_EXTENSIONS):
                file_path = Path(root) / file
                name_lower = file_path.name.lower()
                parent_lower = file_path.parent.name.lower()

                if all(term.lower() in name_lower or term.lower() in parent_lower for term in search_terms) and \
                   not any(term.lower() in name_lower or term.lower() in parent_lower for term in exclude_terms):
                    matched_files.add(str(file_path.resolve()))
    return matched_files

def open_images(image_paths):

    for path in image_paths:
        os.startfile(path)

def stitch_images_2x2(image_paths, output_path="stitched_output.jpg", target_size=500, border_size=30, border_color=(255, 255, 255)):
    if len(image_paths) < 1:
        print("No images to stitch.")
        return

    selected = list(image_paths)[:4]  # limit to 4 images for 2x2 grid
    selected.sort()

    images = []

    for idx, path in enumerate(selected):
        img = Image.open(path).convert("RGB")

        if idx % 2 != 0:
            crop_left = int(img.width * 0.05)
            img = img.crop((crop_left, 0, img.width, img.height))
                
        # Resize while keeping aspect ratio to target height
        scale_factor = target_size / img.height
        new_size = (int(img.width * scale_factor), target_size)
        img_resized = img.resize(new_size, Image.LANCZOS)

        # Add border
        img_bordered = ImageOps.expand(img, border=border_size, fill=border_color)
        images.append(img_bordered)

    # Ensure we have 4 images by duplicating last if fewer
    while len(images) < 4:
        images.append(images[-1].copy())

    width = images[0].width
    height = images[0].height

    stitched_image = Image.new("RGB", (2 * width, 2 * height), border_color)

    positions = [(0, 0), (width, 0), (0, height),(width, height)]
    for img, pos in zip(images, positions):
        stitched_image.paste(img, pos)

    stitched_image.save(output_path)
    print(f"Stitched image saved to {output_path}")
    open_images([output_path])

def stitch_images_1x3(image_paths, output_path="stitched_output.jpg", target_height=800, border_size=10, border_color=(255, 255, 255)):
    if len(image_paths) < 1:
        print("No images to stitch.")
        return

    # Limit to 3 images for the 1x3 format
    selected = list(image_paths)[:3]
    selected.sort()
    images = []

    for idx, path in enumerate(selected):
        img = Image.open(path).convert("RGB")

        # Cuts 5% from left
        if idx != 0:
            crop_left = int(img.width * 0.05)
            img = img.crop((crop_left, 0, img.width, img.height))

        # Resize while keeping aspect ratio to target height
        scale_factor = target_height / img.height
        new_size = (int(img.width * scale_factor), target_height)
        img_resized = img.resize(new_size, Image.LANCZOS)

        # Add border
        img_bordered = ImageOps.expand(img_resized, border=border_size, fill=border_color)
        images.append(img_bordered)

    total_width = sum(img.width for img in images)
    final_height = images[0].height  # They should all have same height now (with border)

    stitched_image = Image.new("RGB", (total_width, final_height), border_color)

    x_offset = 0
    for img in images:
        stitched_image.paste(img, (x_offset, 0))
        x_offset += img.width

    stitched_image.save(output_path)
    print(f"Stitched image saved to {output_path}")
    open_images([output_path])

def main():
    parser = argparse.ArgumentParser(description="Find and open image files, optionally stitch them.")
    parser.add_argument('terms', nargs='+', help="Folder names or partial filenames to match.")
    parser.add_argument('--path', '-p', default='.', help="Base directory to search from.")
    parser.add_argument('--stitch', default=True, help="Stitch first 3 matched images into one image.")
    parser.add_argument('--exclude', '-e', nargs='*', default=[], help="Partial filenames to ignore")

    args = parser.parse_args()

    matched_images = find_matching_images(args.terms, args.path, args.exclude)

    if args.stitch == True:
        if len(args.exclude) > 0:
            stitch_images_1x3(matched_images)
        else:
            stitch_images_2x2(matched_images)
    else:
        if not matched_images:
            print("No matching images found.")
        else:
            print(f"Opening {len(matched_images)} image(s):")
            open_images(matched_images)

if __name__ == '__main__':
    main()
