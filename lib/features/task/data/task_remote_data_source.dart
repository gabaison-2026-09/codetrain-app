import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../domain/task_configuration.dart';
import 'task_slots_response_dto.dart';

class TaskRemoteDataSource {
  const TaskRemoteDataSource(this._client);

  final ApiClient _client;

  Future<TaskSlotsResponseDto> fetchSlots() async {
    final json = expectJsonObject(await _client.get('/v1/task-slots'));
    return parseApiResponse(() => TaskSlotsResponseDto.fromJson(json));
  }

  Future<TaskSlotDto> saveSlot(TaskSlot slot) async {
    final dto = TaskSlotDto.fromDomain(slot);
    final json = expectJsonObject(
      await _client.put(
        '/v1/task-slots/${slot.slotNo}',
        body: dto.toRequestJson(),
      ),
    );
    return parseApiResponse(() => TaskSlotDto.fromJson(json));
  }

  Future<void> deleteSlot(int slotNo) async {
    await _client.delete('/v1/task-slots/$slotNo');
  }

  Future<TaskOptionsResponseDto> fetchOptions() async {
    final json = expectJsonObject(
      await _client.get('/v1/task-slots/options'),
    );
    return parseApiResponse(() => TaskOptionsResponseDto.fromJson(json));
  }
}
