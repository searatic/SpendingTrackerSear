# SpendingTracker iOS App - Claude Code Context

## Project Overview
A local-only, privacy-focused iOS spending tracker app built with SwiftUI + SwiftData (iOS 17+).

### Core Philosophy
- **Privacy-first**: Everything local, no bank connections, no cloud sync (optional iCloud backup)
- **Fast entry**: Under 10 seconds for manual expense entry
- **Simple UI**: Intuitive, friction-free design

## Architecture
Follow **Swift App Development Master Prompt v1.4** conventions:
- MVVM + SwiftData architecture
- Features/Core/Models folder structure
- @Observable for ViewModels
- Dependency injection via init
- @MainActor for all services using modelContext
- ALWAYS save modelContext with do-catch error handling

### Folder Structure
```
SpendingTracker/
├── App/
│   └── SpendingTrackerApp.swift
├── Core/
│   ├── Database/
│   │   └── DataController.swift
│   ├── Navigation/
│   │   └── Router.swift
│   ├── Services/
│   │   └── OCRService.swift
│   └── Utilities/
├── Features/
│   ├── Expenses/
│   │   ├── Views/
│   │   │   ├── AddExpenseView.swift
│   │   │   ├── ExpenseListView.swift
│   │   │   └── ReceiptScannerView.swift
│   │   ├── ViewModels/
│   │   │   └── AddExpenseViewModel.swift
│   │   └── Services/
│   │       └── ExpenseService.swift
│   ├── Budget/
│   ├── Charts/
│   └── Shared/
│       ├── Views/
│       │   └── CameraView.swift
│       └── Components/
│           └── ExpenseRow.swift
└── Models/
    ├── CategoryModel.swift
    ├── ExpenseModel.swift
    ├── BudgetModel.swift
    └── ReceiptData.swift
```

## Models

### CategoryModel
```swift
@Model: id, name, icon, colorHex, budgetLimit, isDefault, createdAt, expenses
- Uses colorHex: String (NOT color: String)
- Has computed property: var color: Color
- Has static defaultCategories array with 16 categories
```

### ExpenseModel
```swift
@Model: id, amount, category, paymentMethod, location, notes, tags, date, 
        isRecurring, recurringFrequency, isPaymentMethodRequired, 
        receiptPhotoData, createdAt
- PaymentMethod enum: cash, credit, debit (with .icon computed property)
```

### BudgetModel
```swift
@Model: id, category, monthlyLimit, warningThreshold, createdAt
- BudgetStatus enum with .color: Color and .icon properties
```

### ReceiptData
```swift
struct: amount?, location?, date?, items?, rawText?
```

## Current Status: Sprint 2

### ✅ Working Features
- Expense tracking with categories
- Payment method tracking (Cash/Credit/Debit)
- Budget setup with category-specific limits
- Budget warning system (green/yellow/red)
- Charts and visualizations
- CSV export
- Tags and notes
- Recurring expenses
- Search and filtering
- Camera integration
- OCR text extraction

### ❌ Current Issue: SwiftData Migration Error
```
Error Domain=NSCocoaErrorDomain Code=134110 
"An error occurred during persistent store migration."
Validation error missing attribute values on mandatory destination attribute, attribute=colorHex
```

**Root Cause**: CategoryModel schema changed from `color: String` to `colorHex: String`. SwiftData cannot auto-migrate.

**Solution Required**:
1. Add database cleanup code to DataController.swift that deletes old database if migration fails
2. Ensure all model initializers match service signatures exactly
3. Verify Info.plist has camera permissions

### Receipt Scanner Data Flow (Currently Broken)
```
User taps "Add Expense" 
→ AddExpenseView appears
→ User taps "Scan Receipt" button
→ Sheet presents ReceiptScannerView with @Binding params
→ User takes photo with CameraView
→ OCRService.extractReceiptData() processes image
→ Scanner sets pendingScanData & shouldProcessScan = true
→ Sheet dismisses
→ AddExpenseView.onChange detects shouldProcessScan
→ ViewModel.processPendingScan() fills form fields
→ User reviews, adds category, saves
```

**Issue**: The closure onScanComplete is called, but data transfer to AddExpenseViewModel isn't happening. Sheet dismisses before parent view processes scanned data.

## Key Files to Modify

### For Migration Fix:
- `/Core/Database/DataController.swift` - Add database cleanup on migration failure

### For Receipt Scanner Fix:
- `/Features/Expenses/Views/ReceiptScannerView.swift` - Uses @Binding for data transfer
- `/Features/Expenses/Views/AddExpenseView.swift` - Has .sheet and .onChange
- `/Features/Expenses/ViewModels/AddExpenseViewModel.swift` - Has pendingScanData, shouldProcessScan, processPendingScan()

## Critical Rules

### SwiftData
- ALWAYS use do-catch for modelContext.save()
- NEVER ignore save errors
- Place .modelContainer() on NavigationStack, not child views
- Mark services with @MainActor

### Navigation  
- Configure navigation bar ONLY in App entry point
- NEVER use .navigationBarBackButtonHidden() on individual views
- Use Router for programmatic navigation

### OCRService
- Changed from class instance methods to struct static methods
- Use OCRService.extractReceiptData(from:) - returns ReceiptData

## MVP Priority Features
1. ✅ Receipt scanning (OCR) - killer feature (needs data transfer fix)
2. Quick entry with templates
3. Category-specific budgets
4. Basic spending charts by category
5. Trend warnings (spending pace alerts)
6. Optional photo attachments
7. CSV export

## Info.plist Requirements
```xml
NSCameraUsageDescription: "We need camera access to scan receipts"
NSPhotoLibraryUsageDescription: "We need photo library access to attach receipt photos"
```

## Quick Commands for Claude Code
- "Fix the SwiftData migration error" → Update DataController.swift
- "Fix receipt scanner data transfer" → Debug binding-based data flow
- "Add [feature]" → Follow MVVM pattern with proper error handling
- "Show me [file]" → Navigate to specific file
