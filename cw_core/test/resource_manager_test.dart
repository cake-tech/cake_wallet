import "dart:async";
import "dart:math";

import "package:cw_core/resource_manager.dart";
import "package:flutter_test/flutter_test.dart";

/// How a load should fail, if at all.
enum _LoadFailure {
  /// the loader throws before it ever returns a future
  synchronous,

  /// the loader returns a future that is *already* completed with an error
  immediateFuture,

  /// the loader is an `async` function that throws before its first `await`
  asyncBeforeAwait,

  /// the loader returns a future that fails a microtask later, i.e. an `async`
  /// function that throws after it has already suspended once
  microtask,
}

class _Key extends ResourceKey {
  _Key(this.id);

  final String id;

  @override
  bool operator ==(Object other) => other is _Key && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => "_Key($id)";
}

/// A key that does not implement `==`/`hashCode`, i.e. it only ever equals
/// itself. [ResourceKey] mandates value equality, so this only compiles by
/// deliberately suppressing that mandate — which is the point of the test
/// below: the warning is the only thing standing between you and silently
/// loading one resource per key instance.
// ignore: missing_override_of_must_be_overridden
class _IdentityKey extends ResourceKey {
  _IdentityKey(this.id);

  final String id;

  @override
  String toString() => "_IdentityKey($id)";
}

/// The bare minimum resource, for the contract tests.
class _PlainRes implements Resource<_IdentityKey> {
  _PlainRes(this.key);

  @override
  final _IdentityKey key;

  @override
  Future<void> dispose() async {}
}

/// A resource whose teardown runs arbitrary caller code.
class _ReentrantRes extends _PlainRes {
  _ReentrantRes(super.key, this._onDispose);

  final Future<void> Function() _onDispose;

  @override
  Future<void> dispose() => _onDispose();
}

class _Res implements Resource<_Key> {
  _Res(this.key, this.serial, this._harness, {this.disposeGate, this.disposeDelay});

  @override
  final _Key key;

  final int serial;
  final _Harness _harness;

  /// if set, `dispose` will not finish until the test completes this
  final Completer<void>? disposeGate;

  final Duration? disposeDelay;

  /// thrown at the very end of `dispose`
  Error? disposeError;

  bool disposed = false;
  int disposeCalls = 0;
  int useCount = 0;

  /// every task calls this, so that touching a closed resource is loud
  void use() {
    if (disposed) {
      _harness.useAfterDispose.add(toString());
      throw StateError("used after dispose: $this");
    }
    useCount++;
  }

  @override
  Future<void> dispose() async {
    disposeCalls++;

    final gate = disposeGate;
    if (gate != null) {
      await gate.future;
    }
    final delay = disposeDelay;
    if (delay != null) {
      await Future<void>.delayed(delay);
    }

    disposed = true;
    _harness.noteDisposed(this);

    final error = disposeError;
    if (error != null) {
      throw error;
    }
  }

  @override
  String toString() => "_Res(${key.id}#$serial)";
}

class _Harness {
  _Harness({this.gateLoads = false, this.gateDisposes = false, this.rng}) {
    manager = ResourceManager<_Key, _Res>(loader: _load);
  }

  /// loads hang until the test calls [completeLoad] / [failLoad]
  final bool gateLoads;

  /// disposes hang until the test completes `_Res.disposeGate`
  final bool gateDisposes;

  /// when set, loads and disposes take a random sub-millisecond amount of time
  final Random? rng;

  late final ResourceManager<_Key, _Res> manager;

  final List<_Key> loadedKeys = [];
  final List<_Res> created = [];
  final Map<_Key, Completer<_Res>> pendingLoads = {};
  final List<String> useAfterDispose = [];

  final Map<String, int> _live = {};
  final Map<String, int> maxLive = {};

  _LoadFailure? _nextFailure;
  Error _nextFailureError = StateError("load failed");

  int get loadCount => loadedKeys.length;

  void failNextLoad(_LoadFailure how, [Error? error]) {
    _nextFailure = how;
    if (error != null) {
      _nextFailureError = error;
    }
  }

