import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

// IDs de view factory já registradas — evita registro duplicado.
final _registeredGifIds = <String>{};

/// GIF animado com fundo branco. Usado na tela de "Ver execução".
Widget buildGifHtmlView(String url, double height) {
  final id = 'gif_anim_${url.hashCode}';

  if (!_registeredGifIds.contains(id)) {
    _registeredGifIds.add(id);
    ui_web.platformViewRegistry.registerViewFactory(id, (_) {
      final div = web.document.createElement('div') as web.HTMLDivElement
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.display = 'flex'
        ..style.alignItems = 'center'
        ..style.justifyContent = 'center'
        ..style.backgroundColor = 'white';

      final img = web.document.createElement('img') as web.HTMLImageElement
        ..src = url
        ..style.maxWidth = '100%'
        ..style.maxHeight = '100%'
        ..style.objectFit = 'contain';

      div.append(img);
      return div;
    });
  }

  return SizedBox(
    height: height,
    width: double.infinity,
    child: HtmlElementView(viewType: id),
  );
}

/// GIF estático (1° frame) via canvas. Usado na tela de execução do treino.
/// Não requer CORS — drawImage funciona mesmo cross-origin (canvas fica "tainted"
/// mas só impede leitura de pixels, não exibição).
Widget buildGifHtmlViewPaused(String url, double height) {
  final id = 'gif_paused_${url.hashCode}';

  if (!_registeredGifIds.contains(id)) {
    _registeredGifIds.add(id);
    ui_web.platformViewRegistry.registerViewFactory(id, (_) {
      final div = web.document.createElement('div') as web.HTMLDivElement
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.display = 'flex'
        ..style.alignItems = 'center'
        ..style.justifyContent = 'center'
        ..style.backgroundColor = 'white';

      final canvas =
          web.document.createElement('canvas') as web.HTMLCanvasElement
            ..style.maxWidth = '100%'
            ..style.maxHeight = '100%'
            ..style.objectFit = 'contain';

      // Carrega o GIF sem crossOrigin → drawImage funciona, canvas fica tainted
      final img = web.document.createElement('img') as web.HTMLImageElement
        ..src = url;
      img.onload = (web.Event _) {
        canvas.width = img.naturalWidth;
        canvas.height = img.naturalHeight;
        final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D;
        ctx.drawImage(img, 0, 0);
      }.toJS;

      div.append(canvas);
      return div;
    });
  }

  return SizedBox(
    height: height,
    width: double.infinity,
    child: HtmlElementView(viewType: id),
  );
}
