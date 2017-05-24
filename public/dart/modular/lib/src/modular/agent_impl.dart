// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:application.lib.app.dart/app.dart';
import 'package:application.services/service_provider.fidl.dart';
import 'package:apps.modular.services.agent/agent.fidl.dart';
import 'package:apps.modular.services.agent/agent_context.fidl.dart';
import 'package:apps.modular.services.auth/token_provider.fidl.dart';
import 'package:apps.modular.services.component/component_context.fidl.dart';
import 'package:lib.fidl.dart/bindings.dart';
import 'package:meta/meta.dart';

export 'package:application.lib.app.dart/app.dart';
export 'package:apps.modular.services.agent/agent.fidl.dart';
export 'package:apps.modular.services.agent/agent_context.fidl.dart';
export 'package:apps.modular.services.auth/token_provider.fidl.dart';
export 'package:apps.modular.services.component/component_context.fidl.dart';

/// A base class for implementing an [Agent] which receives common services and
/// also helps exposing services through an outgoing [ServiceProvider].
abstract class AgentImpl extends Agent {
  final AgentBinding _binding = new AgentBinding();
  final ApplicationContext _applicationContext;

  AgentContextProxy _agentContext;
  ComponentContextProxy _componentContext;
  TokenProviderProxy _tokenProvider;

  final ServiceProviderImpl _outgoingServicesImpl = new ServiceProviderImpl();
  final List<ServiceProviderBinding> _outgoingServicesBindings =
      <ServiceProviderBinding>[];

  /// Creates a new instance of [AgentImpl].
  AgentImpl({
    @required ApplicationContext applicationContext,
  })
      : _applicationContext = applicationContext {
    assert(applicationContext != null);
  }

  @override
  void connect(
    String requestorUrl,
    InterfaceRequest<ServiceProvider> services,
  ) {
    _outgoingServicesBindings.add(
      new ServiceProviderBinding()..bind(_outgoingServicesImpl, services),
    );
  }

  @override
  Future<Null> initialize(
    InterfaceHandle<AgentContext> agentContext,
    void callback(),
  ) async {
    // Bind the AgentContext handle
    _agentContext = new AgentContextProxy();
    _agentContext.ctrl.bind(agentContext);

    // Get the ComponentContext
    _componentContext = new ComponentContextProxy();
    _agentContext.getComponentContext(_componentContext.ctrl.request());

    // Get the TokenProvider
    _tokenProvider = new TokenProviderProxy();
    _agentContext.getTokenProvider(_tokenProvider.ctrl.request());

    await onReady(
      _applicationContext,
      _agentContext,
      _componentContext,
      _tokenProvider,
      _outgoingServicesImpl,
    );

    callback();
  }

  @override
  Future<Null> runTask(
    String taskId,
    void callback(),
  ) async {
    await onRunTask(taskId);

    callback();
  }

  @override
  Future<Null> stop(void callback()) async {
    await onStop();

    _tokenProvider?.ctrl?.close();
    _tokenProvider = null;
    _componentContext?.ctrl?.close();
    _componentContext = null;
    _agentContext?.ctrl?.close();
    _agentContext = null;

    _outgoingServicesBindings
        .forEach((ServiceProviderBinding binding) => binding.close());

    callback();
  }

  /// Advertises this [AgentImpl] as an [Agent] to the rest of the system via
  /// the [_applicationContext].
  void advertise() {
    _applicationContext.outgoingServices.addServiceForName(
      (InterfaceRequest<Agent> request) {
        if (_binding.isBound) {
          // Can only connect to this interface once.
          request.close();
        } else {
          _binding.bind(this, request);
        }
      },
      Agent.serviceName,
    );
  }

  /// Performs additional initialization after [Agent.initialize] is called.
  /// Subclasses must override this if additional work should be done at the
  /// initialization phase.
  Future<Null> onReady(
    ApplicationContext applicationContext,
    AgentContext agentContext,
    ComponentContext componentContext,
    TokenProvider tokenProvider,
    ServiceProviderImpl outgoingServices,
  ) async =>
      null;

  /// Performs additional cleanup work when [Agent.stop] is called.
  /// Subclasses must override this if there are additional resources to be
  /// cleaned up that are obtained from the [onReady] method.
  Future<Null> onStop() async => null;

  /// Runs the task for the given [taskId]. Subclasses must override this
  /// instead of overriding the [runTask] method directly.
  Future<Null> onRunTask(String taskId) async => null;
}
