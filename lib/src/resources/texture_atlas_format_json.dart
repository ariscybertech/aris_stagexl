part of stagexl.resources;

class _TextureAtlasFormatJson extends TextureAtlasFormat {
  const _TextureAtlasFormatJson();

  @override
  Future<TextureAtlas> load(TextureAtlasLoader loader) async {
    var source = await loader.getSource();
    var pixelRatio = loader.getPixelRatio();
    var textureAtlas = TextureAtlas(pixelRatio);

    var json = jsonDecode(source);
    var frames = json['frames'];
    var meta = json['meta'] as Map;
    var image = meta['image'] as String;
    var renderTextureQuad = await loader.getRenderTextureQuad(image);

    if (frames is List) {
      for (var frame in frames) {
        var frameMap = frame as Map;
        var fileName = frameMap['filename'] as String;
        var frameName = getFilenameWithoutExtension(fileName);
        _createFrame(
            textureAtlas, renderTextureQuad, frameName, frameMap, meta);
      }
    }

    if (frames is Map) {
      for (String fileName in frames.keys) {
        var frameMap = frames[fileName] as Map;
        var frameName = getFilenameWithoutExtension(fileName);
        _createFrame(
            textureAtlas, renderTextureQuad, frameName, frameMap, meta);
      }
    }

    return textureAtlas;
  }

  //---------------------------------------------------------------------------

  void _createFrame(
      TextureAtlas textureAtlas,
      RenderTextureQuad renderTextureQuad,
      String frameName,
      Map frameMap,
      Map metaMap) {
    var rotation = ensureBool(frameMap['rotated'] as bool) ? 1 : 0;
    var offsetX = ensureInt(frameMap['spriteSourceSize']['x']);
    var offsetY = ensureInt(frameMap['spriteSourceSize']['y']);
    var originalWidth = ensureInt(frameMap['sourceSize']['w']);
    var originalHeight = ensureInt(frameMap['sourceSize']['h']);
    var frameX = ensureInt(frameMap['frame']['x']);
    var frameY = ensureInt(frameMap['frame']['y']);
    var frameWidth = ensureInt(frameMap['frame'][rotation == 0 ? 'w' : 'h']);
    var frameHeight = ensureInt(frameMap['frame'][rotation == 0 ? 'h' : 'w']);

    Float32List vxList;
    Int16List ixList;

    if (frameMap.containsKey('vertices')) {
      var vertices = frameMap['vertices'] as List;
      var verticesUV = frameMap['verticesUV'] as List;
      var triangles = frameMap['triangles'] as List;
      var width = metaMap['size']['w'].toInt();
      var height = metaMap['size']['h'].toInt();

      vxList = Float32List(vertices.length * 4);
      ixList = Int16List(triangles.length * 3);

      for (var i = 0, j = 0; i <= vxList.length - 4; i += 4, j += 1) {
        vxList[i + 0] = vertices[j][0] * 1.0;
        vxList[i + 1] = vertices[j][1] * 1.0;
        vxList[i + 2] = verticesUV[j][0] / width;
        vxList[i + 3] = verticesUV[j][1] / height;
      }

      for (var i = 0, j = 0; i <= ixList.length - 3; i += 3, j += 1) {
        ixList[i + 0] = triangles[j][0];
        ixList[i + 1] = triangles[j][1];
        ixList[i + 2] = triangles[j][2];
      }
    }

    var taf = TextureAtlasFrame(
        textureAtlas,
        renderTextureQuad,
        frameName,
        rotation,
        offsetX,
        offsetY,
        originalWidth,
        originalHeight,
        frameX,
        frameY,
        frameWidth,
        frameHeight,
        vxList,
        ixList);

    textureAtlas.frames.add(taf);
  }
}
