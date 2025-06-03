import os
import xml.etree.ElementTree as ET
from pathlib import Path
from PIL import Image

# Define source and destination directories
#source_dir = Path('C:/Users/nitin/Documents/CNN/helmet_dataset/train')  # Replace with your source directory path
#dest_dir = Path('C:/Users/nitin/Documents/CNN/helmet_dataset/labels/train')  # Replace with your destination directory path
#source_dir = Path('C:/Users/nitin/Documents/CNN/helmet_dataset/valid')  # Replace with your source directory path
#dest_dir = Path('C:/Users/nitin/Documents/CNN/helmet_dataset/labels/valid')  # Replace with your destination directory path
source_dir = Path('C:/Users/nitin/Documents/CNN/helmet_dataset/test')  # Replace with your source directory path
dest_dir = Path('C:/Users/nitin/Documents/CNN/helmet_dataset/labels/test')  # Replace with your destination directory path

# Ensure the destination directory exists
dest_dir.mkdir(parents=True, exist_ok=True)

# Define class labels (adjust as per your dataset)
class_labels = ['With Helmet', 'Without Helmet', 'licence']  # Replace with your actual class labels

def parse_xml_to_yolo(xml_file, image_width, image_height):
    """
    Parse a single XML file to extract bounding box annotations and convert to YOLO format.
    """
    print(f"Processing XML file: {xml_file}")
    tree = ET.parse(xml_file)
    root = tree.getroot()
    annotations = []

    # Extract bounding boxes and class labels

    for obj in root.findall('object'):
        class_name = obj.find('name').text.strip()
        # print(f"Found class: {class_name}")  # Debug statement to display each class name

        if class_name not in class_labels:
            print(f"Class '{class_name}' not in defined labels, skipping.")  # Debug for undefined classes
            continue  # Skip if class name is not in the defined labels        class_name = obj.find('name').text.strip()
        
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

def process_single_annotation():
    """
    Process the first XML file in the source directory and convert annotations to YOLO format.
    """
    # Get the first XML file in the source directory
    xml_files = list(source_dir.glob('*.xml'))
    if not xml_files:
        print("No XML files found in the source directory.")
        return

    xml_file = xml_files[0]
    print(f"Found XML file: {xml_file}")

    # Determine corresponding image file
    image_file = source_dir / f"{xml_file.stem}.jpg"  # Adjust extension if necessary
    if not image_file.exists():
        print(f"Image file {image_file} not found, skipping.")
        return

    # Get image dimensions
    with Image.open(image_file) as img:
        image_width, image_height = img.size
        print(f"Opened image: {image_file} with dimensions: {image_width}x{image_height}")

    # Parse XML and convert annotations
    annotations = parse_xml_to_yolo(xml_file, image_width, image_height)

    if annotations:
        # Create corresponding text file in destination directory
        txt_file = dest_dir / f"{xml_file.stem}.txt"
        with open(txt_file, 'w', encoding='utf-8') as file:
            file.write("\n".join(annotations))
        print(f"Annotations for {xml_file.stem} saved to {txt_file}")
    else:
        print(f"No annotations found in {xml_file}, skipping.")

def process_all_annotations():
    """
    Process all XML files in the source directory and convert annotations to YOLO format.
    """
    # Retrieve all XML files in the source directory
    xml_files = list(source_dir.glob('*.xml'))
    if not xml_files:
        print("No XML files found in the source directory.")
        return

    for xml_file in xml_files:
        print(f"Processing XML file: {xml_file}")

        # Determine the corresponding image file
        image_file_jpg = source_dir / f"{xml_file.stem}.jpg"
        image_file_png = source_dir / f"{xml_file.stem}.png"

        if image_file_jpg.exists():
            image_file = image_file_jpg
        elif image_file_png.exists():
            image_file = image_file_png
        else:
            print(f"No corresponding image file found for {xml_file.stem}, skipping.")
            continue

        # Obtain image dimensions
        with Image.open(image_file) as img:
            image_width, image_height = img.size
            print(f"Opened image: {image_file} with dimensions: {image_width}x{image_height}")

        # Parse XML and convert annotations
        annotations = parse_xml_to_yolo(xml_file, image_width, image_height)

        if annotations:
            # Create corresponding text file in the destination directory
            txt_file = dest_dir / f"{xml_file.stem}.txt"
            with open(txt_file, 'w', encoding='utf-8') as file:
                file.write("\n".join(annotations))
            print(f"Annotations for {xml_file.stem} saved to {txt_file}")
        else:
            print(f"No annotations found in {xml_file}, skipping.")

if __name__ == "__main__":
    process_all_annotations()
