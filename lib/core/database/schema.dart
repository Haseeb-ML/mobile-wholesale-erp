class AppSchema {
  static const int currentVersion = 1;

  static const List<String> createTables = [
    // 1. Settings Table
    '''
    CREATE TABLE IF NOT EXISTS shop_settings (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      shop_name TEXT NOT NULL,
      address TEXT NOT NULL,
      phone TEXT NOT NULL,
      logo_path TEXT,
      invoice_footer TEXT NOT NULL,
      default_tax_percent REAL DEFAULT 0.0,
      currency TEXT DEFAULT 'PKR',
      language TEXT DEFAULT 'en',
      owner_pin_hash TEXT,
      owner_pin_salt TEXT,
      active_role TEXT DEFAULT 'owner',
      last_backup_date TEXT
    );
    ''',

    // 2. Financial Accounts (Cash, Bank)
    '''
    CREATE TABLE IF NOT EXISTS financial_accounts (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      type TEXT NOT NULL,
      balance_paisa INTEGER NOT NULL DEFAULT 0,
      account_number TEXT,
      bank_name TEXT
    );
    ''',

    // 3. Products Table
    '''
    CREATE TABLE IF NOT EXISTS products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sku TEXT NOT NULL UNIQUE,
      barcode TEXT,
      name TEXT NOT NULL,
      category TEXT NOT NULL,
      brand TEXT,
      compatible_model TEXT,
      color_spec TEXT,
      image_path TEXT,
      pieces_per_box INTEGER NOT NULL DEFAULT 50,
      cost_price_paisa INTEGER NOT NULL DEFAULT 0,
      wholesale_price_paisa INTEGER NOT NULL DEFAULT 0,
      min_selling_price_paisa INTEGER NOT NULL DEFAULT 0,
      reorder_level INTEGER NOT NULL DEFAULT 10,
      tier_min_qty INTEGER,
      tier_price_paisa INTEGER,
      current_stock_pieces INTEGER NOT NULL DEFAULT 0,
      damaged_stock_pieces INTEGER NOT NULL DEFAULT 0,
      is_active INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );
    ''',

    // 4. Parties Table (Customers & Suppliers)
    '''
    CREATE TABLE IF NOT EXISTS parties (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      type TEXT NOT NULL,
      name TEXT NOT NULL,
      contact_person TEXT,
      phone TEXT NOT NULL,
      city TEXT,
      address TEXT,
      credit_limit_paisa INTEGER NOT NULL DEFAULT 0,
      payment_terms TEXT,
      opening_balance_paisa INTEGER NOT NULL DEFAULT 0,
      current_balance_paisa INTEGER NOT NULL DEFAULT 0,
      notes TEXT,
      is_active INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );
    ''',

    // 5. Invoices Table
    '''
    CREATE TABLE IF NOT EXISTS invoices (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      invoice_number TEXT NOT NULL UNIQUE,
      date TEXT NOT NULL,
      customer_id INTEGER,
      customer_name TEXT NOT NULL,
      customer_phone TEXT,
      status TEXT NOT NULL,
      payment_status TEXT NOT NULL,
      subtotal_paisa INTEGER NOT NULL,
      discount_paisa INTEGER NOT NULL DEFAULT 0,
      tax_paisa INTEGER NOT NULL DEFAULT 0,
      grand_total_paisa INTEGER NOT NULL,
      paid_paisa INTEGER NOT NULL DEFAULT 0,
      due_paisa INTEGER NOT NULL DEFAULT 0,
      total_cost_paisa INTEGER NOT NULL DEFAULT 0,
      payment_method TEXT NOT NULL DEFAULT 'cash',
      notes TEXT,
      created_by TEXT NOT NULL DEFAULT 'Owner',
      created_at TEXT NOT NULL,
      FOREIGN KEY (customer_id) REFERENCES parties (id) ON DELETE RESTRICT
    );
    ''',

    // 6. Invoice Items Table
    '''
    CREATE TABLE IF NOT EXISTS invoice_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      invoice_id INTEGER NOT NULL,
      product_id INTEGER NOT NULL,
      sku TEXT NOT NULL,
      product_name TEXT NOT NULL,
      color_spec TEXT,
      image_path TEXT,
      pack_unit TEXT NOT NULL,
      pack_qty INTEGER NOT NULL,
      pieces_per_pack INTEGER NOT NULL,
      total_pieces INTEGER NOT NULL,
      unit_price_paisa INTEGER NOT NULL,
      line_discount_paisa INTEGER NOT NULL DEFAULT 0,
      net_total_paisa INTEGER NOT NULL,
      cost_per_piece_paisa INTEGER NOT NULL,
      total_cost_paisa INTEGER NOT NULL,
      FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE,
      FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE RESTRICT
    );
    ''',

    // 7. Purchases Table
    '''
    CREATE TABLE IF NOT EXISTS purchases (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      ref_number TEXT NOT NULL UNIQUE,
      date TEXT NOT NULL,
      supplier_id INTEGER NOT NULL,
      supplier_name TEXT NOT NULL,
      status TEXT NOT NULL,
      payment_status TEXT NOT NULL,
      subtotal_paisa INTEGER NOT NULL,
      discount_paisa INTEGER NOT NULL DEFAULT 0,
      freight_paisa INTEGER NOT NULL DEFAULT 0,
      grand_total_paisa INTEGER NOT NULL,
      paid_paisa INTEGER NOT NULL DEFAULT 0,
      due_paisa INTEGER NOT NULL DEFAULT 0,
      payment_method TEXT NOT NULL DEFAULT 'credit',
      notes TEXT,
      created_at TEXT NOT NULL,
      FOREIGN KEY (supplier_id) REFERENCES parties (id) ON DELETE RESTRICT
    );
    ''',

    // 8. Purchase Items Table
    '''
    CREATE TABLE IF NOT EXISTS purchase_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      purchase_id INTEGER NOT NULL,
      product_id INTEGER NOT NULL,
      sku TEXT NOT NULL,
      product_name TEXT NOT NULL,
      color_spec TEXT,
      pack_unit TEXT NOT NULL,
      pack_qty INTEGER NOT NULL,
      pieces_per_pack INTEGER NOT NULL,
      total_pieces INTEGER NOT NULL,
      unit_rate_paisa INTEGER NOT NULL,
      line_discount_paisa INTEGER NOT NULL DEFAULT 0,
      net_total_paisa INTEGER NOT NULL,
      FOREIGN KEY (purchase_id) REFERENCES purchases (id) ON DELETE CASCADE,
      FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE RESTRICT
    );
    ''',

    // 9. Party Payments Table (Receipts & Payments)
    '''
    CREATE TABLE IF NOT EXISTS party_payments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      payment_type TEXT NOT NULL,
      receipt_number TEXT NOT NULL UNIQUE,
      date TEXT NOT NULL,
      party_id INTEGER NOT NULL,
      party_name TEXT NOT NULL,
      amount_paisa INTEGER NOT NULL,
      account_type TEXT NOT NULL DEFAULT 'cash',
      ref_number TEXT,
      notes TEXT,
      created_at TEXT NOT NULL,
      FOREIGN KEY (party_id) REFERENCES parties (id) ON DELETE RESTRICT
    );
    ''',

    // 10. Expenses Table
    '''
    CREATE TABLE IF NOT EXISTS expenses (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      category TEXT NOT NULL,
      amount_paisa INTEGER NOT NULL,
      account_id TEXT NOT NULL DEFAULT 'cash',
      date TEXT NOT NULL,
      notes TEXT,
      created_at TEXT NOT NULL,
      FOREIGN KEY (account_id) REFERENCES financial_accounts (id) ON DELETE RESTRICT
    );
    ''',

    // 11. Inventory Movements Ledger
    '''
    CREATE TABLE IF NOT EXISTS inventory_movements (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      product_id INTEGER NOT NULL,
      sku TEXT NOT NULL,
      product_name TEXT NOT NULL,
      movement_type TEXT NOT NULL,
      qty_pieces INTEGER NOT NULL,
      unit_cost_paisa INTEGER NOT NULL,
      total_cost_paisa INTEGER NOT NULL,
      ref_id INTEGER,
      ref_number TEXT,
      date TEXT NOT NULL,
      reason TEXT,
      created_at TEXT NOT NULL,
      FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE RESTRICT
    );
    ''',

    // 12. Party Running Ledger
    '''
    CREATE TABLE IF NOT EXISTS party_ledger (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      party_id INTEGER NOT NULL,
      date TEXT NOT NULL,
      type TEXT NOT NULL,
      ref_id INTEGER,
      ref_number TEXT,
      debit_paisa INTEGER NOT NULL DEFAULT 0,
      credit_paisa INTEGER NOT NULL DEFAULT 0,
      running_balance_paisa INTEGER NOT NULL,
      notes TEXT,
      created_at TEXT NOT NULL,
      FOREIGN KEY (party_id) REFERENCES parties (id) ON DELETE RESTRICT
    );
    ''',

    // 13. Financial Account Ledger
    '''
    CREATE TABLE IF NOT EXISTS account_transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      account_id TEXT NOT NULL,
      date TEXT NOT NULL,
      type TEXT NOT NULL,
      ref_id INTEGER,
      ref_number TEXT,
      debit_paisa INTEGER NOT NULL DEFAULT 0,
      credit_paisa INTEGER NOT NULL DEFAULT 0,
      running_balance_paisa INTEGER NOT NULL,
      notes TEXT,
      created_at TEXT NOT NULL,
      FOREIGN KEY (account_id) REFERENCES financial_accounts (id) ON DELETE RESTRICT
    );
    ''',

    // 14. Stock Adjustments Table
    '''
    CREATE TABLE IF NOT EXISTS stock_adjustments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      product_id INTEGER NOT NULL,
      sku TEXT NOT NULL,
      product_name TEXT NOT NULL,
      old_qty_pieces INTEGER NOT NULL,
      new_qty_pieces INTEGER NOT NULL,
      diff_qty_pieces INTEGER NOT NULL,
      cost_per_piece_paisa INTEGER NOT NULL,
      total_cost_impact_paisa INTEGER NOT NULL,
      reason TEXT NOT NULL,
      date TEXT NOT NULL,
      created_by TEXT NOT NULL DEFAULT 'Owner',
      created_at TEXT NOT NULL,
      FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE RESTRICT
    );
    ''',

    // 15. Return Orders Table
    '''
    CREATE TABLE IF NOT EXISTS return_orders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      return_type TEXT NOT NULL,
      return_number TEXT NOT NULL UNIQUE,
      original_document_id INTEGER NOT NULL,
      original_document_number TEXT NOT NULL,
      party_id INTEGER NOT NULL,
      party_name TEXT NOT NULL,
      date TEXT NOT NULL,
      total_credit_paisa INTEGER NOT NULL,
      refunded_cash_paisa INTEGER NOT NULL DEFAULT 0,
      notes TEXT,
      created_at TEXT NOT NULL,
      FOREIGN KEY (party_id) REFERENCES parties (id) ON DELETE RESTRICT
    );
    ''',

    // 16. Return Items Table
    '''
    CREATE TABLE IF NOT EXISTS return_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      return_order_id INTEGER NOT NULL,
      product_id INTEGER NOT NULL,
      sku TEXT NOT NULL,
      product_name TEXT NOT NULL,
      pack_unit TEXT NOT NULL,
      pack_qty INTEGER NOT NULL,
      pieces_per_pack INTEGER NOT NULL,
      total_pieces INTEGER NOT NULL,
      is_saleable INTEGER NOT NULL DEFAULT 1,
      unit_credit_rate_paisa INTEGER NOT NULL,
      net_credit_paisa INTEGER NOT NULL,
      cost_per_piece_paisa INTEGER NOT NULL,
      FOREIGN KEY (return_order_id) REFERENCES return_orders (id) ON DELETE CASCADE,
      FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE RESTRICT
    );
    ''',

    // 17. Audit Logs Table
    '''
    CREATE TABLE IF NOT EXISTS audit_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      timestamp TEXT NOT NULL,
      user_role TEXT NOT NULL,
      action TEXT NOT NULL,
      entity TEXT NOT NULL,
      entity_id TEXT,
      details TEXT NOT NULL
    );
    '''
  ];

  static const List<String> createIndexes = [
    'CREATE INDEX IF NOT EXISTS idx_products_sku ON products (sku);',
    'CREATE INDEX IF NOT EXISTS idx_products_barcode ON products (barcode);',
    'CREATE INDEX IF NOT EXISTS idx_products_category ON products (category);',
    'CREATE INDEX IF NOT EXISTS idx_invoices_date ON invoices (date);',
    'CREATE INDEX IF NOT EXISTS idx_invoices_customer ON invoices (customer_id);',
    'CREATE INDEX IF NOT EXISTS idx_invoices_status ON invoices (status);',
    'CREATE INDEX IF NOT EXISTS idx_purchases_date ON purchases (date);',
    'CREATE INDEX IF NOT EXISTS idx_purchases_supplier ON purchases (supplier_id);',
    'CREATE INDEX IF NOT EXISTS idx_movements_prod ON inventory_movements (product_id);',
    'CREATE INDEX IF NOT EXISTS idx_movements_date ON inventory_movements (date);',
    'CREATE INDEX IF NOT EXISTS idx_party_ledger_party ON party_ledger (party_id);',
    'CREATE INDEX IF NOT EXISTS idx_party_ledger_date ON party_ledger (date);',
    'CREATE INDEX IF NOT EXISTS idx_acc_trans_acc ON account_transactions (account_id);',
    'CREATE INDEX IF NOT EXISTS idx_acc_trans_date ON account_transactions (date);',
  ];
}