  Future<_Res> _load(_Key key) {
    loadedKeys.add(key);

    final failure = _nextFailure;
    if (failure != null) {
      _nextFailure = null;
      final error = _nextFailureError;
      switch (failure) {
        case _LoadFailure.synchronous:
          throw error;
        case _LoadFailure.immediateFuture:
          return Future<_Res>.error(error);
        case _LoadFailure.asyncBeforeAwait:
          return _throwingLoad(error);
        case _LoadFailure.microtask:
          return Future<_Res>.microtask(() => throw error);
      }
    }

    if (gateLoads) {
      final completer = Completer<_Res>();
      pendingLoads[key] = completer;
      return completer.future;
    }

    final delay = _randomDelay();
    if (delay != null) {
      return Future<_Res>.delayed(delay, () => _create(key));
    }
    return Future<_Res>.microtask(() => _create(key));
  }

  Future<_Res> _throwingLoad(Error error) async => throw error;

  Duration? _randomDelay() {
    final random = rng;
    if (random == null) {
      return null;
    }
    return Duration(microseconds: random.nextInt(1500));
  }

  _Res _create(_Key key) {
    final res = _Res(
      key,
      created.length,
      this,
      disposeGate: gateDisposes ? Completer<void>() : null,
      disposeDelay: _randomDelay(),
    );
    created.add(res);

    final live = (_live[key.id] ?? 0) + 1;
    _live[key.id] = live;
    maxLive[key.id] = max(live, maxLive[key.id] ?? 0);

    return res;
  }

  void noteDisposed(_Res res) => _live[res.key.id] = (_live[res.key.id] ?? 0) - 1;

  int get liveCount => _live.values.fold(0, (a, b) => a + b);

  void completeLoad(_Key key) {
    final completer = pendingLoads.remove(key);
    if (completer == null) {
      throw StateError("no pending load for $key");
    }
    completer.complete(_create(key));
  }

  void failLoad(_Key key, Object error) {
    final completer = pendingLoads.remove(key);
    if (completer == null) {
      throw StateError("no pending load for $key");
    }
    completer.completeError(error);
  }

  /// Every resource this harness handed out is closed, exactly once.
  void expectFullyDrained() {
    expect(useAfterDispose, isEmpty, reason: "a task touched a closed resource");
    expect(liveCount, 0, reason: "resources still open: $_live");
    for (final res in created) {
      expect(res.disposed, isTrue, reason: "$res was never closed");
      expect(res.disposeCalls, 1, reason: "$res was closed ${res.disposeCalls} times");
    }
  }
}

