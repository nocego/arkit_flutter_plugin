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
                            //print("Model config: \(modelConfigData)")
                            //print(modelConfigData)

                            if let modelConfigData = modelsConfig[imageName] as? String {
                                do {
                                    let jsonData = modelConfigData.data(using: .utf8)!
                                    if let modelConfigDict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {

                                        //print("modelConfigDict: \(modelConfigDict)")

                                        // Create a new dictionary with the desired key order
                                        let orderedModelConfigData: [String: Any] = [
                                            "dartType": modelConfigDict["dartType"] as! String,
                                            "name": modelConfigDict["name"] as! String,
                                            "isHidden": modelConfigDict["isHidden"] as! Int,
                                            "renderingOrder": modelConfigDict["renderingOrder"] as! Int,
                                            "assetType": modelConfigDict["assetType"] as! Int,
                                            "url": modelConfigDict["url"] as! String
                                        ]


                                        //print("orderedModelConfigData: \(orderedModelConfigData)")

                                        let nodeToAdd = createNode(nil, fromDict: orderedModelConfigData, forDevice: sceneView.device, channel: channel)
                                        nodeToAdd.position.x += (modelConfigDict["relativePositionX"] as! NSNumber).floatValue
                                        nodeToAdd.position.y += (modelConfigDict["relativePositionY"] as! NSNumber).floatValue
                                        nodeToAdd.position.z += (modelConfigDict["relativePositionZ"] as! NSNumber).floatValue
                                        //print("node: \(node)")
                                        node.addChildNode(nodeToAdd)
                                    }
                                    //print("URL: \(modelConfig.url)")
                                    //let geometryArguments = nil
                                    //let geometry = createGeometry(nil, withDevice: sceneView.device)
                                    //let node = createNode(geometry, fromDict: modelConfig, forDevice: sceneView.device, channel: channel)
                                    //print("node: \(node)")
                                } catch {
                                    print("Failed to decode modelConfig: \(error)")
                                }
                            } else {
                                print("modelConfigData is not a valid string")
                            }
                        } else {
                            print("Model config not found for key 'nils_saas-grund_theater_erlebnisbank'")
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
