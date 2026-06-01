import UIKit

@main
class PsychoAppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    let hackEngine = HackEngine.shared
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // إنشاء النافذة
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = PsychoSidePanel()
        window?.makeKeyAndVisible()
        window?.windowLevel = .statusBar + 2  // فوق كل شيء
        
        // تفعيل الحماية فوراً
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.hackEngine.activateAllShields()
        }
        
        print("[Psycho] ✅ التطبيق جاهز")
        return true
    }
}