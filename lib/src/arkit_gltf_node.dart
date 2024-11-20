import 'package:arkit_plugin/src/arkit_node.dart';
import 'package:arkit_plugin/src/enums/asset_type.dart';

/// Node in .gltf or .glb file format.
class ARKitGltfNode extends ARKitNode {
  ARKitGltfNode({
    this.assetType = AssetType.documents,
    required this.url,
    super.physicsBody,
    super.light,
    super.position,
    super.scale,
    super.eulerAngles,
    super.name,
    super.renderingOrder,
    super.isHidden,
    double? relativePositionX,
    double? relativePositionY,
    double? relativePositionZ,
  })  : relativePositionX = relativePositionX ?? 0,
        relativePositionY = relativePositionY ?? 0,
        relativePositionZ = relativePositionZ ?? 0;

  /// Path to the asset.
  final String url;

  /// Describes the location of the asset.
  final AssetType assetType;

  /// relative positioning of the node in the x-axis
  final double relativePositionX;

  /// relative positioning of the node in the y-axis
  final double relativePositionY;

  /// relative positioning of the node in the z-axis
  final double relativePositionZ;

  @override
  Map<String, dynamic> toMap() => <String, dynamic>{
        'url': url,
        'assetType': assetType.index
      }..addAll(super.toMap());

  String toJsonString() {
    // transform fehlt noch
    return '{"assetType": ${assetType.index}, "name": "${super.name}", "renderingOrder": ${super.renderingOrder}, "url": "$url", "isHidden": 0, "dartType": "ARKitGltfNode", "relativePositionX": $relativePositionX, "relativePositionY": $relativePositionY, "relativePositionZ": $relativePositionZ}';
  }
}
