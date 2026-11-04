# Mobile Wholesale ERP (Pakistan)

A complete, production-grade, offline-first mobile accessories wholesale ERP application built for Android with Flutter, Dart, and on-device SQLite. Designed specifically for wholesale markets in Pakistan (Hall Road Lahore, Saddar Karachi, Raja Bazaar Rawalpindi, etc.).

---

## 🌟 Core Architecture & Principles

1. **100% Offline-First (Zero Remote Dependencies)**:
   - Complete functionality operates with WiFi/Mobile data disconnected.
   - Real on-device SQLite database with strict foreign keys, atomic transactions, and custom indexes.
   - Fully separated `erp_demo.db` (seeded exploration) and `erp_real.db` (clean production business data).
   - Bundled offline product rendering assets and Noto Nastaliq Urdu font.

2. **Precise Wholesale Financial Arithmetic**:
   - **Integer Paisa Precision**: All monetary values are strictly stored and computed as integer paisas (1 PKR = 100 paisas), completely avoiding floating-point IEEE 754 rounding drift.
   - **Moving Weighted-Average Inventory Costing**: Real-time perpetual inventory valuation recalculates cost-per-piece on every purchase receipt and snapshots historical COGS on every sale line.
   - **Atomic Multi-Table Posting**: Sales, purchases, payments, returns, adjustments, and expense entries execute within isolated SQLite transactions.
   - **Double-Counting Protection**: Customer receipts reduce accounts receivable without inflating sales revenue; supplier payments settle bills without inflating purchase expense.

3. **Units & Pack Conversions**:
   - Primary inventory tracked in base **Pieces**.
   - Transactional entry supports **Piece**, **Dozen** (12 pieces), and **Box / Carton** (customizable per SKU, e.g. 50 pcs/box).
   - Quantity-based tiered pricing dynamically applies when order quantity meets or exceeds SKU thresholds.

4. **Product Pictures & Image Pipeline**:
   - Optional photos: Add, edit, purchase, and sell products without requiring an image.
   - Bundled 16 offline vector-grade accessory renders covering Chargers, Cables, Earbuds, Power Banks, Glass, and Holders.
   - User gallery & camera imports are safely compressed and copied into persistent app-owned storage (`app_documents/photos/`), avoiding temporary picker URI leaks.

5. **Urdu Localization & Clean RTL Typography**:
   - Native Urdu translation toggle with full Right-To-Left layout mirroring.
   - Embedded Noto Nastaliq Urdu font with cleanly isolated Western 0-9 digits and PKR currency symbols.

6. **Safety & Audit Controls**:
   - **Role-Based Access Control**: Owner, Manager, Salesman roles with SHA-256 salted PIN security.
   - **Tamper-Evident Audit Logs**: Critical actions (credit limit overrides, price modifications, stock write-offs) are logged with timestamp, user role, and justification notes.
   - **Portable Backup & Restore**: Exports `.mwzip` archive containing SQLite database, image folder, and a SHA-256 cryptographic manifest.

---

## 📱 App Navigation & Feature Set

### 1. Home Dashboard
- KPI Summary Cards: Today's Sales, Cash in Shop, Bank Balance, Customer Receivables, Supplier Payables, Low-Stock Alert.
- Quick Actions: **New Sale**, **New Purchase**, **Receive Payment**, **Pay Supplier**, **Add Expense**.
- Role switcher and Demo/Real mode badge.

### 2. Stock & Catalog
- 36 Realistic Pakistani wholesale accessory SKUs (Anker 20W Fast Charger, Baseus 100W Type-C Braided Cable, Audionic Airbud 550, Ronin R-9 Power Bank 10,000mAh, 9D Tempered Glass for iPhone/Redmi, etc.).
- Search by SKU, Barcode, Compatibility, Category, or Color.
- Filter by All, Active, Low Stock, or Out of Stock.
- Stock Adjustments: Cycle count physical corrections and write-offs with audit notes.
- Detailed Stock Movement History per product.

