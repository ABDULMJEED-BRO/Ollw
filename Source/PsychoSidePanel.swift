import UIKit

class PsychoSidePanel: UIViewController {
    
    // MARK: - العناصر
    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 0.92)
        v.layer.cornerRadius = 20
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        v.layer.borderWidth = 1.5
        v.layer.borderColor = UIColor(red: 0.9, green: 0.2, blue: 0.3, alpha: 0.8).cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let logoLabel: UILabel = {
        let l = UILabel()
        l.text = "PSYCHO"
        l.font = .systemFont(ofSize: 28, weight: .bold)
        l.textColor = UIColor(red: 0.9, green: 0.2, blue: 0.3, alpha: 1)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "HACK v5.0"
        l.font = .systemFont(ofSize: 12, weight: .light)
        l.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.8, alpha: 0.6)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    // مؤشرات الحماية (تعمل فوراً)
    private let shieldStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 4
        s.distribution = .fillEqually
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()
    
    // الأزرار
    private let autoAimBtn = PsychoButton(title: "🎯 AUTO AIM")
    private let autoPlayBtn = PsychoButton(title: "🤖 AUTO PLAY")
    private let guidelineBtn = PsychoButton(title: "📐 LINE GUIDE", defaultOn: true)
    private let powerBtn = PsychoButton(title: "💪 PERFECT POWER", defaultOn: true)
    
    // حالة الأزرار
    private var isAutoAimOn = false
    private var isAutoPlayOn = false
    private var isGuidelineOn = true
    private var isPowerOn = true
    
    // مؤشر الاتصال
    private let statusDot: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.2, green: 0.9, blue: 0.3, alpha: 1)
        v.layer.cornerRadius = 5
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let statusLabel: UILabel = {
        let l = UILabel()
        l.text = "جاهز"
        l.font = .systemFont(ofSize: 10)
        l.textColor = UIColor(red: 0.5, green: 0.8, blue: 0.5, alpha: 0.8)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupUI()
        setupShieldLabels()
        activateProtection()
        startMonitoring()
    }
    
    // MARK: - إعداد الواجهة
    private func setupUI() {
        view.addSubview(containerView)
        containerView.addSubview(logoLabel)
        containerView.addSubview(subtitleLabel)
        containerView.addSubview(shieldStack)
        containerView.addSubview(autoAimBtn)
        containerView.addSubview(autoPlayBtn)
        containerView.addSubview(guidelineBtn)
        containerView.addSubview(powerBtn)
        containerView.addSubview(statusDot)
        containerView.addSubview(statusLabel)
        
        // ربط الأزرار
        autoAimBtn.addTarget(self, action: #selector(tapAutoAim), for: .touchUpInside)
        autoPlayBtn.addTarget(self, action: #selector(tapAutoPlay), for: .touchUpInside)
        guidelineBtn.addTarget(self, action: #selector(tapGuideline), for: .touchUpInside)
        powerBtn.addTarget(self, action: #selector(tapPower), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            // الحاوية
            containerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 70),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -70),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 8),
            containerView.widthAnchor.constraint(equalToConstant: 190),
            
            // الشعار
            logoLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            logoLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: logoLabel.bottomAnchor, constant: 2),
            subtitleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            // أزرار التحكم
            autoAimBtn.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            autoAimBtn.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            autoAimBtn.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            autoAimBtn.heightAnchor.constraint(equalToConstant: 42),
            
            autoPlayBtn.topAnchor.constraint(equalTo: autoAimBtn.bottomAnchor, constant: 10),
            autoPlayBtn.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            autoPlayBtn.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            autoPlayBtn.heightAnchor.constraint(equalToConstant: 42),
            
            guidelineBtn.topAnchor.constraint(equalTo: autoPlayBtn.bottomAnchor, constant: 10),
            guidelineBtn.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            guidelineBtn.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            guidelineBtn.heightAnchor.constraint(equalToConstant: 42),
            
            powerBtn.topAnchor.constraint(equalTo: guidelineBtn.bottomAnchor, constant: 10),
            powerBtn.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            powerBtn.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            powerBtn.heightAnchor.constraint(equalToConstant: 42),
            
            // مؤشرات الحماية
            shieldStack.topAnchor.constraint(equalTo: powerBtn.bottomAnchor, constant: 18),
            shieldStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            shieldStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            shieldStack.heightAnchor.constraint(equalToConstant: 90),
            
            // مؤشر الاتصال
            statusDot.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -18),
            statusDot.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 18),
            statusDot.widthAnchor.constraint(equalToConstant: 10),
            statusDot.heightAnchor.constraint(equalToConstant: 10),
            
            statusLabel.centerYAnchor.constraint(equalTo: statusDot.centerYAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: statusDot.trailingAnchor, constant: 6)
        ])
    }
    
    private func setupShieldLabels() {
        let shields = ["🛡️ ANTI-BAN: ACTIVE", "🔒 ANTI-CHEAT: ACTIVE", "🧠 MEMORY SHIELD: ACTIVE"]
        for text in shields {
            let label = UILabel()
            label.text = text
            label.font = .systemFont(ofSize: 11, weight: .bold)
            label.textColor = UIColor(red: 0.2, green: 0.9, blue: 0.3, alpha: 1)
            label.textAlignment = .center
            label.backgroundColor = UIColor(red: 0.1, green: 0.3, blue: 0.1, alpha: 0.4)
            label.layer.cornerRadius = 8
            label.layer.masksToBounds = true
            shieldStack.addArrangedSubview(label)
        }
    }
    
    // MARK: - تفعيل الحماية
    private func activateProtection() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            self.hackEngine.activateAntiBan()
            self.hackEngine.activateAntiCheatBypass()
            self.hackEngine.activateMemoryShield()
            self.hackEngine.applyMemoryPatches()
        }
    }
    
    private var hackEngine: HackEngine { HackEngine.shared }
    
    // MARK: - مراقبة اللعبة
    private var gameTimer: Timer?
    
    private func startMonitoring() {
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.hackEngine.is8BallPoolRunning() {
                self.statusDot.backgroundColor = UIColor(red: 0.2, green: 0.9, blue: 0.3, alpha: 1)
                self.statusLabel.text = "🟢 متصل بـ 8 Ball Pool"
                
                if self.isAutoPlayOn {
                    self.hackEngine.executeAutoPlay()
                }
            } else {
                self.statusDot.backgroundColor = UIColor(red: 0.9, green: 0.8, blue: 0.2, alpha: 1)
                self.statusLabel.text = "⏳ انتظار 8 Ball Pool..."
            }
        }
    }
    
    // MARK: - أحداث الأزرار
    @objc private func tapAutoAim() {
        isAutoAimOn.toggle()
        autoAimBtn.setOn(isAutoAimOn)
        hackEngine.setAutoAim(isAutoAimOn)
    }
    
    @objc private func tapAutoPlay() {
        isAutoPlayOn.toggle()
        autoPlayBtn.setOn(isAutoPlayOn)
        
        if isAutoPlayOn {
            isAutoAimOn = true
            autoAimBtn.setOn(true)
            hackEngine.setAutoAim(true)
            hackEngine.startAutoPlay()
            autoPlayBtn.setTitle("🤖 AUTO PLAY: ON ✓", for: .normal)
        } else {
            hackEngine.stopAutoPlay()
            autoPlayBtn.setTitle("🤖 AUTO PLAY", for: .normal)
        }
    }
    
    @objc private func tapGuideline() {
        isGuidelineOn.toggle()
        guidelineBtn.setOn(isGuidelineOn)
        hackEngine.setForceGuideline(isGuidelineOn)
    }
    
    @objc private func tapPower() {
        isPowerOn.toggle()
        powerBtn.setOn(isPowerOn)
        hackEngine.setPerfectPower(isPowerOn)
    }
}

// MARK: - زر مخصص
class PsychoButton: UIButton {
    
    init(title: String, defaultOn: Bool = false) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 14
        layer.borderWidth = 1.5
        
        if defaultOn {
            setOn(true)
        } else {
            setOn(false)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setOn(_ isOn: Bool) {
        if isOn {
            backgroundColor = UIColor(red: 0.1, green: 0.4, blue: 0.2, alpha: 0.5)
            layer.borderColor = UIColor(red: 0.2, green: 0.9, blue: 0.3, alpha: 0.7).cgColor
        } else {
            backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.3, alpha: 1)
            layer.borderColor = UIColor(red: 0.3, green: 0.6, blue: 1, alpha: 0.7).cgColor
        }
    }
}