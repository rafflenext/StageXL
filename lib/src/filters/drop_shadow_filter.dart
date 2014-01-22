part of stagexl;

class DropShadowFilter extends BitmapFilter {

  num distance;
  num angle;
  int color;
  num alpha;
  int blurX;
  int blurY;
  bool hideObject;

  DropShadowFilter([this.distance = 4.0, this.angle = PI / 4, this.color = 0, this.alpha = 1.0,
                    this.blurX = 4, this.blurY = 4, this.hideObject = false]) {

    if (blurX < 1 || blurY < 1)
      throw new ArgumentError("Error #9004: The minimum blur size is 1.");

    if (blurX > 64 || blurY > 64)
      throw new ArgumentError("Error #9004: The maximum blur size is 64.");
  }

  //-------------------------------------------------------------------------------------------------
  //-------------------------------------------------------------------------------------------------

  BitmapFilter clone() =>
      new DropShadowFilter(distance, angle, color, alpha, blurX, blurY, hideObject);

  Rectangle get overlap {
    var shiftX = (this.distance * cos(this.angle)).round();
    var shiftY = (this.distance * sin(this.angle)).round();
    var sRect = new Rectangle(0, 0, 0, 0);
    var dRect = new Rectangle(shiftX - blurX, shiftY - blurY, 2 * blurX, 2 * blurY);
    return sRect.union(dRect);
  }

  //-------------------------------------------------------------------------------------------------

  void apply(BitmapData bitmapData, [Rectangle rectangle]) {

    RenderTextureQuad renderTextureQuad = rectangle == null
        ? bitmapData.renderTextureQuad
        : bitmapData.renderTextureQuad.cut(rectangle);

    ImageData sourceImageData = this.hideObject ? null : renderTextureQuad.getImageData();
    ImageData imageData = renderTextureQuad.getImageData();
    List<int> data = imageData.data;
    int width = _ensureInt(imageData.width);
    int height = _ensureInt(imageData.height);
    int shiftX = (this.distance * cos(this.angle)).round();
    int shiftY = (this.distance * sin(this.angle)).round();

    num pixelRatio = renderTextureQuad.renderTexture.storePixelRatio;
    int blurX = (this.blurX * pixelRatio).round();
    int blurY = (this.blurY * pixelRatio).round();
    int alphaChannel = _isLittleEndianSystem ? 3 : 0;
    int stride = width * 4;

    _shiftChannel(data, 3, width, height, shiftX, shiftY);

    for (int x = 0; x < width; x++) {
      _blur2(data, x * 4 + alphaChannel, height, stride, blurY);
    }

    for (int y = 0; y < height; y++) {
      _blur2(data, y * stride + alphaChannel, width, 4, blurX);
    }

    if (this.hideObject) {
      _setColor(data, this.color, this.alpha);
    } else {
      _setColorBlend(data, this.color, this.alpha, sourceImageData.data);
    }

    renderTextureQuad.putImageData(imageData);
  }

}
