//
//  Utilities.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 20/09/25.
//

import Foundation
import UIKit

final class Utilities {
    static let shared = Utilities()
    
    private init() {}
    
    @MainActor
    func topViewController(controller: UIViewController? = nil) -> UIViewController? {
        var currentController: UIViewController? = controller
        
        if UIApplication.shared.connectedScenes.count == 1 {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                currentController = scene.keyWindow?.rootViewController
            }
        } else {
            for scene in UIApplication.shared.connectedScenes {
                if scene is UIWindowScene {
                    let scene = scene as! UIWindowScene
                    if let window = scene.keyWindow {
                        currentController = window.rootViewController
                        break
                    }
                }
            }
        }
        
        while let nextController: UIViewController? = {
            if let navigationController = currentController as? UINavigationController {
                return navigationController.visibleViewController
            } else if let tabController = currentController as? UITabBarController {
                return tabController.selectedViewController
            } else if let presented = currentController?.presentedViewController {
                return presented
            } else {
                return nil
            }
        }() {
            currentController = nextController
        }
        
        return currentController
    }
}
