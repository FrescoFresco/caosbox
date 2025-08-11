import 'package:caosbox/domain/search/search_models.dart';

class TabSearchController {
  String quickQuery = '';
  SearchSpec spec = const SearchSpec();

  TabSearchController();

  void setQuick(String q) { quickQuery = q; }
  void setSpec(SearchSpec s) { spec = s; }
}