/// Lets every pending microtask *and* zero-duration timer run.
Future<void> pump([int turns = 8]) async {
  for (var i = 0; i < turns; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  group("sharing", () {
    test("parallel callers share one load and one instance", () async {
      final h = _Harness(gateLoads: true);
      final seen = <_Res>[];

      final calls = List<Future<int>>.generate(
        5,
        (i) => h.manager.runWithResource(_Key("a"), (r) async {
          seen.add(r);
          r.use();
          return i;
        }),
      );
      await pump();

      expect(h.loadCount, 1, reason: "five callers, one load");

      h.completeLoad(_Key("a"));
      expect(await Future.wait(calls), [0, 1, 2, 3, 4]);

      expect(seen, hasLength(5));
      expect(seen.every((r) => identical(r, h.created.single)), isTrue);

      await pump();
      h.expectFullyDrained();
    });

    test("a caller arriving mid-load joins that load", () async {
      final h = _Harness(gateLoads: true);
      _Res? first;
      _Res? second;

      final a = h.manager.runWithResource(_Key("a"), (r) async {
        first = r;
        r.use();
      });
      await pump();
      expect(h.loadCount, 1);

      final b = h.manager.runWithResource(_Key("a"), (r) async {
        second = r;
        r.use();
      });
      await pump();
      expect(h.loadCount, 1, reason: "the in-flight load must be reused, not restarted");

      h.completeLoad(_Key("a"));
      await Future.wait([a, b]);

      expect(first, isNotNull);
      expect(second, same(first));

      await pump();
      h.expectFullyDrained();
    });

    test("overlapping callers keep the resource alive until the last one leaves", () async {
      final h = _Harness();
      final gateA = Completer<void>();
      final gateB = Completer<void>();
      _Res? first;
      _Res? second;

      final a = h.manager.runWithResource(_Key("a"), (r) async {
        first = r;
        r.use();
        await gateA.future;
        r.use();
      });
      await pump();

      // b joins after the load already finished
      final b = h.manager.runWithResource(_Key("a"), (r) async {
        second = r;
        r.use();
        await gateB.future;
        r.use();
      });
      await pump();

      expect(h.loadCount, 1);
      expect(second, same(first));

      gateA.complete();
      await a;
      await pump();
      expect(first!.disposeCalls, 0, reason: "b is still inside its task");

      gateB.complete();
      await b;
      await pump();
      expect(first!.disposeCalls, 1);
      h.expectFullyDrained();
    });

    test("distinct keys get distinct resources", () async {
      final h = _Harness(gateLoads: true);
      _Res? fromA;
      _Res? fromB;

      final a = h.manager.runWithResource(_Key("a"), (r) async {
        fromA = r;
        r.use();
      });
      final b = h.manager.runWithResource(_Key("b"), (r) async {
        fromB = r;
        r.use();
      });
      await pump();

      expect(h.loadCount, 2);
      expect(h.loadedKeys.map((k) => k.id), ["a", "b"]);

      h.completeLoad(_Key("a"));
      h.completeLoad(_Key("b"));
      await Future.wait([a, b]);

      expect(fromA, isNotNull);
      expect(fromB, isNotNull);
      expect(fromA, isNot(same(fromB)));
      expect(fromA!.key.id, "a");
      expect(fromB!.key.id, "b");

      await pump();
      h.expectFullyDrained();
    });

    test("equal but not identical keys share a resource", () async {
      final h = _Harness(gateLoads: true);
      _Res? first;
      _Res? second;

      final a = h.manager.runWithResource(_Key("a"), (r) async => first = r);
      final b = h.manager.runWithResource(_Key("a"), (r) async => second = r);
      await pump();

      expect(h.loadCount, 1);

      h.completeLoad(_Key("a"));
      await Future.wait([a, b]);

      expect(second, same(first));
      await pump();
      h.expectFullyDrained();
    });

    test("a task may re-enter the manager for the same key", () async {
      final h = _Harness();

      final result = await h.manager.runWithResource(_Key("a"), (outer) async {
        outer.use();

        final inner = await h.manager.runWithResource(_Key("a"), (r) async {
          r.use();
          return r;
        });
        expect(inner, same(outer), reason: "nesting must not load a second copy");

        // the inner call released its reference; the outer one still holds it
        outer.use();
        return 7;
      });

      expect(result, 7);
      expect(h.loadCount, 1);

      await pump();
      h.expectFullyDrained();
    });
  });

  group("results and failures", () {
    test("the task's value is returned", () async {
      final h = _Harness();
      expect(
        await h.manager.runWithResource(_Key("a"), (r) async {
          r.use();
          return "value";
        }),
        "value",
      );
      await pump();
      h.expectFullyDrained();
    });

    test("a task error propagates and the resource is still closed", () async {
      final h = _Harness();

      await expectLater(
        h.manager.runWithResource<void>(_Key("a"), (r) {
          r.use();
          throw StateError("boom");
        }),
        throwsA(isA<StateError>()),
      );

      await pump();
      expect(h.created, hasLength(1));
      h.expectFullyDrained();
    });

    test("a load failure reaches every waiting caller", () async {
      final h = _Harness(gateLoads: true);

      final a = h.manager.runWithResource<void>(_Key("a"), (r) async => r.use());
      final b = h.manager.runWithResource<void>(_Key("a"), (r) async => r.use());
      await pump();

      h.failLoad(_Key("a"), StateError("nope"));

      await expectLater(a, throwsA(isA<StateError>()));
      await expectLater(b, throwsA(isA<StateError>()));

      expect(h.created, isEmpty, reason: "nothing was ever constructed, so nothing to close");
      await pump();
      h.expectFullyDrained();
    });

    test("a failed load is not cached: the next call retries", () async {
      final h = _Harness();
      h.failNextLoad(_LoadFailure.microtask);

      await expectLater(
        h.manager.runWithResource<void>(_Key("a"), (r) async => r.use()),
        throwsA(isA<StateError>()),
      );
      await pump();

      expect(
        await h.manager.runWithResource(_Key("a"), (r) async {
          r.use();
          return "ok";
        }),
        "ok",
      );
      expect(h.loadCount, 2);

      await pump();
      h.expectFullyDrained();
    });

    test("a loader that throws synchronously does not wedge the key", () async {
      final h = _Harness();
      h.failNextLoad(_LoadFailure.synchronous);

      await expectLater(
        h.manager.runWithResource<void>(_Key("a"), (r) async => r.use()),
        throwsA(isA<StateError>()),
      );
      await pump();

      expect(
        await h.manager.runWithResource(_Key("a"), (r) async {
          r.use();
          return "ok";
        }),
        "ok",
      );

      await pump();
      h.expectFullyDrained();
    });

    test("a loader returning an already-failed future does not wedge the key", () async {
      final h = _Harness();
      h.failNextLoad(_LoadFailure.immediateFuture);

      await expectLater(
        h.manager.runWithResource<void>(_Key("a"), (r) async => r.use()),
        throwsA(isA<StateError>()),
      );
      await pump();

      expect(
        await h.manager.runWithResource(_Key("a"), (r) async {
          r.use();
          return "ok";
        }),
        "ok",
      );

      await pump();
      h.expectFullyDrained();
    });

    test("an async loader that throws before its first await reports once", () async {
      final h = _Harness();
      h.failNextLoad(_LoadFailure.asyncBeforeAwait);

      // Regression guard: the failure must reach the caller and *only* the
      // caller. Nothing listens to `createFuture` until runWithResource awaits
      // it, so without _ResourceState arming it the same failure also escapes
      // as an unhandled async error, which fails this test.
      await expectLater(
        h.manager.runWithResource<void>(_Key("a"), (r) async => r.use()),
        throwsA(isA<StateError>()),
      );
      await pump();

      expect(
        await h.manager.runWithResource(_Key("a"), (r) async {
          r.use();
          return "ok";
        }),
        "ok",
      );

      await pump();
      h.expectFullyDrained();
    });

    test("a dispose error is swallowed and the key still recovers", () async {
      final h = _Harness();

      await h.manager.runWithResource<void>(_Key("a"), (r) async {
        r.use();
        r.disposeError = StateError("close failed");
      });
      await pump();

      final first = h.created.single;
      expect(first.disposeCalls, 1);

      expect(
        await h.manager.runWithResource(_Key("a"), (r) async {
          r.use();
          return "ok";
        }),
        "ok",
      );
      expect(h.loadCount, 2);
      expect(h.created[1], isNot(same(first)));

      await pump();
      expect(h.useAfterDispose, isEmpty);
    });
  });

  group("close lifecycle", () {
    test("the resource is closed exactly once, after the last caller", () async {
      final h = _Harness();

      await Future.wait([
        h.manager.runWithResource<void>(_Key("a"), (r) async => r.use()),
        h.manager.runWithResource<void>(_Key("a"), (r) async => r.use()),
        h.manager.runWithResource<void>(_Key("a"), (r) async => r.use()),
      ]);
      await pump();

      expect(h.created, hasLength(1));
      expect(h.created.single.disposeCalls, 1);
      h.expectFullyDrained();
    });

    test("runWithResource returns before the close has finished", () async {
      final h = _Harness(gateDisposes: true);

      await h.manager.runWithResource<void>(_Key("a"), (r) async => r.use());

      final first = h.created.single;
      expect(
        first.disposed,
        isFalse,
        reason: "the caller's future completes without waiting for teardown",
      );

      await pump();
      expect(first.disposeCalls, 1, reason: "closing was started, just not awaited");
      expect(first.disposed, isFalse, reason: "still gated");

      first.disposeGate!.complete();
      await pump();
      h.expectFullyDrained();
    });

    test("a caller arriving during a close waits for it, then loads a fresh resource", () async {
      final h = _Harness(gateDisposes: true);

      await h.manager.runWithResource<void>(_Key("a"), (r) async => r.use());
      await pump();

      final first = h.created.single;
      expect(first.disposeCalls, 1, reason: "closing is in flight");
      expect(first.disposed, isFalse, reason: "gated, so it cannot finish yet");

      _Res? second;
      final pending = h.manager.runWithResource<void>(_Key("a"), (r) async {
        second = r;
        r.use();
      });
      await pump();

      expect(h.loadCount, 1, reason: "must not reload while the old resource is still closing");
      expect(second, isNull);

      first.disposeGate!.complete();
      await pending;

      expect(h.loadCount, 2);
      expect(second, isNotNull);
      expect(second, isNot(same(first)));
      expect(h.maxLive["a"], 1, reason: "the two generations must never overlap");

      h.created[1].disposeGate!.complete();
      await pump();
      h.expectFullyDrained();
    });

    test("several callers arriving during a close share a single reload", () async {
      final h = _Harness(gateDisposes: true);

      await h.manager.runWithResource<void>(_Key("a"), (r) async => r.use());
      await pump();

      final first = h.created.single;
      final seen = <_Res>[];
      final calls = List<Future<void>>.generate(
        3,
        (_) => h.manager.runWithResource<void>(_Key("a"), (r) async {
          seen.add(r);
          r.use();
        }),
      );
      await pump();
      expect(h.loadCount, 1);

      first.disposeGate!.complete();
      await pump();
      expect(h.loadCount, 2, reason: "all three waiters must share one reload");

      h.created[1].disposeGate!.complete();
      await Future.wait(calls);
      await pump();

      expect(seen, hasLength(3));
      expect(seen.every((r) => identical(r, h.created[1])), isTrue);
      expect(h.maxLive["a"], 1);
      h.expectFullyDrained();
    });

    test("sequential calls reload the resource every single time", () async {
      final h = _Harness();

      await h.manager.runWithResource<void>(_Key("a"), (r) async => r.use());
      await h.manager.runWithResource<void>(_Key("a"), (r) async => r.use());
      await h.manager.runWithResource<void>(_Key("a"), (r) async => r.use());
      await pump();

      // Nothing is kept warm: only *overlapping* callers ever share an instance.
      expect(h.loadCount, 3);
      expect(h.created, hasLength(3));
      h.expectFullyDrained();
    });
  });

  group("contract gaps", () {
    test("a key that ignores the equality mandate silently defeats sharing", () async {
      final loads = <_IdentityKey>[];
      final manager = ResourceManager<_IdentityKey, _PlainRes>(
        loader: (key) async {
          loads.add(key);
          return _PlainRes(key);
        },
      );

      // The same wallet, addressed by two equal-looking keys.
      await Future.wait([
        manager.runWithResource<void>(_IdentityKey("a"), (r) async {}),
        manager.runWithResource<void>(_IdentityKey("a"), (r) async {}),
      ]);

      // Identity equality means two keys, so two resources: exactly what the
      // @mustBeOverridden on ResourceKey.== exists to prevent.
      expect(loads, hasLength(2));
    });

    test("dispose() re-entering the manager for its own key deadlocks forever", () async {
      late ResourceManager<_IdentityKey, _PlainRes> manager;
      final key = _IdentityKey("a");
      var reentryFinished = false;

      manager = ResourceManager<_IdentityKey, _PlainRes>(
        loader: (k) async => _ReentrantRes(k, () async {
          // anything in close() that routes back through the manager for the
          // same key waits on the dispose that is calling it
          await manager.runWithResource<void>(k, (r) async {});
          reentryFinished = true;
        }),
      );

      await manager.runWithResource<void>(key, (r) async {});

      // and the key stays wedged: later callers wait on a dispose that can
      // never finish, with no timeout to break them out
      var laterCallerFinished = false;
      unawaited(
        manager.runWithResource<void>(key, (r) async {}).then((_) => laterCallerFinished = true),
      );

      await Future<void>.delayed(const Duration(milliseconds: 150));
      await pump(20);

      expect(reentryFinished, isFalse);
      expect(laterCallerFinished, isFalse);
    });

    test("the resource's own key is never checked against the requested one", () async {
      final manager = ResourceManager<_IdentityKey, _PlainRes>(
        loader: (key) async => _PlainRes(_IdentityKey("something-else")),
      );

      final key = await manager.runWithResource(_IdentityKey("a"), (r) async => r.key.id);

      // A loader handing back a mismatched resource goes unnoticed.
      expect(key, "something-else");
    });
  });

  group("invariants under churn", () {
    for (final seed in [1, 7, 42, 1337, 20260902]) {
      test("randomised interleavings (seed $seed) never double-load or reuse a closed resource",
          () async {
        final rng = Random(seed);
        final h = _Harness(rng: rng);
        final keys = [_Key("a"), _Key("b"), _Key("c")];

        final calls = <Future<void>>[];
        for (var i = 0; i < 120; i++) {
          final key = keys[rng.nextInt(keys.length)];
          final taskDelay = Duration(microseconds: rng.nextInt(1500));

          calls.add(
            Future<void>.delayed(
              Duration(microseconds: rng.nextInt(4000)),
              () => h.manager.runWithResource<void>(key, (r) async {
                expect(r.key, key);
                r.use();
                await Future<void>.delayed(taskDelay);
                r.use();
              }),
            ),
          );
        }

        await Future.wait(calls);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await pump(20);

        for (final key in keys) {
          expect(
            h.maxLive[key.id],
            1,
            reason: "two resources for ${key.id} were open at the same time",
          );
        }
        expect(h.created, isNotEmpty);
        h.expectFullyDrained();
      });
    }
  });
}
