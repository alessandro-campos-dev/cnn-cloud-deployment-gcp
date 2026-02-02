"""
Cloud Function for CNN Image Classification
"""
import os
import tempfile
import json
import base64
from io import BytesIO
from datetime import datetime

from flask import jsonify
from PIL import Image
import numpy as np
import tensorflow as tf

# Load model at startup (cold start optimization)
model = None

def load_model():
    """Load the CNN model (called once per instance)"""
    global model
    if model is None:
        # Try to load from different possible locations
        model_paths = [
            'cifar10_model.keras',
            '/workspace/cifar10_model.keras',
            './cifar10_model.keras'
        ]
        
        for path in model_paths:
            try:
                model = tf.keras.models.load_model(path)
                print(f"Model loaded successfully from {path}")
                break
            except Exception as e:
                print(f"Failed to load model from {path}: {e}")
                continue
        
        if model is None:
            raise Exception("Could not load model from any path")
    
    return model

def preprocess_image(image_bytes):
    """Preprocess image for model prediction"""
    try:
        # Open image from bytes
        img = Image.open(BytesIO(image_bytes))
        
        # Resize to 32x32 (CIFAR-10 input size)
        img = img.resize((32, 32))
        
        # Convert to numpy array and normalize
        img_array = np.array(img)
        
        # Handle different image modes
        if len(img_array.shape) == 2:  # Grayscale
            img_array = np.stack([img_array] * 3, axis=-1)
        elif img_array.shape[2] == 4:  # RGBA
            img_array = img_array[:, :, :3]
        
        # Normalize to [0, 1]
        img_array = img_array / 255.0
        
        # Add batch dimension
        img_array = np.expand_dims(img_array, axis=0)
        
        return img_array
    except Exception as e:
        raise Exception(f"Error preprocessing image: {str(e)}")

def predict_image(request):
    """
    HTTP Cloud Function for image classification
    Args:
        request (flask.Request): HTTP request object
    Returns:
        HTTP response with prediction results
    """
    # Set CORS headers for browser requests
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Max-Age': '3600'
    }
    
    # Handle preflight requests
    if request.method == 'OPTIONS':
        return ('', 204, headers)
    
    try:
        # Load model (will be cached for subsequent requests)
        model = load_model()
        
        # Get image from request
        if 'image' in request.files:
            # Form data upload
            image_file = request.files['image']
            image_bytes = image_file.read()
        elif request.is_json:
            # Base64 encoded image in JSON
            data = request.get_json()
            if 'image' in data:
                image_bytes = base64.b64decode(data['image'])
            else:
                return (jsonify({'error': 'No image provided'}), 400, headers)
        else:
            return (jsonify({'error': 'Unsupported content type'}), 400, headers)
        
        # Check file size (limit to 5MB)
        if len(image_bytes) > 5 * 1024 * 1024:
            return (jsonify({'error': 'File too large (max 5MB)'}), 400, headers)
        
        # Preprocess image
        img_array = preprocess_image(image_bytes)
        
        # Make prediction
        predictions = model.predict(img_array)
        predicted_class_idx = np.argmax(predictions[0])
        confidence = float(predictions[0][predicted_class_idx])
        
        # Class names (CIFAR-10)
        class_names = ['airplane', 'automobile', 'bird', 'cat', 'deer', 
                      'dog', 'frog', 'horse', 'ship', 'truck']
        
        predicted_class = class_names[predicted_class_idx]
        
        # Get top 3 predictions
        top_indices = np.argsort(predictions[0])[-3:][::-1]
        top_predictions = [
            {
                'class': class_names[idx],
                'confidence': float(predictions[0][idx]),
                'rank': i + 1
            }
            for i, idx in enumerate(top_indices)
        ]
        
        # Prepare response
        response = {
            'success': True,
            'prediction': predicted_class,
            'confidence': confidence,
            'top_predictions': top_predictions,
            'timestamp': datetime.utcnow().isoformat(),
            'model': 'cifar10-cnn',
            'version': '1.0.0'
        }
        
        return (jsonify(response), 200, headers)
        
    except Exception as e:
        error_response = {
            'success': False,
            'error': str(e),
            'timestamp': datetime.utcnow().isoformat()
        }
        return (jsonify(error_response), 500, headers)

# Alternative: Function for base64 input
def predict_image_base64(event, context):
    """Cloud Function triggered by Pub/Sub or HTTP with base64 image"""
    try:
        # Load model
        model = load_model()
        
        # Get image data from event
        if 'data' in event:
            image_bytes = base64.b64decode(event['data'])
        else:
            raise ValueError("No image data in event")
        
        # Preprocess and predict
        img_array = preprocess_image(image_bytes)
        predictions = model.predict(img_array)
        predicted_class_idx = np.argmax(predictions[0])
        
        class_names = ['airplane', 'automobile', 'bird', 'cat', 'deer', 
                      'dog', 'frog', 'horse', 'ship', 'truck']
        
        return {
            'prediction': class_names[predicted_class_idx],
            'confidence': float(predictions[0][predicted_class_idx])
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        raise