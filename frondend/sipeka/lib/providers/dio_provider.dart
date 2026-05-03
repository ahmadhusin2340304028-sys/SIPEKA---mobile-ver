import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DioProvider {
  static String get baseApiUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000/api';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000/api';
      default:
        return 'http://127.0.0.1:8000/api';
    }
  }

  // dio_provider.dart — getToken() juga simpan user data
  Future<bool> getToken(String username, String password) async {
    try {
      var response = await Dio().post(
        '$baseApiUrl/login',
        data: {'username': username, 'password': password},
      );

      if (response.statusCode == 200 && response.data != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", response.data['token']);

        // ✅ Simpan juga user data dari response login
        // sehingga tidak perlu request /api/user lagi
        // (opsional tapi lebih efisien)

        return true;
      }
      return false;
    } catch (error) {
      return false;
    }
  }

  Future<void> logout(String token) async {
    await Dio().post(
      '$baseApiUrl/logout',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ),
    );
  }

  // ✅ return Map<String, dynamic>? bukan dynamic
  Future<Map<String, dynamic>?> getUser(String token) async {
    try {
      var response = await Dio().get(
        '$baseApiUrl/user',
        options: Options(
          validateStatus: (status) => status != null && status < 500,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        // ✅ response /api/user punya wrapper 'data'
        // return Map langsung, JANGAN jsonEncode
        final body = response.data;
        if (body['data'] != null) {
          return body['data'] as Map<String, dynamic>;
        }
        // Fallback: kalau response langsung tanpa wrapper
        return body as Map<String, dynamic>;
      }
      return null;
    } catch (error) {
      return null;
    }
  }

  // dio_provider.dart

  // ── Kegiatan ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getDashboardSummary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      print('Fetching dashboard summary with token: $token'); // Debug log

      final response = await Dio().get(
        '$baseApiUrl/dashboard/summary',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      print('Dashboard status: ${response.statusCode}');
      print('Dashboard body: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final body = response.data;
        if (body['success'] == true && body['data'] != null) {
          return body['data'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e, st) {
      // ✅ Jangan catch kosong — print errornya
      print('❌ getDashboardSummary error: $e');
      print('Stack: $st');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getKegiatan({
    String? search,
    String? tahun,
    String? bidang,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await Dio().get(
        '$baseApiUrl/kegiatan',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (tahun != null) 'tahun': tahun,
          if (bidang != null && bidang.isNotEmpty) 'bidang': bidang,
          'page': page,
          'per_page': perPage,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      print('getKegiatan status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final filters = response.data['filters'];
        final bidangOptions = filters is Map
            ? filters['bidang'] as List<dynamic>? ?? const <dynamic>[]
            : const <dynamic>[];

        final body = response.data['data'];
        if (body is Map && body['data'] != null) {
          final list = body['data'] as List<dynamic>? ?? [];
          print('getKegiatan items: ${list.length}');
          int toInt(dynamic value, int fallback) {
            if (value is int) return value;
            if (value is String) return int.tryParse(value) ?? fallback;
            return fallback;
          }

          return {
            'items': list,
            'current_page': toInt(body['current_page'], page),
            'last_page': toInt(body['last_page'], page),
            'per_page': toInt(body['per_page'], perPage),
            'total': toInt(body['total'], list.length),
            'bidang_options': bidangOptions,
          };
        }
        if (body is List) {
          return {
            'items': body,
            'current_page': 1,
            'last_page': 1,
            'per_page': body.length,
            'total': body.length,
            'bidang_options': bidangOptions,
          };
        }
      }
      return null;
    } catch (e, st) {
      print('❌ getKegiatan error: $e'); // ✅ jangan telan error
      print('Stack: $st');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getKegiatanDetail(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await Dio().get(
        '$baseApiUrl/kegiatan/$id',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );
      print('Fetched kegiatan detail data: ${response.data}'); // Debug log

      if (response.statusCode == 200) {
        return response.data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // TAMBAHKAN method-method ini ke class DioProvider yang sudah ada
  // di lib/providers/dio_provider.dart
  // ════════════════════════════════════════════════════════════════════════════

  // ── Tambahkan di dalam class DioProvider, setelah getKegiatanDetail() ────────

  /// GET /api/kegiatan/{id}/realisasi
  /// Mengembalikan data realisasi fisik + anggaran + keterangan + bukti per bulan
  Future<Map<String, dynamic>?> getRealisasiDetail(int kegiatanId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await Dio().get(
        '$baseApiUrl/kegiatan/$kegiatanId/realisasi',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      print('getRealisasiDetail status: ${response.statusCode}');
      print('getRealisasiDetail body: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e, st) {
      print('❌ getRealisasiDetail error: $e\n$st');
      return null;
    }
  }

  /// POST /api/realisasi
  /// Simpan/update realisasi fisik + anggaran + keterangan satu bulan
  Future<bool> postRealisasi({
    required int kegiatanId,
    required int bulan,
    required double realisasiFisik,
    required double realisasiAnggaran,
    String? keterangan,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await Dio().post(
        '$baseApiUrl/realisasi',
        data: {
          'kegiatan_id': kegiatanId,
          'bulan': bulan,
          'realisasi_fisik': realisasiFisik,
          'realisasi_anggaran': realisasiAnggaran,
          if (keterangan != null && keterangan.isNotEmpty)
            'keterangan': keterangan,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('postRealisasi status: ${response.statusCode}');
      print('postRealisasi body: ${response.data}');

      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      print('❌ postRealisasi DioException: ${e.response?.statusCode}');
      print('Response body: ${e.response?.data}');
      return false;
    } catch (e, st) {
      print('❌ postRealisasi error: $e\n$st');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  /// POST /api/upload-bukti
  /// Upload atau ganti file bukti untuk satu kegiatan dan bulan.
  Future<Map<String, dynamic>?> uploadBukti({
    required int kegiatanId,
    required int bulan,
    required String fileName,
    required List<int> fileBytes,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await Dio().post(
        '$baseApiUrl/upload-bukti',
        data: FormData.fromMap({
          'kegiatan_id': kegiatanId,
          'bulan': bulan,
          'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
        }),
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      print('uploadBukti status: ${response.statusCode}');
      print('uploadBukti body: ${response.data}');

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        final body = response.data;
        if (body is Map<String, dynamic>) return body;
        if (body is Map) return Map<String, dynamic>.from(body);
      }
      return null;
    } on DioException catch (e) {
      print('uploadBukti DioException: ${e.response?.statusCode}');
      print('Response body: ${e.response?.data}');
      return null;
    } catch (e, st) {
      print('uploadBukti error: $e\n$st');
      return null;
    }
  }

  // FILE DioProvider LENGKAP (ganti seluruh file dengan ini)
  // ════════════════════════════════════════════════════════════════════════════

  /*
  import 'package:dio/dio.dart';
  import 'package:shared_preferences/shared_preferences.dart';

  class DioProvider {
    // ... semua method yang sudah ada ...
    
    // Tambahkan kedua method di atas
  }
  */
}
