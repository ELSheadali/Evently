import UIKit
import SnapKit

// MARK: - Комірка для відображення учасника
class ParticipantTableViewCell: UITableViewCell {
    
    // MARK: - UI Elements
    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = AppConstants.profileImageSmallSize / 2
        imageView.backgroundColor = AppColors.secondaryText.withAlphaComponent(0.3)
        imageView.image = UIImage(systemName: "person.circle.fill")?.withTintColor(AppColors.placeholderText, renderingMode: .alwaysOriginal)
        return imageView
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = AppColors.primaryText
        label.font = AppFonts.cellTitle
        label.numberOfLines = 1
        return label
    }()

    private let cellContainerView: UIView = {
        let view = UIView()
        AppAppearance.styleCardView(view, backgroundColor: AppColors.subtleBackground, cornerRadius: AppConstants.cornerRadiusM)
        return view
    }()

    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        backgroundColor = .clear 
        contentView.backgroundColor = .clear 
        
        contentView.addSubview(cellContainerView)
        cellContainerView.addSubview(profileImageView)
        cellContainerView.addSubview(nameLabel)
        
        cellContainerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(AppConstants.paddingXS) 
            make.bottom.equalToSuperview().offset(-AppConstants.paddingXS) 
            make.leading.equalToSuperview().offset(AppConstants.paddingM) 
            make.trailing.equalToSuperview().offset(-AppConstants.paddingM) 
        }
        
        profileImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppConstants.paddingS) 
            make.centerY.equalToSuperview()
            make.width.height.equalTo(AppConstants.profileImageSmallSize) 
        }
        
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(profileImageView.snp.trailing).offset(AppConstants.paddingM) 
            make.trailing.equalToSuperview().offset(-AppConstants.paddingS) 
            make.centerY.equalToSuperview()
        }
    }

    // MARK: - Configuration
    func configure(with profile: UserProfile) {
        let firstName = profile.firstName ?? ""
        let lastName = profile.lastName ?? ""
        
        if firstName.isEmpty && lastName.isEmpty {
            if let uidSubstring = profile.uid?.prefix(8) {
                 nameLabel.text = "Користувач \(uidSubstring)..."
            } else {
                 nameLabel.text = "Невідомий користувач"
            }
        } else {
            nameLabel.text = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        profileImageView.image = UIImage(systemName: "person.circle.fill")?.withTintColor(AppColors.placeholderText, renderingMode: .alwaysOriginal) 
        
        if let photoURLString = profile.profilePhotoURL, let url = URL(string: photoURLString) {
            DispatchQueue.global(qos: .userInitiated).async {
                guard let data = try? Data(contentsOf: url), let image = UIImage(data: data) else {
                    DispatchQueue.main.async {
                         self.profileImageView.image = UIImage(systemName: "person.circle.fill")?.withTintColor(AppColors.placeholderText, renderingMode: .alwaysOriginal) 
                    }
                    return
                }
                DispatchQueue.main.async {
                    let currentConfiguredName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
                    let currentLabelText = self.nameLabel.text ?? ""
                    
                    let isSameUserByName = !firstName.isEmpty && !lastName.isEmpty && currentLabelText == currentConfiguredName
                    let isSameUserByUID = firstName.isEmpty && lastName.isEmpty && currentLabelText.contains(profile.uid?.prefix(8) ?? "###NON_EXISTING_UID###")
                                        
                    if isSameUserByName || isSameUserByUID {
                        self.profileImageView.image = image
                    }
                }
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        profileImageView.image = UIImage(systemName: "person.circle.fill")?.withTintColor(AppColors.placeholderText, renderingMode: .alwaysOriginal) 
    }
}
