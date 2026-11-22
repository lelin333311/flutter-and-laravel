import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../config/api_config.dart';
import '../erpModel/party_everything/party_model/party_model.dart';
import '../erpModel/party_everything/services/party_repository.dart';
import '../erpModel/product_everything/product_model/product_model.dart';
import '../erpModel/product_everything/services/product_repository.dart';
import '../erpModel/sales_everything/models/sale.dart';

class SaleSyncException implements Exception {
  final String message;

  const SaleSyncException(this.message);

  @override
  String toString() => message;
}

class LaravelApiService {
  static final LaravelApiService instance = LaravelApiService._init();
  LaravelApiService._init();

  /// 0. Test Connection with Laravel REST API (/api/v1/test)
  Future<Map<String, dynamic>?> testLaravelConnection() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/test');
      debugPrint('Laravel API: GET $url');

      final response = await http
          .get(url, headers: ApiConfig.headers)
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      }
    } catch (e) {
      debugPrint('Laravel GET /test exception: $e');
    }
    return null;
  }

  /// 1. Fetch Parties from Laravel REST API (/api/v1/parties)
  Future<List<Party>> fetchPartiesFromLaravel() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/parties');
      debugPrint('Laravel API: GET $url');

      final response = await http.get(url, headers: ApiConfig.headers);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List data = decoded is List
            ? decoded
            : (decoded['data'] ?? decoded['parties'] ?? []);

        return data
            .map((e) => Party.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        debugPrint(
          'Laravel GET /parties failed: Status ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Laravel GET /parties exception: $e');
    }
    return [];
  }

  /// 2. Fetch Products from Laravel REST API (/api/v1/products)
  Future<List<Product>> fetchProductsFromLaravel() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/products');
      debugPrint('Laravel API: GET $url');

      final response = await http.get(url, headers: ApiConfig.headers);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List data = decoded is List
            ? decoded
            : (decoded['data'] ?? decoded['products'] ?? []);

        return data
            .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        debugPrint(
          'Laravel GET /products failed: Status ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Laravel GET /products exception: $e');
    }
    return [];
  }

  Future<List<Sale>> fetchSalesFromLaravel() async {
    final sales = <Sale>[];
    try {
      for (var page = 1; page <= 100; page++) {
        final url = Uri.parse('${ApiConfig.baseUrl}/sales?page=$page');
        debugPrint('Laravel API: GET $url');
        final response = await http
            .get(url, headers: ApiConfig.headers)
            .timeout(const Duration(seconds: 15));
        if (response.statusCode != 200) {
          throw Exception(
            'Laravel GET /sales failed with status ${response.statusCode}',
          );
        }

        final decoded = jsonDecode(response.body);
        final List data = decoded is List
            ? decoded
            : (decoded is Map
                  ? (decoded['data'] ?? decoded['sales'] ?? [])
                  : []);
        for (final item in data) {
          if (item is Map) {
            sales.add(Sale.fromJson(Map<String, dynamic>.from(item)));
          }
        }

        if (decoded is! Map ||
            decoded['last_page'] == null ||
            page >= (decoded['last_page'] as num).toInt()) {
          break;
        }
      }
    } catch (e) {
      debugPrint('Laravel GET /sales exception: $e');
      rethrow;
    }
    return sales;
  }

  Future<bool> deleteSaleFromLaravel(String invoiceNo) async {
    try {
      final listUrl = Uri.parse('${ApiConfig.baseUrl}/sales');
      final listResponse = await http
          .get(listUrl, headers: ApiConfig.headers)
          .timeout(const Duration(seconds: 15));
      if (listResponse.statusCode != 200) return false;
      final decoded = jsonDecode(listResponse.body);
      final data = decoded is Map
          ? (decoded['data'] ?? const [])
          : (decoded is List ? decoded : const []);
      if (data is! List) return false;
      final matches = data.whereType<Map>().where(
        (item) =>
            (item['sale_number'] ?? item['invoice_no'] ?? '').toString() ==
            invoiceNo,
      );
      if (matches.isEmpty) return false;
      final remoteId = int.tryParse(matches.first['id']?.toString() ?? '');
      if (remoteId == null) return false;
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/sales/$remoteId'),
            headers: ApiConfig.headers,
          )
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Laravel Sale delete failed: $e');
      return false;
    }
  }

  /// Saves invoices to Laravel using the invoice number as an idempotency key.
  Future<bool> syncSaleToLaravel(Sale sale) async {
    try {
      final productRepository = ProductRepository();
      final partyRepository = PartyRepository();
      final party = sale.customerId == 0
          ? null
          : await partyRepository.getLocalPartyById(sale.customerId);
      if (sale.customerId != 0 && party?.serverId == null) {
        throw const SaleSyncException(
          'Customer is not linked to Laravel. Sync the customer first.',
        );
      }

      final items = <Map<String, dynamic>>[];
      for (final item in sale.items) {
        final product = await productRepository.getLocalProductById(
          item.productId,
        );
        if (product?.serverId == null) {
          throw SaleSyncException(
            'Product "${item.productName}" is not linked to Laravel. Sync the product first.',
          );
        }
        items.add({
          'product_id': product!.serverId,
          'product_name': item.productName,
          'product_code': item.productCode,
          'unit': item.unit,
          'quantity': item.quantityPcsBosta,
          'weight_kg_per_unit': item.weightKgPerUnit,
          'total_kg': item.totalKg,
          'unit_price': item.pricePerUnit,
          'price_type': item.priceType,
          'line_total': item.subtotal,
        });
      }

      final paymentMethod = switch (sale.paymentMethod.toLowerCase()) {
        'cash' => 'cash',
        'card' => 'card',
        'bank' => 'bank',
        'mobile banking' || 'mobile_banking' => 'mobile_banking',
        _ => 'other',
      };
      final payload = {
        'sale_number': sale.invoiceNo,
        'party_id': party?.serverId,
        'customer_name': sale.customerName,
        'customer_phone': sale.customerPhone,
        'customer_address': sale.customerAddress,
        'subtotal': sale.subtotal,
        'discount_amount': sale.discountAmount,
        'tax_amount': sale.taxAmount,
        'commission_cost': sale.commissionCost,
        'labor_cost': sale.laborCost,
        'additional_costs': sale.additionalCosts
            .map((cost) => cost.toJson())
            .toList(),
        'total_amount': sale.grandTotal,
        'paid_amount': sale.paidAmount,
        'payment_method': paymentMethod,
        'sale_date': DateFormat('yyyy-MM-dd').format(sale.date),
        'notes': sale.note,
        'items': items,
      };
      final url = Uri.parse('${ApiConfig.baseUrl}/sales/sync');
      debugPrint('Laravel API: POST $url');

      final response = await http
          .post(url, headers: ApiConfig.headers, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Laravel Sale Sync Success: #${sale.invoiceNo}');
        return true;
      }
      throw SaleSyncException(_extractSaleSyncError(response));
    } catch (e) {
      if (e is SaleSyncException) rethrow;
      debugPrint('Laravel POST /sales/sync exception: $e');
      throw SaleSyncException('Laravel sync failed: $e');
    }
  }

  String _extractSaleSyncError(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final errors = decoded['errors'];
        if (errors is Map && errors.isNotEmpty) {
          return errors.values
              .map((value) => value is List ? value.join(', ') : '$value')
              .join('\n');
        }
        if (decoded['message'] != null) {
          return decoded['message'].toString();
        }
      }
    } on FormatException {
      return 'Laravel returned an invalid response (${response.statusCode}).';
    }
    return 'Laravel sale sync failed (${response.statusCode}).';
  }

  /// 4. Sync Single Party to Laravel REST API (/api/v1/parties/sync)
  Future<bool> syncPartyToLaravel(Party party) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/parties/sync');
      debugPrint('Laravel API: POST $url');

      final response = await http.post(
        url,
        headers: ApiConfig.headers,
        body: jsonEncode(party.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Laravel Party Sync Success: #${party.id}');
        return true;
      }
    } catch (e) {
      debugPrint('Laravel POST /parties/sync exception: $e');
    }
    return false;
  }

  /// 5. Sync Single Product to Laravel REST API (/api/v1/products/sync)
  Future<bool> syncProductToLaravel(Product product) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/products/sync');
      debugPrint('Laravel API: POST $url');

      final response = await http.post(
        url,
        headers: ApiConfig.headers,
        body: jsonEncode(product.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
    } catch (e) {
      debugPrint('Laravel POST /products/sync exception: $e');
    }
    return false;
  }
}
