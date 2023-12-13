import UIKit
import Firebase
import FirebaseRemoteConfig

class ViewController: UIViewController {
    
    private let view1:UIView = {
       let v = UIView()
        v.isHidden = true
        v.backgroundColor = .red
        return v
    }()
    
    private let view2: UIView = {
        let v = UIView()
        v.isHidden = true
        v.backgroundColor = .blue
        return v
    }()
    
    private let remoteConfig = RemoteConfig.remoteConfig()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(view1)
        view.addSubview(view2)
        
        fetchValues()
        // Fetch remote config values
    }
    
    func fetchValues(){
        let defaults: [String: NSObject] = [
            "shows_new_ui": true as NSObject
        ]
        
        remoteConfig.setDefaults(defaults)
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        remoteConfig.configSettings = settings
        
        self.remoteConfig.fetch(withExpirationDuration: 0) { (status, err) in
            if status == .success, err == nil {
                self.remoteConfig.activate { success, activationError in
                    guard success, activationError == nil else {
                        // Handle activation error
                        return
                    }
                    let value = self.remoteConfig.configValue(forKey: "shows_new_ui").boolValue
                    print("Fetch \(value)")
                }
            } else {
                print("Wrong fetching")
            }
        }


    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view1.frame = view.bounds
        view2.frame = view.bounds
    }
    
    
}
