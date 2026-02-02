## 🎯 Modelo Treinado

O modelo CNN treinado no dataset CIFAR-10 está disponível em:

**📥 Download Direto:**
- [cifar10_model.keras](https://storage.googleapis.com/seus-modelos-cnn/models/cifar10_model.keras) (150MB)
- [modelo_reduzido.tflite](src/cnn-model/saved_models/model.tflite) (15MB) - Versão compactada

**Para usar no projeto:**
```bash
# Baixe o modelo para a pasta correta
mkdir -p src/cnn-model/saved_models
wget https://storage.googleapis.com/seus-modelos-cnn/models/cifar10_model.keras \
     -O src/cnn-model/saved_models/cifar10_model.keras