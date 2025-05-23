import UIKit
import SnapKit

// MARK: - View for Events Drawer (My Events)
class EventsDrawerView: UIView {

    // MARK: - UI Elements
    let container: UIView = {
        let view = UIView()
        AppAppearance.applyPanelBackground(to: view) 
        view.layer.cornerRadius = AppConstants.cornerRadiusL 
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.clipsToBounds = true
        return view
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Мої події"
        label.font = AppFonts.drawerTitle 
        label.textAlignment = .center
        label.textColor = AppColors.primaryText 
        return label
    }()
    
    let segmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Приєднані", "Створені"])
        sc.selectedSegmentIndex = 1
        
        sc.backgroundColor = AppColors.primaryText.withAlphaComponent(0.1) 
        sc.selectedSegmentTintColor = AppColors.primaryDeepRed 
        
        let titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: AppColors.primaryText, 
            NSAttributedString.Key.font: AppFonts.medium(size: 13) 
        ]
        sc.setTitleTextAttributes(titleTextAttributes, for: .normal)
        
        let selectedTextAttributes = [
            NSAttributedString.Key.foregroundColor: AppColors.primaryText, 
            NSAttributedString.Key.font: AppFonts.semibold(size: 13) 
        ]
        sc.setTitleTextAttributes(selectedTextAttributes, for: .selected)
        
        return sc
    }()
    
    let tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.register(EventTableViewCell.self, forCellReuseIdentifier: EventTableViewCell.identifier)
        return tv
    }()

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupLayout()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Setup Methods
    private func setupView() {
        backgroundColor = .clear
        
        addSubview(container)
        [titleLabel, segmentedControl, tableView].forEach { container.addSubview($0) }
    }

    private func setupLayout() {
        container.snp.makeConstraints { make in
            make.top.bottom.trailing.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.85) 
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(container.safeAreaLayoutGuide).offset(AppConstants.paddingXL) 
            make.centerX.equalTo(container)
        }
        
        segmentedControl.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(AppConstants.paddingXL) 
            make.leading.trailing.equalTo(container).inset(AppConstants.paddingL) 
            make.height.equalTo(AppConstants.textFieldHeight - AppConstants.paddingS) 
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(segmentedControl.snp.bottom).offset(AppConstants.paddingL) 
            make.leading.trailing.equalTo(container)
            make.bottom.equalTo(container.safeAreaLayoutGuide)
        }
    }
}
