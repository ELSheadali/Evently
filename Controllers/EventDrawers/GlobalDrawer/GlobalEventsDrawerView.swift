import UIKit
import SnapKit

// MARK: - View for Global Events Drawer
class GlobalEventsDrawerView: UIView {

    // MARK: - UI Elements
    let container: UIView = {
        let view = UIView()
        AppAppearance.applyPanelBackground(to: view) 
        view.layer.cornerRadius = AppConstants.cornerRadiusL 
        view.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner] 
        view.clipsToBounds = true
        return view
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Уcі події"
        label.font = AppFonts.drawerTitle 
        label.textAlignment = .center
        label.textColor = AppColors.primaryText 
        return label
    }()
    
    let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = AppColors.placeholderText 
        return button
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

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup Methods
    private func setupView() {
        backgroundColor = .clear
        
        addSubview(container)
        container.addSubview(titleLabel)
        container.addSubview(closeButton)
        container.addSubview(tableView)
    }

    private func setupLayout() {
        container.snp.makeConstraints { make in
            make.top.bottom.leading.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.85)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(container.safeAreaLayoutGuide).offset(AppConstants.paddingXL) 
            make.trailing.equalTo(container).offset(-(AppConstants.paddingXXL + AppConstants.paddingS))
            make.centerX.equalTo(container)
        }
        
        closeButton.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel.snp.centerY)
            make.trailing.equalTo(container).inset(AppConstants.paddingL) 
            make.width.height.equalTo(AppConstants.paddingXXL)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(AppConstants.paddingXL) 
            make.leading.trailing.equalTo(container)
            make.bottom.equalTo(container.safeAreaLayoutGuide)
        }
    }
}
