# Flutter Scientific Calculator 📱✨

A modern, high-precision **Scientific & Standard Calculator** mobile application built with **Flutter** and **Dart**. Crafted with a dark-first OLED aesthetic, vibrant electric blue and purple gradient accents, tactile rounded keypads, and a custom recursive-descent math evaluation engine.

---

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Platform-Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Platform" />
  <img src="https://img.shields.io/badge/License-MIT-8B5CF6?style=for-the-badge" alt="License" />
  <img src="https://img.shields.io/badge/Tests-11%20Passed-brightgreen?style=for-the-badge" alt="Tests" />
</p>

---

## 📖 Table of Contents

- [Overview](#-overview)
- [Application Screenshots](#-application-screenshots)
- [Key Features](#-key-features)
- [Mathematical Engine Capabilities](#-mathematical-engine-capabilities)
- [Modes Overview](#-modes-overview)
- [Technologies Used](#-technologies-used)
- [Project Architecture & Directory Structure](#-project-architecture--directory-structure)
- [Installation & Setup](#-installation--setup)
- [Running the Application](#-running-the-application)
- [Automated Testing](#-automated-testing)
- [Standalone CLI Calculator](#-standalone-cli-calculator)
- [Contributing](#-contributing)
- [License](#-license)
- [Author](#-author)

---

## 🔍 Overview

**Flutter Scientific Calculator** is designed to provide an ergonomic, authentic, and responsive calculator experience on Android mobile devices. Unlike standard calculators that limit logarithmic functions or cram dozens of buttons into disorganized scrollable tables, this application features:

- A dedicated **Standard Mode** for fast, everyday calculations with large comfortable touch targets.
- A full-featured **Scientific Mode** with dedicated trigonometric, power, root, bracket, and arbitrary-base logarithm keys.
- A **Pure Dart Recursive-Descent Expression Parser** that handles operator precedence, implicit multiplication (e.g. `2(3+4)`, `2π`), unary operators, and floating-point precision rounding.

---

## 📱 Application Screenshots

<!-- 
Replace the placeholder below with your repository's raw screenshot URL once uploaded:
e.g. https://raw.githubusercontent.com/alanbiju422-dev/flutter-scientific-calculator/main/screenshots/app_preview.png
-->

<p align="center">
  <img src="https://raw.githubusercontent.com/alanbiju422-dev/flutter-scientific-calculator/main/screenshots/app_preview.png" alt="Flutter Scientific Calculator Preview" width="360" onerror="this.src='https://placehold.co/360x780/0b0c11/8b5cf6?text=Flutter+Scientific+Calculator+Preview&font=roboto';" />
</p>

> *The interface features deep charcoal backgrounds (`#0B0C11`), Electric Blue (`#3B82F6`) and Purple (`#8B5CF6`) gradient buttons, and real-time live evaluation.*

---

## 🌟 Key Features

- 🌓 **Seamless Dual-Mode Switcher**: Effortlessly toggle between **Standard** and **Scientific** modes via a smooth, animated capsule pill.
- 🎨 **Premium Dark-First UI**: High-contrast OLED dark palette with subtle button gradients, 1px chamfered borders, and soft elevation shadows.
- ⚡ **Tactile Haptic Feedback**: Integrated light haptic vibrations on key presses (`HapticFeedback.lightImpact()`) for realistic tactile responsiveness.
- 🧮 **Live Expression Preview**: Displays intermediate evaluated answers in real-time as you type, automatically balancing open parentheses.
- 📐 **Interactive Angle Mode**: Toggle between Degrees (`DEG`) and Radians (`RAD`) directly from the display screen.
- 🔄 **Dynamic 2nd / Shift Key**: Tapping `2nd*` activates an illuminated gradient indicator and transforms keys into their inverse/secondary functions (e.g., `sin` $\rightarrow$ `sin⁻¹`, `ln` $\rightarrow$ `eˣ`, `x²` $\rightarrow$ `x³`).
- 📜 **Calculation History**: Built-in sliding history modal that stores previous expressions and answers with one-tap recall and clear capabilities.
- 💾 **Memory Functions**: Full memory register (`M+`, `M−`, `MR`, `MC`) with status indicator badge.
- 📋 **Long-Press Clipboard Copy**: Long-press on the result display to copy the evaluated value to the Android clipboard.
- 🛡️ **Zero Layout Overflow**: Strictly engineered with responsive `LayoutBuilder` and `FittedBox` typography to adapt cleanly across diverse Android screen dimensions without pixel clipping.

---

## 🔬 Mathematical Engine Capabilities

The custom mathematical engine (`CalculatorEngine`) supports a comprehensive set of operations:

| Category | Functions / Operators | Example Syntax |
| :--- | :--- | :--- |
| **Basic Arithmetic** | `+`, `−`, `×`, `÷`, `%`, `+/-` | `125 × 4 ÷ 2 = 250` |
| **Trigonometry** | `sin`, `cos`, `tan` | `sin(30)` in `DEG` $\rightarrow$ `0.5` |
| **Inverse Trigonometry** | `asin` ($\sin^{-1}$), `acos` ($\cos^{-1}$), `atan` ($\tan^{-1}$) | `asin(0.5)` in `DEG` $\rightarrow$ `30` |
| **Hyperbolic Trig** | `sinh`, `cosh`, `tanh`, `asinh`, `acosh`, `atanh` | `sinh(1) ≈ 1.1752` |
| **Logarithms (Any Base)** | `logᵦ` ($\log_b(x)$), `log` (base 10), `ln` (base $e$), `log2` | `log(3, 81) = 4`, `log_3(81) = 4` |
| **Powers & Exponents** | $x^2$, $x^3$, $x^y$ (`^`), $e^x$, $10^x$ | `2^3 + 3^2 = 17` |
| **Roots** | Square Root ($\sqrt{x}$), Cube Root ($\sqrt[3]{x}$), $n$-th Root ($\sqrt[n]{x}$) | `sqrt(144) = 12`, `cbrt(-27) = -3` |
| **Discrete Math** | Factorial (`!`), Permutations (`nPr`), Combinations (`nCr`) | `5! = 120`, `npr(5,2) = 20` |
| **Number Theory** | Greatest Common Divisor (`gcd`), Least Common Multiple (`lcm`), Modulo (`mod`) | `gcd(18, 24) = 6`, `lcm(6, 8) = 24` |
| **Fractions & Representation** | Fraction toggle (`F⬄D`), Mixed fraction formatting | `1.75` $\leftrightarrow$ `1 3/4` |
| **Constants** | $\pi$ (`3.14159...`), Euler's number $e$ (`2.71828...`), Random (`rand()`), Last Answer (`Ans`) | `2π ≈ 6.28318` |

---

## 🎛️ Modes Overview

```
                      [ Standard | Scientific ]
                                  │
         ┌────────────────────────┴────────────────────────┐
         ▼                                                 ▼
┌─────────────────────────────────┐   ┌─────────────────────────────────┐
│          STANDARD MODE          │   │         SCIENTIFIC MODE         │
├─────────────────────────────────┤   ├─────────────────────────────────┤
│ • Clean 5x4 Grid Layout         │   │ • 7x5 Unified Scientific Keypad │
│ • Large numeric buttons (0-9)   │   │ • Fixed bottom number pad       │
│ • Clear (AC) & Delete (DEL)     │   │ • Direct sin, cos, tan & inverses│
│ • Basic operators (+, −, ×, ÷)  │   │ • Any-base log & comma support  │
│ • Percentage (%) & Sign (+/-)   │   │ • Powers, roots, π, e, brackets │
│ • Quick calculations on the go  │   │ • Advanced Functions Sheet f(x) │
└─────────────────────────────────┘   └─────────────────────────────────┘
```

---

## 💻 Technologies Used

- **Framework**: [Flutter](https://flutter.dev/) (SDK `^3.13.7`)
- **Language**: [Dart](https://dart.dev/)
- **UI Design System**: Material Design 3 with custom OLED gradients and typography
- **State Architecture**: Clean separation between `CalculatorEngine`, `CalculatorController`, and State-driven Flutter widgets
- **Code Quality**: `flutter_lints: ^6.0.0` with strict static analysis

---

## 📁 Project Architecture & Directory Structure

```text
flutter-scientific-calculator/
├── android/                        # Android native configurations, manifest & Gradle
│   ├── app/
│   │   └── build.gradle.kts        # App-level Gradle build configuration
│   └── build.gradle.kts            # Project-level Gradle build configuration
├── bin/
│   └── calculator.dart             # Standalone pure Dart CLI interactive calculator
├── lib/
│   ├── calculator_controller.dart  # State controller managing Ans, memory & history records
│   ├── calculator_engine.dart      # Recursive-descent math parser & evaluator
│   └── main.dart                   # Main Flutter application UI, layouts & gradient buttons
├── test/
│   ├── calculator_engine_test.dart # Comprehensive unit tests for math evaluation engine
│   └── widget_test.dart            # Flutter widget & smoke tests for UI interactions
├── .gitignore                      # Git ignore file for Flutter, Dart, Android & IDEs
├── analysis_options.yaml           # Linting rules & static analysis configuration
├── pubspec.yaml                    # Project metadata, SDK constraints & dependencies
└── README.md                       # Project documentation
```

---

## 🚀 Installation & Setup

### Prerequisites

Ensure you have the following installed on your machine:
- **Flutter SDK**: [Install Flutter](https://docs.flutter.dev/get-started/install) (Version 3.13+ recommended).
- **Dart SDK**: Included with Flutter.
- **Android Studio** or **VS Code** with the Flutter and Dart extensions.
- An **Android Emulator** or physical Android device connected with USB Debugging enabled.

### Verification

Check your local Flutter installation and dependencies:

```bash
flutter doctor
```

### Clone the Repository

```bash
git clone https://github.com/alanbiju422-dev/flutter-scientific-calculator.git
cd flutter-scientific-calculator
```

### Install Dependencies

Fetch all required packages declared in `pubspec.yaml`:

```bash
flutter pub get
```

---

## 📱 Running the Application

The application is structured to run directly through the **Android Emulator** or an active physical device:

### 1. List Available Devices / Emulators

```bash
flutter devices
```

### 2. Launch on Emulator or Device

```bash
flutter run
```

*During execution, press `r` in your terminal for Hot Reload or `R` for Hot Restart.*

---

## 🧪 Automated Testing

The project includes unit test suites verifying both the mathematical calculation logic and the user interface.

### Run All Unit and Widget Tests

```bash
flutter test
```

### Run Math Engine Unit Tests Only

```bash
flutter test test/calculator_engine_test.dart
```

### Run Widget & UI Tests Only

```bash
flutter test test/widget_test.dart
```

### Run Static Code Analysis

Ensure code quality meets strict linting standards:

```bash
flutter analyze
```

---

## 🖥️ Standalone CLI Calculator

For command-line environments or quick terminal calculations, a pure Dart CLI version is included in `bin/calculator.dart`:

```bash
dart run bin/calculator.dart
```

Supports basic arithmetic, percentage, and division-by-zero validation in an interactive terminal prompt.

---

## 🤝 Contributing

Contributions, issues, and feature suggestions are welcome!

1. **Fork** the repository.
2. **Create** your feature branch:
   ```bash
   git checkout -b feature/AmazingFeature
   ```
3. **Commit** your changes:
   ```bash
   git commit -m "Add some AmazingFeature"
   ```
4. **Run tests** to ensure no regressions:
   ```bash
   flutter test
   ```
5. **Push** to the branch:
   ```bash
   git push origin feature/AmazingFeature
   ```
6. **Open a Pull Request**.

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

**Alan Biju**  
- **GitHub Profile**: [@alanbiju422-dev](https://github.com/alanbiju422-dev)  
- **Repository**: [flutter-scientific-calculator](https://github.com/alanbiju422-dev/flutter-scientific-calculator)
