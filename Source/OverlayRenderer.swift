import UIKit
import QuartzCore

class OverlayRenderer {
    
    static let shared = OverlayRenderer()
    
    private var overlayWindow: UIWindow?
    private var trajectoryLayer: CAShapeLayer?
    private var ballIndicatorLayers: [Int: CALayer] = [:]
    
    // MARK: - إظهار الـ Overlay
    func showOverlay() {
        guard overlayWindow == nil else { return }
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.windowLevel = .statusBar + 3
        window.backgroundColor = .clear
        window.isUserInteractionEnabled = false
        
        let view = UIView(frame: window.bounds)
        view.backgroundColor = .clear
        
        // طبقة المسارات
        let layer = CAShapeLayer()
        layer.frame = view.bounds
        layer.backgroundColor = UIColor.clear.cgColor
        view.layer.addSublayer(layer)
        trajectoryLayer = layer
        
        window.addSubview(view)
        window.makeKeyAndVisible()
        overlayWindow = window
        
        // بدء الرسم
        startRendering()
    }
    
    // MARK: - رسم المسارات
    func drawTrajectory(from startX: Float, startY: Float, angle: Float, power: Float, balls: [BallData]) {
        guard let layer = trajectoryLayer else { return }
        
        // مسح المسارات القديمة
        layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        let rad = angle * .pi / 180
        var x = CGFloat(startX)
        var y = CGFloat(startY)
        let velX = CGFloat(cos(rad) * power * 0.3)
        let velY = CGFloat(sin(rad) * power * 0.3)
        
        // المسار الرئيسي (من العصا)
        let mainPath = UIBezierPath()
        mainPath.move(to: CGPoint(x: x, y: y))
        
        var collisionPoint: CGPoint?
        var collidedBallId: Int?
        
        for step in 0..<200 {
            x += velX * 0.1
            y += velY * 0.1
            
            // التحقق من التصادم
            for ball in balls where ball.id != -1 && !ball.isCueBall {
                let dx = Float(x) - ball.x
                let dy = Float(y) - ball.y
                let dist = hypotf(dx, dy)
                
                if dist < 20 && collisionPoint == nil {
                    collisionPoint = CGPoint(x: x, y: y)
                    collidedBallId = ball.id
                    
                    // رسم مسار الكرة المصطدمة
                    let ballRad = atan2(Float(velY), Float(velX))
                    let ballVelX = cos(ballRad) * power * 0.3 * 0.6
                    let ballVelY = sin(ballRad) * power * 0.3 * 0.6
                    
                    var bx = x + CGFloat(cos(rad) * 12)
                    var by = y + CGFloat(sin(rad) * 12)
                    
                    let ballPath = UIBezierPath()
                    ballPath.move(to: CGPoint(x: bx, y: by))
                    
                    for _ in 0..<100 {
                        bx += CGFloat(ballVelX) * 0.1
                        by += CGFloat(ballVelY) * 0.1
                        ballPath.addLine(to: CGPoint(x: bx, y: by))
                    }
                    
                    let ballLineLayer = CAShapeLayer()
                    ballLineLayer.path = ballPath.cgPath
                    
                    // لون المسار حسب صاحب الكرة
                    if ball.owner == .myBall {
                        ballLineLayer.strokeColor = UIColor.green.withAlphaComponent(0.8).cgColor
                    } else if ball.owner == .opponentBall {
                        ballLineLayer.strokeColor = UIColor.red.withAlphaComponent(0.6).cgColor
                    } else {
                        ballLineLayer.strokeColor = UIColor.blue.withAlphaComponent(0.5).cgColor
                    }
                    
                    ballLineLayer.fillColor = UIColor.clear.cgColor
                    ballLineLayer.lineWidth = 2.0
                    ballLineLayer.lineDashPattern = [6, 4]
                    layer.addSublayer(ballLineLayer)
                    
                    break
                }
            }
            
            mainPath.addLine(to: CGPoint(x: x, y: y))
            
            // التحقق من دخول الجيب
            let distToNearestPocket = distanceToNearestPocket(from: CGPoint(x: x, y: y))
            if distToNearestPocket < 25 {
                // إضافة دائرة حول الجيب المستهدف
                let pocketLayer = CAShapeLayer()
                let pocketPath = UIBezierPath(ovalIn: CGRect(x: x-10, y: y-10, width: 20, height: 20))
                pocketLayer.path = pocketPath.cgPath
                
                if let ballId = collidedBallId {
                    let ball = balls.first { $0.id == ballId }
                    if ball?.owner == .myBall {
                        pocketLayer.strokeColor = UIColor.green.cgColor
                        pocketLayer.fillColor = UIColor.green.withAlphaComponent(0.3).cgColor
                    } else {
                        pocketLayer.strokeColor = UIColor.red.cgColor
                        pocketLayer.fillColor = UIColor.red.withAlphaComponent(0.3).cgColor
                    }
                }
                
                pocketLayer.lineWidth = 2
                layer.addSublayer(pocketLayer)
                break
            }
            
            if abs(velX) < 0.1 && abs(