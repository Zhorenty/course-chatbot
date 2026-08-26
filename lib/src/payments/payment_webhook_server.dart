import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:course_chatbot/src/application/checkout_service.dart';
import 'package:course_chatbot/src/data/course_repository.dart';
import 'package:course_chatbot/src/jobs/job_scheduler.dart';
import 'package:course_chatbot/src/payments/payment_gateway.dart';
import 'package:l/l.dart';

/// HTTPS callbacks from the kassa. Does not replace Telegram long polling.
final class PaymentWebhookServer {
  PaymentWebhookServer({
    required String bind,
    required PaymentGateway gateway,
    required CheckoutService checkout,
    required CourseRepository course,
    required PaymentResultNotifier notifier,
    String? secret,
    String callbackPath = '/payments/callback',
    JobScheduler? scheduler,
  })  : _bind = bind,
        _gateway = gateway,
        _checkout = checkout,
        _course = course,
        _notifier = notifier,
        _secret = secret?.trim(),
        _callbackPath = _normalizePath(callbackPath),
        _scheduler = scheduler;

  static const int maxBodyBytes = 256 * 1024;

  final String _bind;
  final PaymentGateway _gateway;
  final CheckoutService _checkout;
  final CourseRepository _course;
  final PaymentResultNotifier _notifier;
  final String? _secret;
  final String _callbackPath;
  final JobScheduler? _scheduler;
  HttpServer? _server;

  Future<void> start() async {
    final colon = _bind.lastIndexOf(':');
    final host = colon <= 0 ? '127.0.0.1' : _bind.substring(0, colon);
    final port = int.tryParse(colon == -1 ? _bind : _bind.substring(colon + 1)) ?? 8080;
    _server = await HttpServer.bind(host, port);
    l.i('Payment webhook listening on $host:$port$_callbackPath');
    _server!.listen(_dispatch, onError: (Object error, StackTrace stackTrace) {
      l.w('Payment webhook listener error: $error', stackTrace);
    });
  }

  Future<void> stop() async {
    await _server?.close(force: false);
    _server = null;
  }

  Future<void> _dispatch(HttpRequest request) async {
    final scheduler = _scheduler;
    if (scheduler == null) {
      await _handle(request);
      return;
    }
    await scheduler.runTracked(() => _handle(request));
  }

  Future<void> _handle(HttpRequest request) async {
    try {
      if (request.method == 'GET' && request.uri.path == '/health') {
        request.response.statusCode = HttpStatus.ok;
        request.response.write('ok');
        await request.response.close();
        return;
      }
      if (request.method != 'POST' || !_isCallbackPath(request.uri.path)) {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }
      if (!_secretMatches(request)) {
        request.response.statusCode = HttpStatus.unauthorized;
        await request.response.close();
        return;
      }
      final contentLength = request.contentLength;
      if (contentLength > maxBodyBytes) {
        request.response.statusCode = HttpStatus.requestEntityTooLarge;
        await request.response.close();
        return;
      }
      final body = await _readBody(request);
      if (body == null) {
        request.response.statusCode = HttpStatus.requestEntityTooLarge;
        await request.response.close();
        return;
      }
      Object? decoded;
      try {
        decoded = jsonDecode(body);
      } on Object {
        request.response.statusCode = HttpStatus.badRequest;
        await request.response.close();
        return;
      }
      final parsed = decoded == null ? null : _gateway.parseCallback(decoded);
      if (parsed == null) {
        request.response.statusCode = HttpStatus.ok;
        await request.response.close();
        return;
      }
      final callback = await _gateway.verifyCallback(parsed);
      if (callback == null) {
        request.response.statusCode = HttpStatus.unauthorized;
        await request.response.close();
        return;
      }
      final launch = _course.activeLaunch();
      if (launch == null) {
        request.response.statusCode = HttpStatus.serviceUnavailable;
        await request.response.close();
        return;
      }
      final result = await _checkout.applyCallback(callback, launch: launch);
      await _notifier.notifyPaymentResult(result);
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
    } on Object catch (error, stackTrace) {
      l.w('Payment webhook failed: $error', stackTrace);
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
      } on Object {
        // ignore
      }
    }
  }

  bool _isCallbackPath(String path) {
    final normalized = _normalizePath(path);
    if (normalized == _callbackPath) {
      return true;
    }
    final secret = _secret;
    if (secret == null || secret.isEmpty) {
      return false;
    }
    return normalized == '$_callbackPath/${Uri.encodeComponent(secret)}';
  }

  bool _secretMatches(HttpRequest request) {
    final expected = _secret;
    if (expected == null || expected.isEmpty) {
      return true;
    }
    final header = request.headers.value('x-webhook-secret');
    if (header != null && header == expected) {
      return true;
    }
    final query = request.uri.queryParameters['secret'];
    if (query != null && query == expected) {
      return true;
    }
    final path = _normalizePath(request.uri.path);
    return path == '$_callbackPath/${Uri.encodeComponent(expected)}';
  }

  Future<String?> _readBody(HttpRequest request) async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in request) {
      if (builder.length + chunk.length > maxBodyBytes) {
        return null;
      }
      builder.add(chunk);
    }
    return utf8.decode(builder.takeBytes());
  }

  static String _normalizePath(String path) {
    if (path.isEmpty) {
      return '/';
    }
    final withoutSlash =
        path.endsWith('/') && path.length > 1 ? path.substring(0, path.length - 1) : path;
    return withoutSlash.startsWith('/') ? withoutSlash : '/$withoutSlash';
  }
}
