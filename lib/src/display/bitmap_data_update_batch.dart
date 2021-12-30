part of stagexl.display;

/// The [BitmapDataUpdateBatch] class provides all the [BitmapData] update
/// methods, but does not automatically update the underlying WebGL texture.
/// This improves the performance for multiple updates to the BitmapData.
/// Once all updates are done, call the [update] method to update the
/// underlying WebGL texture.

class BitmapDataUpdateBatch {
  final BitmapData bitmapData;
  final RenderContextCanvas _renderContext;
  final Matrix _drawMatrix;

  BitmapDataUpdateBatch(BitmapData bitmapData)
      : bitmapData = bitmapData,
        _renderContext = RenderContextCanvas(bitmapData.renderTexture.canvas),
        _drawMatrix = bitmapData.renderTextureQuad.drawMatrix;

  //---------------------------------------------------------------------------

  /// Update the underlying rendering surface.

  void update() => bitmapData.renderTexture.update();

  //---------------------------------------------------------------------------

  void applyFilter(BitmapFilter filter, [Rectangle<num> rectangle]) {
    filter.apply(bitmapData, rectangle);
  }

  //---------------------------------------------------------------------------

  void colorTransform(Rectangle<num> rectangle, ColorTransform transform) {
    var isLittleEndianSystem = env.isLittleEndianSystem;

    var redMultiplier = (1024 * transform.redMultiplier).toInt();
    var greenMultiplier = (1024 * transform.greenMultiplier).toInt();
    var blueMultiplier = (1024 * transform.blueMultiplier).toInt();
    var alphaMultiplier = (1024 * transform.alphaMultiplier).toInt();

    var redOffset = transform.redOffset;
    var greenOffset = transform.greenOffset;
    var blueOffset = transform.blueOffset;
    var alphaOffset = transform.alphaOffset;

    var mulitplier0 = isLittleEndianSystem ? redMultiplier : alphaMultiplier;
    var mulitplier1 = isLittleEndianSystem ? greenMultiplier : blueMultiplier;
    var mulitplier2 = isLittleEndianSystem ? blueMultiplier : greenMultiplier;
    var mulitplier3 = isLittleEndianSystem ? alphaMultiplier : redMultiplier;

    var offset0 = isLittleEndianSystem ? redOffset : alphaOffset;
    var offset1 = isLittleEndianSystem ? greenOffset : blueOffset;
    var offset2 = isLittleEndianSystem ? blueOffset : greenOffset;
    var offset3 = isLittleEndianSystem ? alphaOffset : redOffset;

    var renderTextureQuad = bitmapData.renderTextureQuad.cut(rectangle);
    var imageData = renderTextureQuad.getImageData();
    var data = imageData.data;

    for (var i = 0; i <= data.length - 4; i += 4) {
      var c0 = data[i + 0];
      var c1 = data[i + 1];
      var c2 = data[i + 2];
      var c3 = data[i + 3];

      if (c0 is! num) continue; // dart2js hint
      if (c1 is! num) continue; // dart2js hint
      if (c2 is! num) continue; // dart2js hint
      if (c3 is! num) continue; // dart2js hint

      data[i + 0] = offset0 + (((c0 * mulitplier0) | 0) >> 10);
      data[i + 1] = offset1 + (((c1 * mulitplier1) | 0) >> 10);
      data[i + 2] = offset2 + (((c2 * mulitplier2) | 0) >> 10);
      data[i + 3] = offset3 + (((c3 * mulitplier3) | 0) >> 10);
    }

    renderTextureQuad.putImageData(imageData);
  }

  //---------------------------------------------------------------------------

  /// See [BitmapData.clear]

  void clear() {
    _renderContext.setTransform(_drawMatrix);
    _renderContext.rawContext
        .clearRect(0, 0, bitmapData.width, bitmapData.height);
  }

  //---------------------------------------------------------------------------

  void fillRect(Rectangle<num> rectangle, int color) {
    _renderContext.setTransform(_drawMatrix);
    _renderContext.rawContext.fillStyle = color2rgba(color);
    _renderContext.rawContext.fillRect(
        rectangle.left, rectangle.top, rectangle.width, rectangle.height);
  }

  //---------------------------------------------------------------------------

  void draw(BitmapDrawable source, [Matrix matrix]) {
    var renderState = RenderState(_renderContext, _drawMatrix);
    if (matrix != null) renderState.globalMatrix.prepend(matrix);
    source.render(renderState);
  }

  //---------------------------------------------------------------------------

  /// See [BitmapData.copyPixels]

  void copyPixels(
      BitmapData source, Rectangle<num> sourceRect, Point<num> destPoint) {
    var sourceQuad = source.renderTextureQuad.cut(sourceRect);
    var renderState = RenderState(_renderContext, _drawMatrix);
    renderState.globalMatrix.prependTranslation(destPoint.x, destPoint.y);
    _renderContext.setTransform(renderState.globalMatrix);
    _renderContext.rawContext
        .clearRect(0, 0, sourceRect.width, sourceRect.height);
    _renderContext.renderTextureQuad(renderState, sourceQuad);
  }

  //---------------------------------------------------------------------------

  /// See [BitmapData.drawPixels]

  void drawPixels(
      BitmapData source, Rectangle<num> sourceRect, Point<num> destPoint,
      [BlendMode blendMode]) {
    var sourceQuad = source.renderTextureQuad.cut(sourceRect);
    var renderState = RenderState(_renderContext, _drawMatrix, 1.0, blendMode);
    renderState.globalMatrix.prependTranslation(destPoint.x, destPoint.y);
    renderState.renderTextureQuad(sourceQuad);
  }

  //---------------------------------------------------------------------------

  /// See [BitmapData.getPixel32]

  int getPixel32(num x, num y) {
    var r = 0, g = 0, b = 0, a = 0;

    var rectangle = Rectangle<num>(x, y, 1, 1);
    var renderTextureQuad = bitmapData.renderTextureQuad.clip(rectangle);
    if (renderTextureQuad.sourceRectangle.isEmpty) return Color.Transparent;

    var isLittleEndianSystem = env.isLittleEndianSystem;
    var imageData = renderTextureQuad.getImageData();
    var pixels = imageData.width * imageData.height;
    var data = imageData.data;

    for (var i = 0; i <= data.length - 4; i += 4) {
      r += isLittleEndianSystem ? data[i + 0] : data[i + 3];
      g += isLittleEndianSystem ? data[i + 1] : data[i + 2];
      b += isLittleEndianSystem ? data[i + 2] : data[i + 1];
      a += isLittleEndianSystem ? data[i + 3] : data[i + 0];
    }

    r = r ~/ pixels;
    g = g ~/ pixels;
    b = b ~/ pixels;
    a = a ~/ pixels;

    return (a << 24) + (r << 16) + (g << 8) + b;
  }

  //---------------------------------------------------------------------------

  /// See [BitmapData.setPixel32]

  void setPixel32(num x, num y, int color) {
    _renderContext.setTransform(_drawMatrix);
    _renderContext.rawContext.fillStyle = color2rgba(color);
    _renderContext.rawContext.clearRect(x, y, 1, 1);
    _renderContext.rawContext.fillRect(x, y, 1, 1);
  }
}
