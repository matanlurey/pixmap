// Copyright 2017, Google Inc.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:collection/collection.dart';

/// An abstraction around a drawable Sprite within Dart web applications.
///
/// A [Sprite] can be created one of five ways:
/// * [Sprite.fromBlob]
/// * [Sprite.fromCanvas]
/// * [Sprite.fromImage]
/// * [Sprite.fromUrl]
/// * or using the [from] method to create a sprite from a larger sprite sheet.
///
/// You may also create a Sprite [Map] with the [toMap] method.
abstract class Sprite {
  /// Creates a [Sprite] extracted from a [blob].
  factory Sprite.fromBlob(Blob blob) {
    final url = Url.createObjectUrlFromBlob(blob);
    return new _ImageSprite(new ImageElement(src: url));
  }

  /// Creates a [Sprite] by *copying* an existing bitmap drawn to a [canvas].
  factory Sprite.fromCanvas(CanvasElement canvas) {
    final copy = new CanvasElement(width: canvas.width, height: canvas.height);
    (copy.getContext('2d') as CanvasRenderingContext2D).drawImage(canvas, 0, 0);
    return new _CanvasSprite(copy);
  }

  /// Creates a [Sprite] by *copying* an existing bitmap from an [image].
  factory Sprite.fromImage(ImageElement image) {
    final copy = new ImageElement(
      src: image.src,
      width: image.width,
      height: image.height,
    );
    return new _ImageSprite(copy);
  }

  /// Creates a [Sprite] from a data [url].
  factory Sprite.fromUrl(Uri url) {
    if (url.data == null) {
      throw new ArgumentError.value(url, 'url', 'Expected a data URL');
    }
    return new _ImageSprite(new ImageElement(src: url.toString()));
  }

  const Sprite._();

  /// Draws the sprite on a `<canvas>` 2D rendering [context] at [x], [y].
  void draw(CanvasRenderingContext2D context, int x, int y, {num scale: 1.0}) {
    context.drawImageScaled(_toSource(), x, y, width * scale, height * scale);
  }

  /// Returns a new [Sprite] extracted from [dimensions].
  Sprite from(Rectangle<int> dimensions) => new _ExtractSprite(this,
      dimensions.width, dimensions.height, dimensions.left, dimensions.top);

  /// Width of the sprite, in pixels.
  int get width;

  /// Height of the sprite, in pixels.
  int get height;

  /// Returns an [ImageElement].
  ImageElement toImage([num quality]);

  /// **INTERNAL ONLY**: As a 2D rendering object.
  CanvasImageSource _toSource() => toImage();

  /// Creates a sprite map that selects sprites based on a predefined size.
  Map<Point<int>, Sprite> toMap(int width, int height) =>
      new _SpriteMap(this, new Point(width, height));
}

class _SpriteMap extends UnmodifiableMapMixin<Point<int>, Sprite> {
  final Sprite _sprite;
  final Point<int> _dimensions;

  _SpriteMap(this._sprite, this._dimensions);

  @override
  Sprite operator [](covariant Point<int> key) => _sprite.from(new Rectangle(
      key.x * _dimensions.x,
      key.y * _dimensions.y,
      _dimensions.x,
      _dimensions.y));

  @override
  bool containsKey(covariant Point<int> key) {
    final location = key + _dimensions;
    return location.x <= _sprite.width && location.y <= _sprite.height;
  }

  @override
  bool containsValue(covariant Sprite value) => false;

  @override
  void forEach(void f(Point<int> key, Sprite value)) {
    keys.forEach((point) => f(point, this[point]));
  }

  @override
  bool get isEmpty => length == 0;

  @override
  bool get isNotEmpty => !isEmpty;

  @override
  Iterable<Point<int>> get keys sync* {
    final width = _sprite.width;
    final height = _sprite.height;
    var x = 0;
    for (var w = 0; w <= width; w += _dimensions.x) {
      var y = 0;
      for (var h = 0; h <= height; h += _dimensions.y) {
        yield new Point(x, y++);
      }
      x++;
    }
  }

  @override
  int get length {
    final width = _sprite.width;
    final height = _sprite.height;
    return width * height ~/ _dimensions.x * _dimensions.y;
  }

  @override
  Iterable<Sprite> get values => keys.map((p) => this[p]);
}

class _ExtractSprite extends Sprite {
  final Sprite _origin;
  final int _x;
  final int _y;

  const _ExtractSprite(
    this._origin,
    this.width,
    this.height,
    this._x,
    this._y,
  )
      : super._();

  @override
  bool operator ==(Object o) =>
      o is _ExtractSprite &&
      _origin == o._origin &&
      _x == o._x &&
      _y == o._y &&
      width == o.width &&
      height == o.height;

  @override
  int get hashCode =>
      _origin.hashCode ^
      _x.hashCode ^
      _y.hashCode ^
      width.hashCode ^
      height.hashCode;

  @override
  void draw(CanvasRenderingContext2D context, int x, int y, {num scale: 1.0}) {
    context.drawImageScaledFromSource(
      _origin._toSource(),
      _x,
      _y,
      width,
      height,
      x,
      y,
      width * scale,
      height * scale,
    );
  }

  @override
  final int width;

  @override
  final int height;

  @override
  ImageElement toImage([num quality]) {
    final canvas = new CanvasElement(width: width, height: height);
    final context = canvas.getContext('2d') as CanvasRenderingContext2D;
    // ignore: cascade_invocations
    context.drawImageScaledFromSource(
      _origin.toImage(),
      _x,
      _y,
      width,
      height,
      0,
      0,
      width,
      height,
    );
    return new _CanvasSprite(canvas).toImage(quality);
  }
}

class _CanvasSprite extends Sprite {
  final CanvasElement _canvas;

  const _CanvasSprite(this._canvas) : super._();

  @override
  bool operator ==(Object o) => o is _ImageSprite && _canvas == o._image;

  @override
  int get hashCode => _canvas.hashCode;

  @override
  int get width => _canvas.width;

  @override
  int get height => _canvas.height;

  @override
  ImageElement toImage([num quality]) =>
      new ImageElement(src: _canvas.toDataUrl('image/png', quality));

  @override
  CanvasImageSource _toSource() => _canvas;
}

class _ImageSprite extends Sprite {
  final ImageElement _image;

  const _ImageSprite(this._image) : super._();

  @override
  bool operator ==(Object o) => o is _ImageSprite && _image == o._image;

  @override
  int get hashCode => _image.hashCode;

  @override
  int get width => _image.width;

  @override
  int get height => _image.height;

  @override
  ImageElement toImage([_]) =>
      new ImageElement(src: _image.src, width: width, height: height);

  @override
  CanvasImageSource _toSource() => _image;
}
