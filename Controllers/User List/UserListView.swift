import UIKit
import SnapKit

// MARK: - View for User Profile/Settings Menu
class UserListView: UIView {

    // MARK: - UI Elements
    let accountSettingsLabel: UILabel = {
        let label = UILabel()
        label.text = "Налаштування Акаунту >"
        label.font = AppFonts.bold(size: 22) 
        label.textColor = AppColors.primaryText 
        label.isUserInteractionEnabled = true
        return label
    }()

    let eventHistoryLabel: UILabel = {
        let label = UILabel()
        label.text = "Історія Подій >"
        label.font = AppFonts.bold(size: 20) 
        label.textColor = AppColors.primaryText 
        label.isUserInteractionEnabled = true
        return label
    }()

    let logoutLabel: UILabel = {
        let label = UILabel()
        label.text = "Вийти"
        label.font = AppFonts.regular(size: 20) 
        label.textColor = AppColors.primaryText 
        label.isUserInteractionEnabled = true
        return label
    }()
    
    let deleteAccountLabel: UILabel = {
        let label = UILabel()
        label.text = "Видалити Акаунт"
        label.font = AppFonts.regular(size: 20) 
        label.textColor = AppColors.actionRed
        label.isUserInteractionEnabled = true
        return label
    }()

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        AppAppearance.applyPrimaryBackground(to: self) 
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup Layout
    private func setupLayout() {
        addSubview(accountSettingsLabel)
        addSubview(eventHistoryLabel)
        addSubview(logoutLabel)
        addSubview(deleteAccountLabel)

        accountSettingsLabel.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).offset(AppConstants.paddingXXL) 
            make.leading.equalToSuperview().inset(AppConstants.paddingXL) 
            make.trailing.equalToSuperview().inset(AppConstants.paddingXL) 
        }

        eventHistoryLabel.snp.makeConstraints { make in
            make.top.equalTo(accountSettingsLabel.snp.bottom).offset(AppConstants.paddingL + AppConstants.paddingXS) 
            make.leading.equalTo(accountSettingsLabel)
            make.trailing.equalTo(accountSettingsLabel)
        }

        // Position delete and logout labels from the bottom
        deleteAccountLabel.snp.makeConstraints { make in
            make.bottom.equalTo(safeAreaLayoutGuide).inset(AppConstants.paddingXL) 
            make.leading.equalToSuperview().inset(AppConstants.paddingXL) 
            make.trailing.equalToSuperview().inset(AppConstants.paddingXL) 
        }
        
        logoutLabel.snp.makeConstraints { make in
            make.bottom.equalTo(deleteAccountLabel.snp.top).offset(-(AppConstants.paddingL - AppConstants.paddingXS)) 
            make.leading.equalTo(deleteAccountLabel)
            make.trailing.equalTo(deleteAccountLabel)
        }
    }
}
