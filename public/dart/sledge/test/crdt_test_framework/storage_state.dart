// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

// ignore_for_file: implementation_imports
import 'package:sledge/src/document/change.dart';
import 'package:sledge/src/uint8list_ops.dart';
import 'package:sledge/src/document/values/key_value.dart';

import 'entry.dart';

/// StorageState is a key-value storage with timestamp per key.
/// It stores timestamps for deleted keys (time of deletion).
/// Used to fake Ledger's KeyValue storage.
class StorageState {
  final Map<Uint8List, Entry> _storage = newUint8ListMap<Entry>();

  /// Applies [change] to storage. Uses [timestamp] as a time of update.
  void applyChange(Change change, int timestamp) {
    for (final entry in change.changedEntries) {
      _storage[entry.key] = new Entry(entry.value, timestamp);
    }
    for (final key in change.deletedKeys) {
      _storage[key] = new Entry.deleted(timestamp);
    }
    // TODO: check that changedEntries and deletedKeys do not intersect.
  }

  /// Updates state of this with respect to [other]. Returns change done to this.
  Change updateWith(StorageState other) {
    final changedEntries = <KeyValue>[];
    final deletedKeys = <Uint8List>[];

    for (final entry in other._storage.entries) {
      // Check which storage has the most recent value for the entry's key.
      if (!_storage.containsKey(entry.key) ||
          _storage[entry.key].timestamp < entry.value.timestamp) {
        // Use other's value for this key.
        if (other._storage[entry.key].isDeleted) {
          // To handle deleted on [other] keys following strategy is used:
          //  If [key] was never presented on [this] - do nothing.
          //  In the other case copy the deletion entry from [other] to [this].
          if (_storage.containsKey(entry.key) &&
              !_storage[entry.key].isDeleted) {
            // [key] should be added to [deletedKeys] only if is currently
            // presented in [this].
            deletedKeys.add(entry.key);
          }
          if (_storage.containsKey(entry.key)) {
            _storage[entry.key] = entry.value;
          }
        } else {
          changedEntries.add(new KeyValue(entry.key, entry.value.value));
          _storage[entry.key] = other._storage[entry.key];
        }
      }
    }
    return new Change(changedEntries, deletedKeys);
  }
}
