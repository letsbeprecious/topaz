// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:lib.agent.fidl.agent_controller/agent_controller.fidl.dart';
import 'package:lib.app.fidl/service_provider.fidl.dart';
import 'package:lib.logging/logging.dart';
import 'package:lib.module.fidl/module_context.fidl.dart';
import 'package:lib.story.fidl/link.fidl.dart';
import 'package:lib.widgets/modular.dart';
import 'package:topaz.app.documents.services/document.fidl.dart' as doc_fidl;

/// The ModuleModel for the document browser
class BrowserModuleModel extends ModuleModel {
  // Interface Proxy. This is how we talk to the Doc FIDL
  final doc_fidl.DocumentInterfaceProxy _docsInterfaceProxy =
      new doc_fidl.DocumentInterfaceProxy();

  final AgentControllerProxy _agentControllerProxy = new AgentControllerProxy();

  /// List of all documents for this Document Provider
  List<doc_fidl.Document> documents = <doc_fidl.Document>[];

  /// Currently selected Document
  doc_fidl.Document _currentDoc;

  /// Constructor
  BrowserModuleModel();

  /// Implements the Document interface to List documents
  /// Saves the updated list of documents to the model
  // TODO(maryxia) SO-913 add error modes to doc_fidl
  void list() {
    _docsInterfaceProxy.list((List<doc_fidl.Document> docs) {
      documents = docs;
      notifyListeners();
      log.fine('Retrieved list of documents for BrowserModuleModel');
    });
  }

  /// Updates the currently-selected doc
  void updateCurrentDoc(doc_fidl.Document doc) {
    _currentDoc = doc;
    notifyListeners();
  }

  /// Gets the currently-selected doc
  doc_fidl.Document get currentDoc => _currentDoc;

  @override
  Future<Null> onReady(
    ModuleContext moduleContext,
    Link link,
  ) async {
    super.onReady(moduleContext, link);

    // The below is used to connect to the DocumentProvider service
    ComponentContextProxy componentContext = new ComponentContextProxy();
    moduleContext.getComponentContext(componentContext.ctrl.request());
    ServiceProviderProxy serviceProviderProxy = new ServiceProviderProxy();

    // The incomingServices here are the ones sent from outgoingServices in the
    // DocumentsAgent
    componentContext.connectToAgent(
      // TODO(maryxia) SO-880 get this from file manifest and add a check for
      // whether it can be found in the system
      // launches the application at this location, as if it were an agent
      'file:///system/apps/documents/content_provider',
      serviceProviderProxy.ctrl.request(),
      _agentControllerProxy.ctrl.request(),
    );
    // Connect the DocumentsInterfaceProxy to a service that the agent manages.
    // Otherwise, you've only connected to the Agent, and can't perform actions.
    connectToService(serviceProviderProxy, _docsInterfaceProxy.ctrl);
    serviceProviderProxy.ctrl.close();
    componentContext.ctrl.close();
    notifyListeners();
    log.fine('BrowserModuleModel onReady complete');
  }

  @override
  void onStop() {
    _docsInterfaceProxy.ctrl.close();
    _agentControllerProxy.ctrl.close();
  }
}
