import 'dart:typed_data';

import '../../domain/repositories/local_file_repository.dart';
import '../datasources/local_file_data_source.dart';

class LocalFileRepositoryImpl implements LocalFileRepository {
  const LocalFileRepositoryImpl(this._dataSource);
  final LocalFileDataSource _dataSource;

  @override
  Future<bool> exists(String path) => _dataSource.exists(path);

  @override
  Future<Uint8List?> readBytes(String path) => _dataSource.readBytes(path);
}
