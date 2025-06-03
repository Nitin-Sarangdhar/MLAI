import os
from bs4 import BeautifulSoup
from pathlib import Path

# Define source and destination directories using forward slashes
source_dir = Path('C:/Users/nitin/Documents/CNN/helmet_dataset/train')  # Replace with your source directory path
dest_dir = Path('C:/Users/nitin/Documents/CNN/helmet_dataset/labels/train')  # Replace with your destination directory path

# Ensure the destination directory exists
dest_dir.mkdir(parents=True, exist_ok=True)

# Define class labels (adjust as per your dataset)
class_labels = ['helmet', 'no_helmet', 'license']  # Replace with your actual class labels

def parse_html_to_yolo(html_file, image_width, image_height):
    """
    Parse a single HTML file to extract bounding box annotations and convert to YOLO format.
    """
    with open(html_file, 'r', encoding='utf-8') as file:
        soup = BeautifulSoup(file, 'html.parser')
        annotations = []

        # Extract bounding boxes and class labels
        for obj in soup.find_all('object'):
            class_name = obj.find('name').text.strip()
            if class_name not in class_labels:
                continue  # Skip if class name is not in the defined labels

            class_id = class_labels.index(class_name)
            bndbox = obj.find('bndbox')
            xmin = int(bndbox.find('xmin').text)
            ymin = int(bndbox.find('ymin').text)
            xmax = int(bndbox.find('xmax').text)
            ymax = int(bndbox.find('ymax').text)

            # Convert to YOLO format (normalized)
            x_center = (xmin + xmax) / 2.0 / image_width
            y_center = (ymin + ymax) / 2.0 / image_height
            width = (xmax - xmin) / float(image_width)
            height = (ymax - ymin) / float(image_height)

            annotations.append(f"{class_id} {x_center} {y_center} {width} {height}")

        return annotations

def process_annotations():
    """
    Process all HTML files in the source directory and convert annotations to YOLO format.
    """
    for html_file in source_dir.glob('*.html'):
        # Determine corresponding image file
        image_file = source_dir / f"{html_file.stem}.jpg"  # Adjust extension if necessary
        if not image_file.exists():
            print(f"Image file {image_file} not found, skipping.")
            continue

        # Get image dimensions
        from PIL import Image
        with Image.open(image_file) as img:
            image_width, image_height = img.size

        # Parse HTML and convert annotations
        annotations = parse_html_to_yolo(html_file, image_width, image_height)

        if annotations:
            # Create corresponding text file in destination directory
            txt_file = dest_dir / f"{html_file.stem}.txt"
            with open(txt_file, 'w', encoding='utf-8') as file:
                file.write("\n".join(annotations))
            print(f"Annotations for {html_file.stem} saved to {txt_file}")
        else:
            print(f"No annotations found in {html_file}, skipping.")

if __name__ == "__main__":
    process_annotations()
