# Phantom Calculator 🧮

**Simple 3D animated motion calculator using Python with Flutter integration.**

A cross-platform calculator application combining a Python backend with a Flutter frontend, featuring smooth 3D animations and a modern UI.

## 📱 Features

- **Flutter Mobile & Web App**: Beautiful, responsive UI with 3D animations
- **Python Backend**: High-performance calculation engine
- **Cross-Platform**: Runs on iOS, Android, Web, Windows, macOS, Linux
- **CI/CD Automation**: GitHub Actions for automated testing and deployment
- **Real-time Sync**: Live calculation engine integration

## 🚀 Quick Start

### Prerequisites
- Flutter SDK (≥3.0)
- Python 3.8+
- Git

### Running Locally

#### Flutter App
```bash
cd flutter_app
flutter pub get
flutter run
```

## 📦 Project Structure
Nova-Calcx/
├── calculator.py                         ← Python: Desktop UI + Flask API 
├── requirements.txt                      ← flask, gunicorn
├── Dockerfile                            ← Multi-stage: Flutter build + nginx + Python
├── nginx.conf                            ← Reverse proxy web + API
├── flutter_app/lib/
│   ├── main.dart                         ← App entry, theme, orientation 
│   ├── screens/calculator_screen.dart    ← Full UI + animations
│   ├── widgets/calc_button.dart          ← 3D custom button    
│   └── utils/calculator_engine.dart      ← Dart math engine    
├── .github/workflows/deploy.yml          ← CI/CD → GitHub Pages
└── docs/index.html                       ← Loading placeholder (auto-replaced on deploy)

## 📖 Documentation

- **[Flutter Setup Guide](docs/FLUTTER_SETUP.md)** - Development environment setup
- **[GitHub Setup Guide](docs/GITHUB_SETUP.md)** - Deployment & CI/CD configuration
- **[Architecture](docs/ARCHITECTURE.md)** - System design & components

## 🔧 Configuration

### Environment Variables
Create a `.env` file in the root:
```env
PYTHON_API_URL=http://localhost:8000
ENVIRONMENT=development
```

### GitHub Actions Secrets
Add these to your repository settings (Settings → Secrets):
- `APP_SIGNING_KEY` - For app store deployment
- `FIREBASE_CONFIG` - For Firebase hosting

## 📱 Deployment

### Web Deployment
```bash
cd flutter_app
flutter build web
firebase deploy --only hosting
```

### Mobile Deployment
- **Android**: `flutter build apk --release`
- **iOS**: `flutter build ios --release`
- **macOS**: `flutter build macos --release`

### Backend Deployment
```bash
cd python_app
# Option 1: Heroku
git push heroku main

# Option 2: Docker
docker build -t phantom-calc .
docker run -p 8000:8000 phantom-calc
```

## 🧪 Testing

```bash
# Flutter tests
cd flutter_app
flutter test

# Python tests
cd python_app
python -m pytest tests/
```

## 🔄 CI/CD Pipeline

Automated workflows trigger on:
- ✅ Push to `main` branch
- ✅ Pull requests
- ✅ Tagged releases

See [GitHub Actions Workflow](.github/workflows/flutter.yml)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

## 📞 Support

For issues and questions:
- Open an [Issue](https://github.com/Phantom-dcode/Calculator/issues)
- Check [Discussions](https://github.com/Phantom-dcode/Calculator/discussions)

---

**Made with ❤️ by Phantom-dcode**
