import UIKit
import MapKit
import SnapKit

// MARK: - Головне View для Екрану з Картою
class HomeView: UIView {

    // MARK: - UI Елементи
    let mapView: MKMapView = {
        let map = MKMapView()
        map.isZoomEnabled = true
        map.showsCompass = true
        map.showsScale = true
        map.isRotateEnabled = true
        map.isPitchEnabled = true
        return map
    }()
    
    let locateMeButton: UIButton = {
        let button = UIButton()
        let image = UIImage(systemName: "location.fill")?.withRenderingMode(.alwaysTemplate)
        button.setImage(image, for: .normal)
        button.tintColor = AppColors.accentBlue
        button.backgroundColor = AppColors.primaryText.withAlphaComponent(0.6)
        button.layer.cornerRadius = 28
        return button
    }()

    let profileButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "person.circle.fill"), for: .normal)
        button.tintColor = AppColors.destructiveRedButton
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        return button
    }()

    let menuButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "list.bullet"), for: .normal)
        button.tintColor = AppColors.destructiveRedButton
        button.imageView?.contentMode = .scaleAspectFit
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        return button
    }()

    let homeButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "house.fill"), for: .normal)
        button.tintColor = AppColors.destructiveRedButton
        button.imageView?.contentMode = .scaleAspectFit
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        return button
    }()

    let addButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        button.tintColor = AppColors.destructiveRedButton;        button.imageView?.contentMode = .scaleAspectFit
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        return button
    }()
    
    let filterButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "line.3.horizontal.decrease.circle.fill"), for: .normal)
        button.tintColor = AppColors.destructiveRedButton 
        button.imageView?.contentMode = .scaleAspectFit
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        return button
    }()
    
    let myEventsButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "calendar.circle.fill"), for: .normal)
        button.tintColor = AppColors.destructiveRedButton
        button.imageView?.contentMode = .scaleAspectFit
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        return button
    }()
    
    // MARK: - Приватні Властивості
    private let gradientLayer = CAGradientLayer()
    let redColorForPins: UIColor = AppColors.primaryDeepRed


    // MARK: - Ініціалізація
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradient()
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle UIView
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    // MARK: - Налаштування View
    
    private func setupGradient() {
        gradientLayer.colors = [
            AppColors.primaryDeepRed.cgColor,
            UIColor(red: 75/255, green: 0, blue: 130/255, alpha: 1).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)
    }

    // Налаштовує та розміщує дочірні view.
    private func setupViews() {
        addSubview(mapView)
        addSubview(profileButton)
        addSubview(menuButton)
        addSubview(homeButton)
        addSubview(filterButton)
        addSubview(addButton)
        addSubview(myEventsButton)
        addSubview(locateMeButton)

        mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let buttonSize = 56

        homeButton.snp.makeConstraints { make in
            make.bottom.equalTo(safeAreaLayoutGuide).inset(AppConstants.paddingXL)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(buttonSize)
        }

        menuButton.snp.makeConstraints { make in
            make.centerY.equalTo(homeButton)
            make.trailing.equalTo(homeButton.snp.leading).offset(-72)
            make.width.height.equalTo(buttonSize)
        }
        
        filterButton.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top).offset(AppConstants.paddingM)
            make.leading.equalToSuperview().inset(AppConstants.paddingL)
            make.width.height.equalTo(buttonSize)
        }
        
        addButton.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top).offset(AppConstants.paddingM)
            make.leading.equalTo(filterButton.snp.trailing).offset(14)
            make.width.height.equalTo(buttonSize)
        }

        profileButton.snp.remakeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top).offset(AppConstants.paddingM)
            make.trailing.equalToSuperview().inset(AppConstants.paddingL)
            make.width.height.equalTo(buttonSize)
        }
        
        myEventsButton.snp.makeConstraints { make in
            make.centerY.equalTo(homeButton)
            make.leading.equalTo(homeButton.snp.trailing).offset(72)
            make.width.height.equalTo(buttonSize)
        }

        locateMeButton.snp.makeConstraints { make in
            make.trailing.equalTo(safeAreaLayoutGuide).inset(AppConstants.paddingL)
            make.bottom.equalTo(homeButton.snp.top).offset(-AppConstants.paddingXL)
            make.width.height.equalTo(buttonSize)
        }
    }
    
}
