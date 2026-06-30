import 'package:social_gallery/data/repositories/travel_mode_repository.dart';
import 'package:social_gallery/domain/models/travel_mode.dart';

/// CRUD and active-trip lookup for auto-sorting new media into trip folders.
class TravelModeUseCase {
  TravelModeUseCase(this._repository);

  final TravelModeRepository _repository;

  Stream<TravelMode?> watchActive() => _repository.watchActive();

  Stream<List<TravelMode>> watchAll() => _repository.watchAll();

  Future<TravelMode?> getById(String id) => _repository.getById(id);

  Future<TravelMode?> shouldMoveMediaToTravelFolder(
    int? mediaDateTaken,
    int mediaDateAdded,
  ) async {
    final active = await _repository.watchActive().first;
    if (active != null &&
        active.isMediaInTravelPeriod(mediaDateTaken, mediaDateAdded)) {
      return active;
    }
    return null;
  }

  Future<void> create(TravelMode mode) => _repository.create(mode);

  Future<void> update(TravelMode mode) => _repository.update(mode);

  Future<void> delete(String id) => _repository.delete(id);
}
