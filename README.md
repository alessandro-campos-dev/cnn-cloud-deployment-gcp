# 🎯 CNN com deploy em múltiplos serviços GCP
Este projeto implementa um modelo de rede neural convolucional(CNN) treinado no dataset CIFAR-10 para classificação de imagens em 10 categorias. O sistema é projetado com princípios cloud-native e demonstra implantação em cinco serviços diferentes da GCP:

- Google Compute Engine (GCE) - Máquinas virtuais
- Google App Engine (GAE) - Plataforma como Serviço
- Google Kubernetes Engine (GKE) - Orquestração de containers
- Cloud Run - Containers serverless
- Cloud Functions - Funções serverless orientadas a eventos

# ✨ Funcionalidades
- Modelo CNN de Alta Precisão: Arquitetura CNN personalizada com ~85% de acurácia no CIFAR-10
- Implantação Multi-Cloud: Código único implantado em 5 serviços GCP
- API RESTful: Endpoints HTTP simples para previsões
- Auto-scaling: Políticas de escalonamento configuráveis para cada serviço
- Otimização de Custos: Análise comparativa de custos de implantação
- Integração com Monitoramento: Cloud Monitoring e Logging
- Pronto para CI/CD: Workflows do GitHub Actions para implantação automatizada

# 🏗️ Arquitetura
Diagrama de Implantação

<img width="3346" height="2112" alt="deepseek_mermaid_20260202_651cc4" src="https://github.com/user-attachments/assets/eb7052b9-9d9a-4ecf-8c14-28d18732e52d" />



## Arquitetura do Modelo

Modelo CNN (para CIFAR-10):

Entrada (32x32x3) → Conv2D(32) → MaxPooling → Conv2D(64) → MaxPooling 
→ Conv2D(128) → Flatten → Dense(256) → Dropout → Dense(10) → Saída

# 📊 Dataset
Dataset CIFAR-10: 60.000 imagens coloridas 32x32 em 10 classes

- Avião ✈️
- Automóvel 🚗
- Pássaro 🐦
- Gato 🐱
- Cervo 🦌
- Cachorro 🐕
- Sapo 🐸
- Cavalo 🐴
- Navio 🚢
- Caminhão 🚚

## Divisão Treino/Teste: 50.000 imagens de treino, 10.000 imagens de teste

# 🚀 Instalação
- Pré-requisitos
- Python 3.10+
- Google Cloud SDK
- Docker (para implantações containerizadas)
- Git

 # 🙏 Agradecimentos
- Dataset CIFAR-10 por Alex Krizhevsky, Vinod Nair e Geoffrey Hinton
- Equipe TensorFlow pelo framework de deep learning
- Google Cloud Platform pelos serviços de infraestrutura
- Equipe Flask pelo framework web

# 📞 Suporte
Para issues, perguntas ou sugestões:

- Alessandro Campos: campos.yah@gmail.com
- Whatsapp: [62 9 9223.5995](https://wa.me/5562992235995)

# 📈 Roadmap
- Adicionar versionamento de modelo
- Implementar A/B testing
- Adicionar mais datasets (CIFAR-100, subset ImageNet)
- Implementar predições em batch
- Adicionar dashboard de monitoramento
- Suporte para treinamento de modelo customizado via UI
