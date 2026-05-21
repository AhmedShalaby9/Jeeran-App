import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/property_repository.dart';
import 'add_property_event.dart';
import 'add_property_state.dart';

class AddPropertyBloc extends Bloc<AddPropertyEvent, AddPropertyState> {
  final PropertyRepository repository;

  AddPropertyBloc({required this.repository}) : super(const AddPropertyInitial()) {
    on<SubmitAddProperty>(_onSubmit);
    on<SubmitUpdateProperty>(_onUpdate);
  }

  Future<void> _onSubmit(
    SubmitAddProperty event,
    Emitter<AddPropertyState> emit,
  ) async {
    final form = event.form;
    final images = form.selectedImages;

    // ── 1. Upload images one by one ───────────────────────────────────────────
    final uploadedUrls = <String>[];
    for (int i = 0; i < images.length; i++) {
      emit(AddPropertyUploading(current: i + 1, total: images.length));
      final result = await repository.uploadImage(images[i].path);
      String? url;
      result.fold((f) => url = null, (u) => url = u);
      if (url == null) {
        emit(AddPropertyFailure('Failed to upload image ${i + 1}. Please try again.'));
        return;
      }
      uploadedUrls.add(url!);
    }

    // ── 1b. Upload video if selected ──────────────────────────────────────────
    if (form.videoFile != null) {
      emit(const AddPropertySubmitting());
      final videoResult = await repository.uploadImage(form.videoFile!.path);
      String? videoUrl;
      videoResult.fold((f) => videoUrl = null, (u) => videoUrl = u);
      if (videoUrl == null) {
        emit(AddPropertyFailure('Failed to upload video. Please try again.'));
        return;
      }
      form.videoUrl = videoUrl;
    }

    // ── 2. Create property ────────────────────────────────────────────────────
    emit(const AddPropertySubmitting());
    final body = form.toBody(uploadedUrls);
    final result = await repository.createProperty(body);
    result.fold(
      (failure) => emit(AddPropertyFailure(_mapFailure(failure))),
      (_) => emit(const AddPropertySuccess()),
    );
  }

  Future<void> _onUpdate(
    SubmitUpdateProperty event,
    Emitter<AddPropertyState> emit,
  ) async {
    final newImages = event.newImages;
    final uploadedUrls = <String>[...event.existingImageUrls];

    // Upload new images
    for (int i = 0; i < newImages.length; i++) {
      emit(AddPropertyUploading(current: i + 1, total: newImages.length));
      final result = await repository.uploadImage(newImages[i].path);
      String? url;
      result.fold((f) => url = null, (u) => url = u);
      if (url == null) {
        emit(AddPropertyFailure('Failed to upload image ${i + 1}. Please try again.'));
        return;
      }
      uploadedUrls.add(url!);
    }

    emit(const AddPropertySubmitting());
    final body = Map<String, dynamic>.from(event.body);
    body['images'] = uploadedUrls;
    final result = await repository.updateProperty(event.propertyId, body);
    result.fold(
      (failure) => emit(AddPropertyFailure(_mapFailure(failure))),
      (_) => emit(const AddPropertySuccess()),
    );
  }

  String _mapFailure(Failure failure) => switch (failure) {
        NetworkFailure _ => 'No internet connection. Please check your network.',
        ServerFailure f => f.message ?? 'Server error. Please try again.',
        _ => 'Something went wrong. Please try again.',
      };
}
