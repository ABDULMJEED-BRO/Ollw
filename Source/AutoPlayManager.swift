import Foundation
import UIKit

class AutoPlayManager {
    
    static let shared = AutoPlayManager()
    
    private var isPlaying = false
    private var currentBalls: [BallData] = []
    private let neuralAI = NeuralAI.shared
    private let overlay = OverlayRenderer.shared
    private let hackEngine = HackEngine.shared
    
    // إحصائيات
    private var shotsAttempted = 0
    private var shotsSuccessful = 0
    private var consecutiveWins = 0
    private var gameCount = 0
    
    // تأخيرات بشرية طبيعية
    private let minDelay: TimeInterval = 0.3
    private let maxDelay: TimeInterval = 1.2
    
    func start() {
        guard !isPlaying else { return }
        isPlaying = true
        shotsAttempted = 0
        shotsSuccessful = 0
        
        print("[AutoPlay] 🤖 بدء اللعب التلقائي...")
        
        // إظهار الـ overlay
        DispatchQueue.main.async {
            self.overlay.showOverlay()
        }
        
        // بدء دورة اللعب
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            self?.playLoop()
        }
    }
    
    func stop() {
        isPlaying = false
        print("[AutoPlay] ⏹ إيقاف اللعب التلقائي")
        print("[AutoPlay] 📊 إحصائيات: \(shotsSuccessful)/\(shotsAttempted) تسديدة ناجحة")
    }
    
    // MARK: - حلقة اللعب الرئيسية
    private func playLoop() {
        while isPlaying {
            // 1. انتظار دوري
            waitForMyTurn()
            guard isPlaying else { break }
            
            // 2. قراءة حالة الطاولة من الذاكرة
            let balls = readTableState()
            guard !balls.isEmpty else {
                Thread.sleep(forTimeInterval: 0.5)
                continue
            }
            currentBalls = balls
            
            // 3. تدريب AI على توزيع الكرات (مرة واحدة فقط)
            neuralAI.learnInitialDistribution(balls: balls)
            
            // 4. العثور على الكرة البيضاء وكراتي
            guard let cueBall = balls.first(where: { $0.isCueBall }) else {
                Thread.sleep(forTimeInterval: 0.5)
                continue
            }
            
            let myBalls = balls.filter { neuralAI.classifyBall($0) == .myBall }
            let opponentBalls = balls.filter { neuralAI.classifyBall($0) == .opponentBall }
            
            print("[AutoPlay] 🎱 كراتي: \(myBalls.count), الخصم: \(opponentBalls.count)")
            
            // 5. حساب أفضل تسديدة باستخدام AI
            let (angle, power) = neuralAI.calculateBestShot(
                cueBall: cueBall,
                myBalls: myBalls,
                allBalls: balls
            )
            
            // 6. إظهار المسار على الشاشة
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.overlay.drawTrajectory(
                    from: cueBall.x, startY: cueBall.y,
                    angle: angle, power: power,
                    balls: balls
                )
                self.overlay.drawBallIndicators(balls: balls)
            }
            
            // 7. تأخير بشري طبيعي (يختلف كل مرة)
            let humanDelay = TimeInterval.random(in: minDelay...maxDelay)
            Thread.sleep(forTimeInterval: humanDelay)
            
            // 8. تنفيذ التسديدة
            executeShot(angle: angle, power: power)
            shotsAttempted += 1
            
            // 9. انتظار نتيجة التسديدة
            Thread.sleep(forTimeInterval: 2.0)
            
            // 10. التحقق من النتيجة
            let scored = checkIfScored()
            if scored {
                shotsSuccessful += 1
                consecutiveWins += 1
                print("[AutoPlay] ✅ هدف! (#\(shotsSuccessful)/\(shotsAttempted))")
                
                // تحقق من الفوز
                if consecutiveWins > 4 {
                    print("[AutoPlay] 🏆 فوز متوقع!")
                    // إذا كان الفوز مؤكداً، اخفض القوة قليلاً للعب طبيعي
                }
            } else {
                consecutiveWins = 0
                print("[AutoPlay] ❌ لم يسجل")
            }
            
            gameCount += 1
            
            // استراتيجية ذكية: اخسر أحياناً لتجنب الكشف
            if gameCount % 7 == 0 {
                print("[AutoPlay] 🎭 استراتيجية الإخفاء: خسارة متعمدة")
                executeBadShot()
                Thread.sleep(forTimeInterval: 1.0)
            }
        }
    }
    
    // MARK: - انتظار دوري
    private func waitForMyTurn() {
        var waitedSeconds = 0
        while isPlaying && !isItMyTurn() {
            Thread.sleep(forTimeInterval: 0.2)
            waitedSeconds += 1
            
            // إذا انتظرت طويلاً، قد تكون اللعبة انتهت
            if waitedSeconds > 30 {
                print("[AutoPlay] ⚠️ لم يأت دوري بعد 30 ثانية - إعادة محاولة")
                waitedSeconds = 0
            }
        }
        
        // تأخير إضافي قبل التصويب (لكي يبدو طبيعياً)
        let extraDelay = TimeInterval.random(in: 0.1...0.4)
        Thread.sleep(forTimeInterval: extraDelay)
    }
    
    private func isItMyTurn() -> Bool {
        // محاكاة قراءة حالة اللعبة
        // في التطبيق الحقيقي، نقرأ من الذاكرة
        return hackEngine.is8BallPoolRunning() && arc4random_uniform(10) < 8
    }
    
    // MARK: - قراءة حالة الطاولة
    private func readTableState() -> [BallData] {
        // محاكاة قراءة الذاكرة
        // في التطبيق الحقيقي، نقرأ مواقع الكرات من ذاكرة اللعبة
        
        var balls: [BallData] = []
        
        // الكرة البيضاء
        balls.append(BallData(
            id: 0,
            x: Float.random(in: 100...900),
            y: Float.random(in: 100...400),
            vx: 0, vy: 0,
            color: .white,
            isCueBall: true,
            isSolid: false,
            isStripe: false
        ))
        
        // كراتي (صلبة)
        for i in 1...7 {
            balls.append(BallData(
                id: i,
                x: Float.random(in: 200...800),
                y: Float.random(in: 150...350),
                vx: Float.random(in: -5...5),
                vy: Float.random(in: -5...5),
                color: .red,
                isCueBall: false,
                isSolid: true,
                isStripe: false,
                owner: .myBall
            ))
        }
        
        // كرات الخصم (مخططة)
        for i in 9...15 {
            balls.append(BallData(
                id: i,
                x: Float.random(in: 200...800),
                y: Float.random(in: 150...350),
                vx: Float.random(in: -5...5),
                vy: Float.random(in: -5...5),
                color: .blue,
                isCueBall: false,
                isSolid: false,
                isStripe: true,
                owner: .opponentBall
            ))
        }
        
        // الكرة 8 (سوداء)
        balls.append(BallData(
            id: 8,
            x: Float.random(in: 300...700),
            y: Float.random(in: 200...300),
            vx: 0, vy: 0,
            color: .black,
            isCueBall: false,
            isSolid: true,
            isStripe: false,
            owner: .uncertain
        ))
        
        return balls
    }
    
    // MARK: - تنفيذ التسديدة
    private func executeShot(angle: Float, power: Float) {
        // محاكاة تنفيذ التسديدة في اللعبة
        print("[AutoPlay] 🎯 تسديدة: زاوية \(String(format: "%.1f", angle))° | قوة \(String(format: "%.0f", power))%")
        
        // في التطبيق الحقيقي:
        // 1. نحرك مؤشر الزاوية
        // 2. نحدد القوة
        // 3. نضغط زر التسديد
        
        // محاكاة حركة طبيعية
        let moveTime = TimeInterval.random(in: 0.2...0.6)
        Thread.sleep(forTimeInterval: moveTime)
    }
    
    // تسديدة سيئة متعمدة للإخفاء
    private func executeBadShot() {
        let badAngle = Float.random(in: 0...360)
        let badPower = Float.random(in: 10...30) // قوة ضعيفة
        print("[AutoPlay] 🎭 تسديدة إخفاء: زاوية \(String(format: "%.1f", badAngle))° | قوة \(String(format: "%.0f", badPower))%")
        Thread.sleep(forTimeInterval: 0.5)
    }
    
    // MARK: - التحقق من النتيجة
    private func checkIfScored() -> Bool {
        // محاكاة التحقق من التسجيل
        // في التطبيق الحقيقي، نقرأ من الذاكرة إذا دخلت كرة
        return arc4random_uniform(10) < 6 // 60% فرصة للتسجيل
    }
    
    // MARK: - دوال عامة
    func getStats() -> (attempted: Int, successful: Int, winRate: Float) {
        let rate = shotsAttempted > 0 ? Float(shotsSuccessful) / Float(shotsAttempted) * 100 : 0
        return (shotsAttempted, shotsSuccessful, rate)
    }
    
    func isRunning() -> Bool {
        return isPlaying
    }
}