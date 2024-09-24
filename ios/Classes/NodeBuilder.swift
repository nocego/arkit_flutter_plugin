import ARKit
import GLTFSceneKit
import GLTFKit2

func createNode(_ geometry: SCNGeometry?, fromDict dict: [String: Any], forDevice device: MTLDevice?, channel: FlutterMethodChannel) -> SCNNode {
    let dartType = dict["dartType"] as! String
    let node: SCNNode

    switch dartType {
    case "ARKitReferenceNode":
        node = createReferenceNode(dict)
    case "ARKitGltfNode":
        node = createGltfNode(dict, channel: channel)
    default:
        node = SCNNode(geometry: geometry)
    }

    updateNode(node, fromDict: dict, forDevice: device)
    return node
}

func updateNode(_ node: SCNNode, fromDict dict: [String: Any], forDevice device: MTLDevice?) {
    if let transform = dict["transform"] as? [NSNumber] {
        node.transform = deserializeMatrix4(transform)
    }

    if let name = dict["name"] as? String {
        node.name = name
    }

    if let physicsBody = dict["physicsBody"] as? [String: Any] {
        node.physicsBody = createPhysicsBody(physicsBody, forDevice: device)
    }

    if let light = dict["light"] as? [String: Any] {
        node.light = createLight(light)
    }

    if let renderingOrder = dict["renderingOrder"] as? Int {
        node.renderingOrder = renderingOrder
    }

    if let isHidden = dict["isHidden"] as? Bool {
        node.isHidden = isHidden
    }
}

private func createGltfNode(_ dict: [String: Any], channel: FlutterMethodChannel) -> SCNNode {
    let url = dict["url"] as! String
    let urlLowercased = url.lowercased()
    let node = SCNNode()

    if urlLowercased.hasSuffix(".gltf") || urlLowercased.hasSuffix(".glb") {
        let assetTypeIndex = dict["assetType"] as? Int
        let isFromFlutterAssets = assetTypeIndex == 0

        do {
            let filePath: String
            if isFromFlutterAssets {
                let modelPath = FlutterDartProject.lookupKey(forAsset: url)
                filePath = Bundle.main.path(forResource: modelPath, ofType: nil)!
            } else {
                let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                let documentsDirectory = paths[0]
                filePath = documentsDirectory.appendingPathComponent(url).path
            }

            // Set the Draco decompressor class
            //GLTFAsset.dracoDecompressorClassName = NSStringFromClass(MyDracoDecompressor.self)
            GLTFAsset.load(with: URL(fileURLWithPath: filePath), options: [:]) { (progress, status, maybeAsset, maybeError, _) in
                if let error = maybeError {
                    logPluginError("Failed to load file: \(error.localizedDescription)", toChannel: channel)
                    return
                }

                guard let asset = maybeAsset else {
                    logPluginError("Failed to load asset", toChannel: channel)
                    return
                }

                let source = GLTFSCNSceneSource(asset: asset)
                var animations = [GLTFSCNAnimation]()
                animations = source.animations
                NSLog("Animations count: \(animations.count)")
                NSLog("Animations: \(animations.debugDescription)")

                let scene = SCNScene(gltfAsset: asset)
                for child in scene.rootNode.childNodes {
                    node.addChildNode(child.flattenedClone())
                }

                // Add animations to each child node
                for child in node.childNodes {
                    if let defaultAnimation = animations.first {
                        defaultAnimation.animationPlayer.animation.usesSceneTimeBase = false
                        defaultAnimation.animationPlayer.animation.repeatCount = .greatestFiniteMagnitude
                        child.addAnimationPlayer(defaultAnimation.animationPlayer, forKey: nil)
                        defaultAnimation.animationPlayer.play()
                    }
                }
            }

            if let name = dict["name"] as? String {
                node.name = name
            }
            if let transform = dict["transform"] as? [NSNumber] {
                node.transform = deserializeMatrix4(transform)
            }

        } catch {
            logPluginError("Failed to load file: \(error.localizedDescription)", toChannel: channel)
        }
    } else {
        logPluginError("Only .gltf or .glb files are supported.", toChannel: channel)
    }
    return node
}

private func createReferenceNode(_ dict: [String: Any]) -> SCNReferenceNode {
    let url = dict["url"] as! String
    let referenceUrl: URL
    if let bundleURL = Bundle.main.url(forResource: url, withExtension: nil) {
        referenceUrl = bundleURL
    } else {
        referenceUrl = URL(fileURLWithPath: url)
    }
    let node = SCNReferenceNode(url: referenceUrl)
    node?.load()
    return node!
}

private func createPhysicsBody(_ dict: [String: Any], forDevice device: MTLDevice?) -> SCNPhysicsBody {
    var shape: SCNPhysicsShape?
    if let shapeDict = dict["shape"] as? [String: Any],
       let shapeGeometry = shapeDict["geometry"] as? [String: Any]
    {
        let geometry = createGeometry(shapeGeometry, withDevice: device)
        shape = SCNPhysicsShape(geometry: geometry!, options: nil)
    }
    let type = dict["type"] as! Int
    let bodyType = SCNPhysicsBodyType(rawValue: type)
    let physicsBody = SCNPhysicsBody(type: bodyType!, shape: shape)
    if let categoryBitMack = dict["categoryBitMask"] as? Int {
        physicsBody.categoryBitMask = categoryBitMack
    }
    return physicsBody
}

private func createLight(_ dict: [String: Any]) -> SCNLight {
    let light = SCNLight()
    if let type = dict["type"] as? Int {
        switch type {
        case 0:
            light.type = .ambient
        case 1:
            light.type = .omni
        case 2:
            light.type = .directional
        case 3:
            light.type = .spot
        case 4:
            light.type = .IES
        case 5:
            light.type = .probe
        case 6:
            if #available(iOS 13.0, *) {
                light.type = .area
            } else {
                // error
                light.type = .omni
            }
        default:
            light.type = .omni
        }
    } else {
        light.type = .omni
    }
    if let temperature = dict["temperature"] as? Double {
        light.temperature = CGFloat(temperature)
    }
    if let intensity = dict["intensity"] as? Double {
        light.intensity = CGFloat(intensity)
    }
    if let spotInnerAngle = dict["spotInnerAngle"] as? Double {
        light.spotInnerAngle = CGFloat(spotInnerAngle)
    }
    if let spotOuterAngle = dict["spotOuterAngle"] as? Double {
        light.spotOuterAngle = CGFloat(spotOuterAngle)
    }
    if let color = dict["color"] as? Int {
        light.color = UIColor(rgb: UInt(color))
    }
    return light
}
