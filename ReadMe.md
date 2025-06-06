# AR Visualizer App

> A comprehensive test application for deep understanding of augmented reality technologies in the iOS ecosystem

## 📱 Description

AR Visualizer App is a comprehensive test application developed for studying and demonstrating the capabilities of augmented reality technologies on the iOS platform. The application allows you to place, manage, and interact with 3D models in real-time.

### 🎯 Project Goals

- **Deep ARKit Study** — understanding architecture and operational principles
- **Performance Optimization** — researching methods to improve FPS and stability
- **Memory Management** — studying efficient patterns for AR applications
- **UX/UI for AR** — creating intuitive interfaces for three-dimensional interaction
- **Architectural Patterns** — applying MVVM, Combine, and modern SwiftUI approaches

## 🛠 Technology Stack

### Core Technologies

| Technology | Version | Purpose |
|------------|---------|---------|
| **Swift** | 5.9+ | Primary development language |
| **SwiftUI** | 4.0+ | Declarative UI framework |
| **ARKit** | 4.0+ | Augmented reality |
| **RealityKit** | 2.0+ | 3D rendering and physics |
| **Combine** | - | Reactive programming |
| **AVFoundation** | - | Camera access |

### Architectural Components

- **MVVM (Model-View-ViewModel)** — primary architectural pattern
- **ObservableObject** — state management
- **@StateObject/@ObservedObject** — data binding
- **Dependency Injection** — dependency injection
- **Repository Pattern** — data work abstraction

## 🏗 Application Architecture

### Core Modules

```
ARVisualizerApp/
├── 📁 Core/
│   ├── ARSessionManager.swift      # AR session management
│   ├── ModelCacheService.swift     # 3D model caching
│   └── ProceduralModelFactory.swift # Procedural model generation
├── 📁 Models/
│   ├── ARModel.swift               # AR object data model
│   ├── PlacedModel.swift           # Placed model in scene
│   └── AppConfig.swift             # Application configuration
├── 📁 Views/
│   ├── ContentView.swift           # Main screen
│   ├── ARViewContainer.swift       # ARView container
│   ├── ModelControlsView.swift     # Model control interface
│   └── UI Components/              # Reusable components
├── 📁 Services/
│   ├── ModelDataService.swift      # Model data service
│   └── PowerManagementService.swift # Power management
└── 📁 Resources/
    └── 3D Models/                  # USDZ model files
```

### Key Patterns

#### 1. **Reactive Data Flow**
```swift
@MainActor
class ARSessionManager: ObservableObject {
    @Published var placedModels: [PlacedModel] = []
    @Published var sessionState: ARSessionState = .notStarted
    @Published var isLoading = false
}
```

#### 2. **Memory Management**
```swift
class ModelCacheService {
    private var cachedEntities: [String: ModelEntity] = [:]
    private var lastUsed: [String: Date] = [:]
    
    func clearUnusedCache() {
        // Automatic cleanup of unused models
    }
}
```

#### 3. **Performance Optimization**
```swift
private func optimizeARViewSettings(_ arView: ARView) {
    arView.renderOptions = [
        .disablePersonOcclusion,
        .disableDepthOfField,
        .disableHDR
    ]
}
```

## 🚀 Key Features

### AR Functionality
- ✅ **Plane Detection** — automatic detection of horizontal surfaces
- ✅ **Model Placement** — precise object positioning through raycast
- ✅ **Transform Management** — scaling, rotation, movement
- ✅ **State Tracking** — monitoring AR tracking quality
- ✅ **Gesture Control** — tap to place, long press to delete

### Model Management
- ✅ **Categorization** — furniture, electronics, decorations, vehicles, architecture
- ✅ **Caching** — efficient reuse of loaded models
- ✅ **Procedural Generation** — creating fallback models when files are missing
- ✅ **Animations** — support for animated objects
- ✅ **Limitations** — performance-based object count control

### User Interface
- ✅ **Adaptive Design** — optimization for different screen sizes
- ✅ **Dark Theme** — modern dark design
- ✅ **Contextual Controls** — on-demand control elements
- ✅ **Status Indicators** — visual feedback about system state
- ✅ **Instructions** — built-in help for new users

## 📋 Requirements

### System Requirements
- **iOS**: 13.0+
- **Device**: iPhone 6s / iPad (5th generation) or newer
- **Processor**: A9 or newer (for ARKit support)
- **Memory**: 2GB+ RAM recommended

### Development
- **Xcode**: 15.0+
- **Swift**: 5.9+
- **macOS**: 13.0+ (for development)

## 🔧 Installation and Setup

### 1. Clone Repository
```bash
git clone https://github.com/your-username/ar-visualizer-app.git
cd ar-visualizer-app
```

### 2. Open Project
```bash
open ARVisualizerApp.xcodeproj
```

### 3. Configure Team ID
1. Select project in Xcode Navigator
2. In "Signing & Capabilities" section, select your development team
3. Ensure Bundle Identifier is unique

