import Foundation
import UIKit

class NeuralAI {
    
    static let shared = NeuralAI()
    
    // الشبكة العصبية المبسطة
    private let weights: [Float] = {
        var w = [Float](repeating: 0, count: 1000)
        for i in 0..<w.count {
            w[i] = Float.random(in: -0.1...0.1)
        }
        return w
    }()
    
    // ذاكرة الكرات
    private var knownBalls: [Int: BallOwner] = [:]
    private var myBallColors: [UIColor] = []
    private var opponentBallColors: [UIColor] = []
    private var isTrained = false
    
    // MARK: - تصنيف الكرات
    func classifyBall(_ ball: BallData) -> BallOwner {
        // إذا كان لدينا تصنيف سابق، استخدمه
        if let known = knownBalls[ball.id] {
            return known
        }
        
        // تحليل خصائص الكرة
        let score = analyzeBallFeatures(ball)
        let owner: BallOwner
        
        if score > 0.7 {
            owner = .myBall
        } else if score < 0.3 {
            owner = .opponentBall
        } else {
            owner = .uncertain
        }
        
        // حفظ التصنيف
        knownBalls[ball.id] = owner
        return owner
    }
    
    private func analyzeBallFeatures(_ ball: BallData) -> Float {
        var score: Float = 0.5 // قيمة افتراضية
        
        // 1. تحليل الموقع
        let centerX: Float = 500
        let centerY: Float = 250
        let distFromCenter = hypotf(ball.x - centerX, ball.y - centerY)
        let positionFactor = 1.0 - (distFromCenter / 600.0)
        score += positionFactor * 0.2
        
        // 2. تحليل اللون (إذا كان متاحاً)
        if ball.color != .clear {
            let isMyColor = myBallColors.contains { c in
                colorsMatch(c, ball.color)
            }
            let isOppColor = opponentBallColors.contains { c in
                colorsMatch(c, ball.color)
            }
            
            if isMyColor { score += 0.3 }
            if isOppColor { score -= 0.3 }
        }
        
        // 3. تحليل السرعة والاتجاه
        let speed = hypotf(ball.vx, ball.vy)
        if speed > 0 {
            // الكرات المتحركة باتجاه جيوبي عادةً ما تكون كرات الخصم
            score -= 0.1
        }
        
        // 4. تحليل الكتلة (Solid vs Stripe)
        if ball.isSolid {
            score += 0.1 // الكرات الصلبة عادة للاعب الأول
        } else if ball.isStripe {
            score -= 0.1 // الكرات المخططة للاعب الثاني
        }
        
        // تطبيع النتيجة بين 0 و 1
        return max(0, min(1, score))
    }
    
    private func colorsMatch(_ c1: UIColor, _ c2: UIColor) -> Bool {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        c1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        c2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        let diff = abs(r1 - r2) + abs(g1 - g2) + abs(b1 - b2)
        return diff < 0.3
    }
    
    // MARK: - تدريب سريع
    func learnInitialDistribution(balls: [BallData]) {
        guard !isTrained, balls.count >= 2 else { return }
        
        // تقسيم الكرات إلى مجموعتين بناءً على الموقع
        let sortedByX = balls.sorted { $0.x < $1.x }
        let half = sortedByX.count / 2
        
        let leftBalls = Array(sortedByX[0..<half])
        let rightBalls = Array(sortedByX[half..<sortedByX.count])
        
        // المجموعة الأقرب إلى الكرة البيضاء هي كراتي
        let cueBall = balls.first { $0.isCueBall }
        if let cue = cueBall {
            let distToLeft = leftBalls.reduce(0) { $0 + hypotf($1.x - cue.x, $1.y - cue.y) } / Float(leftBalls.count)
            let distToRight = rightBalls.reduce(0) { $0 + hypotf($1.x - cue.x, $1.y - cue.y) } / Float(rightBalls.count)
            
            let myBalls = distToLeft < distToRight ? leftBalls : rightBalls
            let oppBalls = distToLeft < distToRight ? rightBalls : leftBalls
            
            myBallColors = myBalls.compactMap { $0.color != .clear ? $0.color : nil }
            opponentBallColors = oppBalls.compactMap { $0.color != .clear ? $0.color : nil }
            
            // تسجيل التصنيفات
            for ball in myBalls {
                knownBalls[ball.id] = .myBall
            }
            for ball in oppBalls {
                knownBalls[ball.id] = .opponentBall
            }
            
            isTrained = true
            print("[NeuralAI] ✅ تم التعرف على \(myBalls.count) كراتي و \(oppBalls.count) كرات الخصم")
        }
    }
    
