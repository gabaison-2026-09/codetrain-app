import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import 'home_response_dto.dart';
import 'me_response_dto.dart';

class HomeRemoteDataSource {
  const HomeRemoteDataSource(this._client);

  final ApiClient _client;

  Future<MeResponseDto> fetchMe() async {
    final json = expectJsonObject(await _client.get('/v1/me'));
    return parseApiResponse(() => MeResponseDto.fromJson(json));
  }

  Future<MeResponseDto> provisionMe({
    required String displayName,
    String? avatarUrl,
  }) async {
    final json = expectJsonObject(
      await _client.post(
        '/v1/me',
        body: {
          'display_name': displayName,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
        },
      ),
    );
    return parseApiResponse(() => MeResponseDto.fromJson(json));
  }

  Future<MeUserDto> updateMe({String? displayName, String? avatarUrl}) async {
    final json = expectJsonObject(
      await _client.patch(
        '/v1/me',
        body: {
          if (displayName != null) 'display_name': displayName,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
        },
      ),
    );
    return parseApiResponse(() => MeUserDto.fromJson(json));
  }

  Future<MeStatsResponseDto> fetchStats() async {
    final json = expectJsonObject(await _client.get('/v1/me/stats'));
    return parseApiResponse(() => MeStatsResponseDto.fromJson(json));
  }

  Future<HomeResponseDto> fetchHome() async {
    final json = expectJsonObject(await _client.get('/v1/home'));
    return parseApiResponse(() => HomeResponseDto.fromJson(json));
  }
}
