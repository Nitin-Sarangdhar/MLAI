import os
import xml.etree.ElementTree as ET
import tensorflow as tf
import numpy as np
import matplotlib.pyplot as plt
from sklearn.metrics import precision_score, recall_score, f1_score, roc_auc_score, confusion_matrix


# Paths to dataset
TRAIN_PATH = "helmet_dataset/train"
VALID_PATH = "helmet_dataset/valid"
#TRAIN_PATH = "Bike Helmet Detection.v2-more-preprocessing-augmentation.voc/train"
#VALID_PATH = "Bike Helmet Detection.v2-more-preprocessing-augmentation.voc/valid"

# Class mapping
class_mapping = {"With Helmet": 1, "Without Helmet": 0}

# Function to parse XML annotation files
def parse_annotation(file_path, dataset_path):
    tree = ET.parse(file_path)
    root = tree.getroot()
    image_filename = root.find("filename").text
    image_path = os.path.join(dataset_path, image_filename)
    objects = []
    for obj in root.findall("object"):
        label = obj.find("name").text
        if label not in class_mapping:
            continue
        bndbox = obj.find("bndbox")
        xmin = int(bndbox.find("xmin").text)
        ymin = int(bndbox.find("ymin").text)
        xmax = int(bndbox.find("xmax").text)
        ymax = int(bndbox.find("ymax").text)
        objects.append((xmin, ymin, xmax, ymax, class_mapping[label]))
    return image_path, objects

# Function to load annotations from a specific directory
def load_annotations_from_directory(dataset_path):
    annotations = []
    for file in os.listdir(dataset_path):
        if file.endswith(".xml"):
            file_path = os.path.join(dataset_path, file)
            annotations.append(parse_annotation(file_path, dataset_path))
    return annotations

# Load annotations for both train and valid directories
train_annotations = load_annotations_from_directory(TRAIN_PATH)
valid_annotations = load_annotations_from_directory(VALID_PATH)

print(f"Loaded {len(train_annotations)} training annotated images.")
print(f"Loaded {len(valid_annotations)} validation annotated images.")

# Function to load and preprocess images for TensorFlow
def load_and_preprocess(image_path, label):
    image = tf.io.read_file(image_path)
    image = tf.image.decode_jpeg(image, channels=3)
    image = tf.image.resize(image, (224, 224)) / 255.0
    image = tf.image.random_flip_left_right(image)
    image = tf.image.random_flip_up_down(image)
    return image, label

# Function to prepare dataset from annotations
def prepare_dataset(annotations):
    image_paths = []
    labels = []
    for ann in annotations:
        img_path = ann[0]
        objects = ann[1]
        label = 0
        for obj in objects:
            if obj[4] == 1:
                label = 1
                break
        image_paths.append(img_path)
        labels.append(label)
    return tf.data.Dataset.from_tensor_slices((image_paths, labels))

# Prepare the train and valid datasets
train_dataset = prepare_dataset(train_annotations)
valid_dataset = prepare_dataset(valid_annotations)

# Apply preprocessing function
train_dataset = train_dataset.map(lambda img_path, lbl: load_and_preprocess(img_path, lbl))
valid_dataset = valid_dataset.map(lambda img_path, lbl: load_and_preprocess(img_path, lbl))

# Shuffle and batch dataset
BATCH_SIZE = 32
train_dataset = train_dataset.shuffle(buffer_size=1000).batch(BATCH_SIZE).prefetch(tf.data.AUTOTUNE)
valid_dataset = valid_dataset.batch(BATCH_SIZE).prefetch(tf.data.AUTOTUNE)

print("TensorFlow dataset is ready for training and validation!")

# Load the pre-trained MobileNetV2 model, excluding the top classification layer
base_model = tf.keras.applications.MobileNetV2(input_shape=(224, 224, 3),
                                               include_top=False,
                                               weights='imagenet')

# Freeze the base model to prevent its weights from being updated during training
base_model.trainable = False

# Add new classification layers on top of the base model
model = tf.keras.Sequential([
    base_model,
    tf.keras.layers.GlobalAveragePooling2D(),
    tf.keras.layers.Dense(1, activation='sigmoid')  # Binary classification: With Helmet or Without Helmet
])

# Compile the model
model.compile(optimizer='adam',
              loss='binary_crossentropy',
              metrics=['accuracy'])

# Train the model
history = model.fit(train_dataset, epochs=10, validation_data=valid_dataset)

# Evaluate the model
loss, acc = model.evaluate(valid_dataset)
print(f"Validation Accuracy: {acc:.2f}")

# Plot training performance
plt.plot(history.history['accuracy'], label='Train Accuracy')
plt.plot(history.history['val_accuracy'], label='Validation Accuracy')
plt.xlabel('Epochs')
plt.ylabel('Accuracy')
plt.legend()
plt.show()

# Save the model
model.save("helmet_detection_model.keras")

print("Training complete! Model saved.")

y_true = []  # True labels
y_pred = []  # Predicted labels

# Collect predictions for metrics calculation
for images, labels in valid_dataset:
    preds = model.predict(images)
    y_true.extend(labels.numpy())
    y_pred.extend((preds > 0.5).astype(int))

# Calculate Precision, Recall, F1 Score, and AUC
precision = precision_score(y_true, y_pred)
recall = recall_score(y_true, y_pred)
f1 = f1_score(y_true, y_pred)
auc = roc_auc_score(y_true, y_pred)
cm = confusion_matrix(y_true, y_pred)

print(f"Precision: {precision:.2f}")
print(f"Recall: {recall:.2f}")
print(f"F1 Score: {f1:.2f}")
print(f"AUC: {auc:.2f}")
print(f"Confusion Matrix:\n{cm}")