### 4. Add 3D Models (Optional)
Place USDZ files in `Resources/3D Models/` folder to replace procedural models.

## 🎮 Usage

### Basic Operations
1. **Launch App** — automatic camera permission request
2. **Surface Scanning** — slowly move device to detect planes
3. **Model Selection** — tap "Add" and choose object
4. **Placement** — touch detected surface
5. **Editing** — tap placed model for controls

### Model Management
- **Scaling**: "Scale" slider (0.1x - 3.0x)
- **Rotation**: "Rotation" slider (0° - 360°) or "90°" button
- **Positioning**: Separate controls for X, Y, Z axes
- **Quick Actions**: Buttons for doubling/halving scale
- **Reset**: Return to original parameters

### Gestures
- **Single Tap**: Select model or place new one
- **Long Press**: Delete model
- **Device Movement**: Update AR tracking

## 🔬 Research Concepts

### ARKit Advanced
- **World Tracking Configuration** — tracking parameter setup
- **Plane Detection** — surface detection algorithms
- **Raycast Queries** — different types of ray queries
- **Anchor Management** — 3D space anchor management
- **Session State Management** — AR session lifecycle

### RealityKit Deep Dive
- **Entity Component System** — object architecture
- **Transform Hierarchy** — transformation hierarchy
- **Material System** — materials and textures system
- **Animation System** — built-in animation system
- **Collision Detection** — collision detection

### Performance Engineering
- **Memory Management** — efficient memory management for AR
- **Frame Rate Optimization** — maintaining stable 60 FPS
- **Asset Loading** — asynchronous loading and caching
- **Gesture Debouncing** — preventing excessive operations
- **Background Processing** — background computation optimization

### SwiftUI Modern Patterns
- **State Management** — using @StateObject, @ObservedObject
- **Combine Integration** — reactive data streams
- **Animation System** — built-in SwiftUI animations
- **Custom Modifiers** — reusable modifiers
- **Environment Objects** — global state

## 📊 Performance Metrics

### Target Metrics
- **FPS**: 30-60 stable frames per second
- **Memory**: <200MB with 6 active models
- **Load Time**: <2 seconds for AR startup
- **Responsiveness**: <100ms delay for user actions

### Monitoring Tools
- **Xcode Instruments** — memory and CPU profiling
- **ARKit Debug Options** — AR data visualization
- **Console Logging** — detailed event logging
- **Performance HUD** — built-in FPS metrics

## 🧪 Testing

### Test Scenarios
1. **Basic Flow**: Launch → place → manage → delete
2. **Stress Test**: Place maximum number of models
3. **Memory**: Long-term usage with leak monitoring
4. **Screen Rotation**: Behavior during orientation changes
5. **Background Mode**: Proper pause/resume of AR

### Testing Devices
- **iPhone 12/13/14/15** — primary target audience
- **iPhone SE 3** — minimum performance requirements
- **iPad Air/Pro** — large screens and performance
- **iPhone 6s/7/8** — legacy support

## 🚀 Development Plans

### Short-term Improvements
- [ ] **Persistence** — saving placed objects between sessions
- [ ] **Sharing** — AR scene export
- [ ] **Scale Gestures** — pinch-to-scale directly in AR
- [ ] **Physics Simulation** — gravity and collisions
- [ ] **Lighting** — dynamic environment-based lighting

### Long-term Goals
- [ ] **ARKit 6 Features** — new iOS 17+ capabilities
- [ ] **Collaborative AR** — multi-user sessions
- [ ] **Machine Learning** — object recognition
- [ ] **Cloud Integration** — iCloud synchronization
- [ ] **Apple Vision Pro** — visionOS adaptation

## 📚 Educational Value

### Technologies Studied
1. **ARKit Framework** — full spectrum of augmented reality capabilities
2. **RealityKit** — Apple's modern 3D engine
3. **SwiftUI** — declarative user interfaces
4. **Combine** — functional reactive programming
5. **Concurrency** — async/await patterns in Swift
6. **Memory Management** — ARC and resource management
7. **Performance Optimization** — profiling and optimization

### Development Skills
- ✅ **3D Mathematics** — working with matrices, quaternions, vectors
- ✅ **Computer Vision** — understanding machine vision principles
- ✅ **Real-time Rendering** — optimization for 60 FPS
- ✅ **Touch Interfaces** — developing intuitive gestures
- ✅ **State Management** — application architecture with state
- ✅ **Debugging AR** — AR-specific debugging techniques

## 🤝 Contributing

This is a test project for learning and experimentation. Welcome:

- **Pull Requests** with performance improvements
- **Issues** describing found problems
- **Discussions** about architectural decisions
- **Forks** for your own experiments

## 📄 License

This project is distributed under the MIT License. See [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Vlad**

---

*This project is created exclusively for educational purposes for deep study of augmented reality technologies in the Apple ecosystem.*