### 3. Wholesale Sales & POS Billing
- Fast customer selection (Cash Wholesale Dealer or named credit accounts).
- Grid / List product picker with live image renders, pack unit selection (Piece, Dozen, Box), and dynamic tiered pricing.
- Line discount, overall bill discount, and optional tax rate handling.
- Payment terms: Cash, Bank, Unpaid Credit, or Partial Payment.
- Credit limit enforcement with Manager/Owner PIN override.
- Professional A4 PDF Invoice Generation with direct print and share support.

### 4. Purchases & Inward Shipments
- Supplier purchase order drafting and immediate atomic posting.
- Freight cost allocation and purchase discounts.
- Settlement status tracking (Paid, Unpaid, Partial).
- Moving average unit cost auto-updating.

### 5. Parties & Ledger
- Customers & Suppliers Directory with debt indicators ("Customer owes us" / "We owe supplier").
- Chronological Running Ledger showing debits, credits, and progressive running balance.
- Multi-invoice payment allocation modal with unapplied excess retained as customer advance.

### 6. Cash, Bank & Expense Management
- Independent Cash in Shop and Bank Account ledgers.
- Funds transfer between accounts.
- Categorized business expense recording (Rent, Utilities, Staff Tea/Food, Delivery Transport, Packaging).

### 7. Returns & Reversals
- Sales Returns: Restocks saleable items to sellable inventory; routes damaged returns to quarantine/damaged stock pool.
- Purchase Returns: Settles supplier payable liability and decreases stock at current average cost.

### 8. Financial Reports & Analytics
- **Profit & Loss Statement**: Gross Sales, Returns, Net Revenue, Cost of Goods Sold (COGS), Gross Profit, Operating Expenses, Net Operating Profit.
- **Stock Valuation Report**: FIFO/Weighted-Average valuation breakdown with one-tap CSV export.

### 9. Backup, Restore & System Settings
- Export full portable encrypted `.mwzip` archive.
- Atomic restore with automated pre-restore rollback backup.
- Shop profile configuration (Shop Name, Address, Phone, Invoice Footer).
- Language toggle (English / اردو).
- PIN Management and Reset Demo Database actions.

---

## 🧪 Automated Verification & Test Coverage

The project includes an end-to-end automated testing suite verifying every mandated requirement:

1. **`test/accounting_scenario_test.dart`**:
   - Verifies the exact numerical scenario:
     - 100 pcs opening stock @ PKR 200 (Value: PKR 20,000)
     - 50 pcs purchase @ PKR 260 on credit (New weighted cost: PKR 220, Stock: 150 pcs, Inventory: PKR 33,000, Supplier Payable: PKR 13,000, Cash: PKR 0)
     - Sale of 2 dozen (24 pcs) @ PKR 300 per pc, PKR 2,000 paid in cash (Revenue: PKR 7,200, Customer Due: PKR 5,200, Remaining Stock: 126 pcs, COGS: PKR 5,280, Gross Profit: PKR 1,920, Cash: PKR 2,000)
     - Customer cash receipt of PKR 1,000 (Customer Due: PKR 4,200, Cash: PKR 3,000, Sales/Profit unchanged)
     - Expense of PKR 500 paid in cash (Cash: PKR 2,500, Period Net Profit: PKR 1,420).
2. **`test/offline_assets_verification_test.dart`**:
   - Asserts that all 16 offline accessory image files exist on disk, contain valid PNG file headers, and load without runtime downloads.
3. **`test/unit_conversion_pricing_test.dart`**:
   - Asserts piece, dozen, and box arithmetic integrity, rejects fractional pieces, and checks tier volume pricing triggers.
4. **`test/widget_test.dart`**:
   - Asserts that the main widget tree and localization providers mount cleanly.

To execute tests:
```bash
flutter test
```

To run static analysis:
```bash
flutter analyze
```

---

## 📦 Building the Android APK

```bash
flutter build apk --debug
# or
flutter build apk --release
```
The output APK is generated at:
`build/app/outputs/flutter-apk/app-debug.apk` (or `app-release.apk`).