    // MARK: - حساب أفضل تسديدة
    func calculateBestShot(cueBall: BallData, myBalls: [BallData], allBalls: [BallData]) -> (angle: Float, power: Float) {
        var bestScore: Float = -Float.infinity
        var bestAngle: Float = 0
        var bestPower: Float = 50
        
        // تجربة زوايا مختلفة - تم استخدام Float لحل خطأ التجميع
        for angle in stride(from: Float(0), to: Float(360), by: Float(1.0)) {
            for power in stride(from: Float(30), to: Float(100), by: Float(2.0)) {
                let score = evaluateShot(angle: angle, power: power, cueBall: cueBall, myBalls: myBalls, allBalls: allBalls)
                
                if score > bestScore {
                    bestScore = score
                    bestAngle = angle
                    bestPower = power
                }
            }
        }
        
        return (bestAngle, bestPower)
    }
    
    private func evaluateShot(angle: Float, power: Float, cueBall: BallData, myBalls: [BallData], allBalls: [BallData]) -> Float {
        var score: Float = 0
        
        // محاكاة بسيطة للمسار
        let rad = angle * .pi / 180
        let velX = cos(rad) * power * 0.5
        let velY = sin(rad) * power * 0.5
        
        var cueX = cueBall.x
        var cueY = cueBall.y
        
        // تتبع المسار للعثور على أول تصادم - تم إزالة تحذير step غير المستخدم
        for _ in 0..<100 {
            cueX += velX * 0.1
            cueY += velY * 0.1
            
            for ball in allBalls where ball.id != cueBall.id {
                let dx = cueX - ball.x
                let dy = cueY - ball.y
                let dist = hypotf(dx, dy)
                
                if dist < 20 { // تصادم
                    if ball.owner == .myBall || knownBalls[ball.id] == .myBall {
                        score += 100 // مكافأة لضرب كرتي
                        
                        // التحقق مما إذا كانت ستتجه نحو الجيب
                        let pocketDist = calculateDistanceToNearestPocket(x: ball.x + ball.vx * 10, y: ball.y + ball.vy * 10)
                        if pocketDist < 50 {
                            score += 500 // مكافأة كبيرة لتسجيل هدف
                        }
                    } else {
                        score -= 200 // عقوبة لضرب كرة الخصم
                    }
                    
                    // التحقق من عدم دخول الكرة البيضاء
                    let cuePocketDist = calculateDistanceToNearestPocket(x: cueX, y: cueY)
                    if cuePocketDist < 30 {
                        score -= 1000 // عقوبة شديدة لدخول البيضاء
                    }
                    
                    break
                }
            }
        }
        
        return score
    }
    
    private func calculateDistanceToNearestPocket(x: Float, y: Float) -> Float {
        let pockets: [(Float, Float)] = [
            (50, 50), (500, 20), (950, 50),
            (50, 450), (500, 480), (950, 450)
        ]
        
        var minDist: Float = Float.infinity
        for (px, py) in pockets {
            let dist = hypotf(x - px, y - py)
            minDist = min(minDist, dist)
        }
        
        return minDist
    }
}

// MARK: - هياكل البيانات
struct BallData {
    let id: Int
    var x: Float
    var y: Float
    var vx: Float
    var vy: Float
    var color: UIColor
    var isCueBall: Bool
    var isSolid: Bool
    var isStripe: Bool
    var owner: BallOwner = .uncertain
    var radius: Float = 12
}

enum BallOwner {
    case myBall
    case opponentBall
    case uncertain
}
