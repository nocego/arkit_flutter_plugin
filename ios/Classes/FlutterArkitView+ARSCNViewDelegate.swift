import ARKit
import Foundation

struct ModelConfig: Codable {
    let url: String
    let assetType: Int
    let name: String
}

extension FlutterArkitView: ARSCNViewDelegate {
    func session(_: ARSession, didFailWithError error: Error) {
        logPluginError("sessionDidFailWithError: \(error.localizedDescription)", toChannel: channel)
    }

    func session(_: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        var params = [String: NSNumber]()

        switch camera.trackingState {
        case .notAvailable:
            params["trackingState"] = 0
        case let .limited(reason):
            params["trackingState"] = 1
            switch reason {
            case .initializing:
                params["reason"] = 1
            case .relocalizing:
                params["reason"] = 2
            case .excessiveMotion:
                params["reason"] = 3
            case .insufficientFeatures:
                params["reason"] = 4
            default:
                params["reason"] = 0
            }
        case .normal:
            params["trackingState"] = 2
        }

        sendToFlutter("onCameraDidChangeTrackingState", arguments: params)
    }

    func sessionWasInterrupted(_: ARSession) {
        sendToFlutter("onSessionWasInterrupted", arguments: nil)
    }

    func sessionInterruptionEnded(_: ARSession) {
        sendToFlutter("onSessionInterruptionEnded", arguments: nil)
    }

    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
            let node = SCNNode()

            // Extract and parse modelsConfig
            if let arguments = arguments,
               let modelsConfig = arguments["modelsConfig"] as? [String: Any] {
                if let imageAnchor = anchor as? ARImageAnchor {
                    let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width,
                                          height: imageAnchor.referenceImage.physicalSize.height)

                    if let imageName = imageAnchor.referenceImage.name {
                        if let modelConfigData = modelsConfig[imageName] {
                            if let modelConfigDataArray = modelConfigData as? [String] {
                                let jsonArrayString = "[\(modelConfigDataArray.joined(separator: ","))]"
                                let jsonData = jsonArrayString.data(using: .utf8)!
                                do {
                                    if let jsonArray = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [[String: Any]] {
                                        for item in jsonArray {
                                            let orderedModelConfigData: [String: Any] = [
                                                "dartType": item["dartType"] as! String,
                                                "name": item["name"] as! String,
                                                "isHidden": item["isHidden"] as! Int,
                                                "renderingOrder": item["renderingOrder"] as! Int,
                                                "assetType": item["assetType"] as! Int,
                                                "url": item["url"] as! String
                                            ]
                                            let nodeToAdd = createNode(nil, fromDict: orderedModelConfigData, forDevice: sceneView.device, channel: channel)

                                            nodeToAdd.position.x += (item["relativePositionX"] as! NSNumber).floatValue
                                            nodeToAdd.position.y += (item["relativePositionY"] as! NSNumber).floatValue
                                            nodeToAdd.position.z += (item["relativePositionZ"] as! NSNumber).floatValue
                                            node.addChildNode(nodeToAdd)
                                        }
                                    }
                                } catch {
                                    print("Failed to decode JSON data: \(error)")
                                }
                            }
                        } else {
                            print("Model config not found for key \(imageName)")
                        }
                    }

/*
                    plane.firstMaterial?.diffuse.contents = UIColor(white: 1, alpha: 0.8)

                    let planeNode = SCNNode(geometry: plane)
                    planeNode.eulerAngles.x = -.pi / 2

                    node.addChildNode(planeNode)
 */
                }
            } else {
                print("modelsConfig is not a valid dictionary")
            }

            return node
        }

    func renderer(_: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if node.name == nil {
            node.name = NSUUID().uuidString
        }
        let params = prepareParamsForAnchorEvent(node, anchor)
        sendToFlutter("didAddNodeForAnchor", arguments: params)
    }

    func renderer(_: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        let params = prepareParamsForAnchorEvent(node, anchor)
        sendToFlutter("didUpdateNodeForAnchor", arguments: params)
    }

    func renderer(_: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        let params = prepareParamsForAnchorEvent(node, anchor)
        sendToFlutter("didRemoveNodeForAnchor", arguments: params)
    }

    func renderer(_: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        let params = ["time": NSNumber(floatLiteral: time)]
        sendToFlutter("updateAtTime", arguments: params)
    }

    fileprivate func prepareParamsForAnchorEvent(_ node: SCNNode, _ anchor: ARAnchor) -> [String: Any] {
        var serializedAnchor = serializeAnchor(anchor)
        serializedAnchor["nodeName"] = node.name
        return serializedAnchor
    }
}
