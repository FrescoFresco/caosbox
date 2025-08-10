Map<String, dynamic> caosSchemaV2() => {
  'fields': {
    'type': {'kind': 'enum', 'values': ['idea', 'action']},
    'status': {'kind': 'enum', 'values': ['normal', 'completed', 'archived']},
    'id': {'kind': 'text'},
    'content': {'kind': 'text'},
    'note': {'kind': 'text'},
  }
};
