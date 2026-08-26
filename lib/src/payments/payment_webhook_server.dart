import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:course_chatbot/src/application/checkout_service.dart';
import 'package:course_chatbot/src/data/course_repository.dart';
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
  })  : _bind = bind,
        _gateway = gateway,
        _checkout = checkout,
        _course = course,
        _notifier = notifier;

  final String _bind;
  final PaymentGateway _gateway;
  final CheckoutService _checkout;
  final CourseRepository _course;
  final PaymentResultNotifier _notifier;
  HttpServer? _server;

  Future<void> start() async {
    final colon = _bind.lastIndexOf(':');
    final host = colon <= 0 ? '127.0.0.1' : _bind.substring(0, colon);
    final port = int.tryParse(colon == -1 ? _bind : _bind.substring(colon + 1)) ?? 8080;
    _server = await HttpServer.bind(host, port);
    l.i('Payment webhook listening on $host:$port');
    _server!.listen(_handle, onError: (Object error, StackTrace stackTrace) {
      l.w('Payment webhook listener error: $error', stackTrace);
    });
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  Future<void> _handle(HttpRequest request) async {
    try {
      if (request.method != 'POST') {
        request.response.statusCode = HttpStatus.methodNotAllowed;
        await request.response.close();
        return;
      }
      final body = await utf8.decoder.bind(request).join();
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
        request.response.statusCode = HttpStatus.ok;
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
}
