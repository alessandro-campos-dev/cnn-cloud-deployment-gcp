import os
from flask import Flask, render_template, request
from tensorflow.keras.models import load_model
import numpy as np
from PIL import Image

#print('Hello')

app = Flask(__name__, template_folder='templates')

model = load_model(os.path.join('app', 'models', 'cifar10_model.keras'))

class_names = ['airplane', 'automobile', 'bird', 'cat', 'deer', 'dog', 'frog', 'horse', 'ship', 'truck']

def preprocess_image(image_file):
    img = Image.open(image_file)
    img = img.resize((32, 32))
    img = np.array(img)
    img = img / 255.0
    img = img.reshape(1, 32, 32, 3)
    return img

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/predict', methods = ['POST'])
def predict():
    if request.method == 'POST':
        file = request.files['image']
        file.save('uploaded_image.jpg')
        img = preprocess_image('uploaded_image.jpg')
        prediction = model.predict(img)
        predicted_class = class_names[np.argmax(prediction)]
        return render_template('result.html', prediction=predicted_class)
    
if __name__ == '__main__':
    app.run(host='0.0.0.0', port='8080')