# 🤝 Contributing to Project Garuda

<div align="center">

  **Thank you for your interest in contributing to Project Garuda!** 🦅

  Every contribution — whether it's a bug report, feature request, documentation improvement, or code — helps make supply chains more resilient and intelligent.

</div>

---

## 📌 Table of Contents

1. [Code of Conduct](#-code-of-conduct)
2. [How Can I Contribute?](#-how-can-i-contribute)
3. [Development Setup](#-development-setup)
4. [Branch Naming Convention](#-branch-naming-convention)
5. [Commit Message Guidelines](#-commit-message-guidelines)
6. [Pull Request Process](#-pull-request-process)
7. [Coding Standards](#-coding-standards)
8. [Reporting Bugs](#-reporting-bugs)
9. [Suggesting Features](#-suggesting-features)
10. [Community](#-community)

---

## 📜 Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to **team.dietcoke.gsc@gmail.com**.

---

## 💡 How Can I Contribute?

| Type | Description |
|:---|:---|
| 🐛 **Bug Reports** | Found a bug? [Open an issue](https://github.com/TechNoSena/Garuda/issues/new?template=bug_report.md) with reproduction steps |
| ✨ **Feature Requests** | Have an idea? [Start a discussion](https://github.com/TechNoSena/Garuda/issues/new?template=feature_request.md) |
| 📖 **Documentation** | Fix typos, improve guides, add examples |
| 🧪 **Testing** | Write unit tests, integration tests, or help test the APK |
| 💻 **Code** | Pick up an open issue and submit a pull request |
| 🌐 **Translations** | Help make Garuda accessible in more languages |

---

## 🛠️ Development Setup

### Prerequisites

- **Python 3.11+** (Backend)
- **Flutter SDK 3.11+** (Frontend)
- **Git** (Version control)
- **Google Cloud Project** with enabled APIs (Maps, Search, Vertex AI)
- **Firebase Project** configured

### Backend (FastAPI)

```bash
# Clone the repository
git clone https://github.com/TechNoSena/Garuda.git
cd Garuda/backend-fastapi

# Create virtual environment
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env with your API keys

# Run the development server
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Frontend (Flutter)

```bash
cd Garuda/flutter_app

# Install dependencies
flutter pub get

# Run on connected device or emulator
flutter run

# Run tests
flutter test
```

---

## 🌿 Branch Naming Convention

Use descriptive branch names following this pattern:

| Prefix | Purpose | Example |
|:---|:---|:---|
| `feature/` | New features | `feature/demand-surge-alerts` |
| `fix/` | Bug fixes | `fix/map-marker-offset` |
| `docs/` | Documentation updates | `docs/api-endpoint-guide` |
| `refactor/` | Code restructuring | `refactor/provider-architecture` |
| `test/` | Adding or updating tests | `test/ride-monitor-unit` |
| `ci/` | CI/CD pipeline changes | `ci/apk-build-optimization` |

```bash
# Example
git checkout -b feature/multi-modal-switching
```

---

## 📝 Commit Message Guidelines

We follow the **Conventional Commits** specification for clear, readable history.

### Format

```
<type>(<scope>): <short description>

[optional body]

[optional footer]
```

### Types

| Type | Description |
|:---|:---|
| `feat` | A new feature |
| `fix` | A bug fix |
| `docs` | Documentation only changes |
| `style` | Code style (formatting, missing semicolons, etc.) |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `test` | Adding or correcting tests |
| `chore` | Build process, auxiliary tools, or dependency updates |
| `perf` | Performance improvements |

### Examples

```bash
feat(routing): add avoid_waypoints parameter to reroute engine
fix(auth): resolve Firebase token refresh on session expiry
docs(readme): add demo credentials and APK download link
refactor(providers): consolidate shipment state management
test(api): add integration tests for /v1/ride/monitor endpoint
```

---

## 🔄 Pull Request Process

### Before Submitting

1. **Fork** the repository and create your branch from `master`
2. **Ensure** all existing tests pass: `flutter test` / `pytest`
3. **Add tests** if you've added code that should be tested
4. **Update documentation** if you've changed APIs or behavior
5. **Lint your code** — follow the project's coding standards

### PR Template

When submitting a PR, please include:

```markdown
## 📋 What does this PR do?
<!-- A clear description of the changes -->

## 🔗 Related Issue
<!-- Link to the GitHub issue, e.g., Closes #42 -->

## 📸 Screenshots (if applicable)
<!-- Add screenshots for UI changes -->

## ✅ Checklist
- [ ] My code follows the project's coding standards
- [ ] I have added tests covering my changes
- [ ] All new and existing tests pass
- [ ] I have updated the documentation accordingly
- [ ] My changes generate no new warnings or lint errors
```

### Review Process

1. At least **one team member** must approve the PR
2. All CI checks (GitHub Actions APK build) must pass ✅
3. Merge conflicts must be resolved before merging
4. Use **Squash and Merge** for feature branches to keep history clean

---

## 📐 Coding Standards

### Dart / Flutter

- Follow the official [Dart Style Guide](https://dart.dev/effective-dart/style)
- Use `const` constructors wherever possible
- Prefer `final` over `var` for local variables
- Keep widgets small and focused — extract into separate files when > 100 lines
- Use the project's `FunkyBox` design system for all UI components
- Ensure dark/light theme compatibility on all screens

### Python / FastAPI

- Follow [PEP 8](https://peps.python.org/pep-0008/) style guidelines
- Use type hints for all function parameters and return types
- Write docstrings for all public functions and classes
- Keep endpoint handlers thin — delegate logic to service layers
- Use `async` for all I/O-bound operations

### General

- No hardcoded API keys or secrets — use environment variables
- Write meaningful variable and function names
- Comment *why*, not *what* — code should be self-documenting
- Keep functions under 50 lines where possible

---

## 🐛 Reporting Bugs

Great bug reports help us fix issues faster! Please include:

### Bug Report Template

```markdown
**Describe the bug**
A clear and concise description of the unexpected behavior.

**Steps to reproduce**
1. Go to '...'
2. Click on '...'
3. Scroll down to '...'
4. See error

**Expected behavior**
What you expected to happen.

**Screenshots**
If applicable, add screenshots to help explain.

**Environment:**
- Device: [e.g., Pixel 7, Samsung S24]
- OS: [e.g., Android 14, iOS 17]
- App Version: [e.g., Beta v1.0.0]
- Role: [e.g., Supplier, Driver]
```

---

## ✨ Suggesting Features

We love hearing ideas! When suggesting a feature, please describe:

- **The problem** you're trying to solve
- **Your proposed solution** and how it would work
- **Alternative approaches** you've considered
- **Which user role** would benefit (Supplier, Logistics, Driver, Consumer)
- **Relevance** to the Google Solution Challenge / UN SDGs

---

## 🌍 Community

- 🐙 **GitHub Issues:** [Report bugs & request features](https://github.com/TechNoSena/Garuda/issues)
- 📧 **Email:** divye.prakash07@gmail.com
- 🎬 **Demo Video:** [Watch on YouTube](https://youtu.be/Alz17zhRqGw)

---

<div align="center">

  **Thank you for helping make Project Garuda better!** 🦅☁️

  *Every contribution counts — Team DietCoke · Google Solution Challenge 2026*

</div>
