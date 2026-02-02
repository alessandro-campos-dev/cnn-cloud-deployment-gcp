import os
import logging
import tempfile
from datetime import datetime
from pathlib import Path

from flask import Flask, render_template, request, jsonify
from tensorflow.keras.models import load_model
import numpy as np
from PIL import Image
import json

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__, template_folder='../../templates')

# Load configuration
try:
    with open('config/config.yaml', 'r') as f:
        import yaml
        config = yaml.safe_load(f)
except:
    # Default configuration if config file not found
    config = {
        'app': {
            'max_file_size': 5 * 1024 * 1024,  # 5MB
            'allowed_extensions': {'.jpg', '.jpeg', '.png', '.gif', '.bmp'}
        },
        'model': {
            'class_names': ['airplane', 'automobile', 'bird', 'cat', 'deer', 
                           'dog', 'frog', 'horse', 'ship', 'truck'],
            'model_path': 'src/cnn-model/saved_models/cifar10_model.keras'
        }
    }

# Load model
MODEL_PATH = os.path.join(
    os.path.dirname(__file__), 
    '..', 
    'cnn-model', 
    'saved_models', 
    'cifar10_model.keras'
)

try:
    model = load_model(MODEL_PATH)
    logger.info(f"Model loaded successfully from {MODEL_PATH}")
except Exception as e:
    logger.error(f"Failed to load model: {e}")
   