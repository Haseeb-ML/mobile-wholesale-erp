class AuditLog {
  final int? id;
  final String timestamp;
  final String userRole; // 'owner', 'sales', 'accountant'
  final String action; // 'PRICE_OVERRIDE', 'CREDIT_LIMIT_OVERRIDE', 'INVOICE_CANCEL', 'STOCK_ADJUSTMENT', 'DATA_RESTORE', 'OPENING_BALANCE'
  final String entity; // 'Invoice', 'Product', 'Party', 'Database'
  final String? entityId;
  final String details;

  AuditLog({
    this.id,
    required this.timestamp,
    required this.userRole,
    required this.action,
    required this.entity,
    this.entityId,
    required this.details,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'timestamp': timestamp,
      'user_role': userRole,
      'action': action,
      'entity': entity,
      'entity_id': entityId,
      'details': details,
    };
  }

  factory AuditLog.fromMap(Map<String, dynamic> map) {
    return AuditLog(
      id: map['id'] as int?,
      timestamp: map['timestamp'] as String,
      userRole: map['user_role'] as String? ?? 'owner',
      action: map['action'] as String,
      entity: map['entity'] as String,
      entityId: map['entity_id'] as String?,
      details: map['details'] as String,
    );
  }
}

