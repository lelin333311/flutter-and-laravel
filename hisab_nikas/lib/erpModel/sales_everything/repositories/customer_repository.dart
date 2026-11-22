import '../../party_everything/party_model/party_model.dart';
import '../../party_everything/services/party_repository.dart' as main_party_repo;

class SalesCustomerRepository {
  final main_party_repo.PartyRepository _mainRepo =
      main_party_repo.PartyRepository();

  Future<List<Party>> fetchCustomers({String? search}) async {
    return await _mainRepo.fetchParties(search: search, type: 'customer');
  }
}
