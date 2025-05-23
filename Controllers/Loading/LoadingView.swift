import UIKit
import SnapKit

// MARK: - View for Loading Screen
class LoadingView: UIView {

    // MARK: - UI Elements
    private let gradientLayer = CAGradientLayer()

    let spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = AppColors.activityIndicator 
        spinner.startAnimating()
        return spinner
    }()

    let loadingLabel: UILabel = {
        let label = UILabel()
        label.text = "Loading..."
        label.font = AppFonts.bold(size: 26) 
        label.textColor = AppColors.primaryText 
        label.textAlignment = .center
        return label
    }()

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradient()
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup Methods
    private func setupGradient() {
        gradientLayer.colors = [
            AppColors.primaryDeepRed.cgColor,
            UIColor(red: 75/255, green: 0, blue: 130/255, alpha: 1).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)
    }

    private func setupViews() {
        addSubview(spinner)
        addSubview(loadingLabel)

        spinner.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        loadingLabel.snp.makeConstraints { make in
            make.top.equalTo(spinner.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
        }
    }
    
    // MARK: - Lifecycle Methods
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}
