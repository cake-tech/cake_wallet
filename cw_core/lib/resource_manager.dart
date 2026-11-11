import "dart:async";

import "package:cw_core/utils/print_verbose.dart";
import "package:meta/meta.dart";

abstract interface class Resource<K extends ResourceKey> {
  K get key;

  Future<void> dispose();
}

abstract class ResourceKey {
  const ResourceKey();

  @mustBeOverridden
  @override
  bool operator ==(Object other);

  @mustBeOverridden
  @override
  int get hashCode;
}

class ResourceInUseException implements Exception {
  ResourceInUseException(this.key);

  final ResourceKey key;

  @override
  String toString() => "$key is in use. Try again in a moment.";
}

class ResourceHold<R> {
  ResourceHold._(this.resource, this._onRelease);

  final R resource;
  Future<void> Function()? _onRelease;

  Future<void> release() async {
    final onRelease = _onRelease;
    _onRelease = null;
    await onRelease?.call();
  }
}

class ResourceManager<K extends ResourceKey, R extends Resource<K>> {
  ResourceManager({required Future<R> Function(K) loader}) : _loader = loader;

  final Future<R> Function(K) _loader;

  final Map<K, _ResourceState<R>> _states = {};

  final Map<K, Future<void>> _locks = {};

  Future<T> runWithResource<T>(K key, Future<T> Function(R) task) async {
    final state = await _get(key);

    try {
      final resource = await state.createFuture;
      return await task(resource);
    } finally {
      _release(key);
    }
  }

  Future<ResourceHold<R>> hold(K key, {Future<R> Function()? load}) async {
    final state = await _get(key, load);

    try {
      return ResourceHold._(await state.createFuture, () async {
        _release(key);
        await _states[key]?.disposeFuture;
      });
    } catch (_) {
      _release(key);
      rethrow;
    }
  }

  // avoid this unless you're 100% sure it's needed, generally used for stuff that will result in the resource not existing later (ex. deleting a wallet)
  Future<T> runExclusive<T>(K key, Future<T> Function() task) async {
    while (_locks[key] != null) {
      await _locks[key];
    }

    final state = _states[key];
    if (state != null && state.refCount > 0) {
      throw ResourceInUseException(key);
    }

    final lock = Completer<void>();
    _locks[key] = lock.future;

    try {
      await state?.disposeFuture;
      return await task();
    } finally {
      _locks.remove(key);
      lock.complete();
    }
  }

  Future<_ResourceState<R>> _get(K key, [Future<R> Function()? load]) async {
    _ResourceState<R>? state = _states[key];

    while (_locks[key] != null || state?.disposeFuture != null) {
      await (_locks[key] ?? state!.disposeFuture);

      state = _states[key];
    }

    if (state == null) {
      state = _ResourceState(load?.call() ?? _loader(key));
      _states[key] = state;
    }

    state.refCount++;
    return state;
  }

  void _release(K key) {
    final state = _states[key];
    if (state == null) {
      return;
    }

    state.refCount--;
    if (state.refCount > 0) {
      // still used
      return;
    }

    state.disposeFuture = state.createFuture
        .then((resource) async {
          try {
            await resource.dispose();
          } catch (e, st) {
            printV("error disposing resource: $e. this should NOT happen!\n$st");
          }
        })
        .catchError((e, _) {})
        .whenComplete(() => _states.remove(key));
  }
}

class _ResourceState<R extends Resource> {
  _ResourceState(this.createFuture) {
    // prevents dart from eating up exceptions thrown by createFuture
    createFuture.ignore();
  }

  // so why is this a future?
  // if a caller requests a resource, it starts loading, that may take time
  // if another caller requests the same resource during that time, manager just awaits this future and gets the same resource
  // this way we avoid loading the same resource twice
  final Future<R> createFuture;

  // if non-null, a dispose was scheduled.
  // if a caller requests a resource with a pending dispose, it waits for the dispose to run then re-inits the resource
  Future<void>? disposeFuture;

  int refCount = 0;
}
