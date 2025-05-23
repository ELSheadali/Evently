import UIKit
import SnapKit

// MARK: - Table View Cell for Rating a User
class RatingTableViewCell: UITableViewCell {
    static let identifier = "RatingTableViewCell"

    // MARK: - UI Elements
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = AppConstants.profileImageSmallSize / 2 
        imageView.backgroundColor = AppColors.secondaryText.withAlphaComponent(0.3) 
        imageView.image = UIImage(systemName: "person.circle.fill")
        imageView.tintColor = AppColors.placeholderText 
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.cellTitle 
        label.textColor = AppColors.primaryText 
        label.numberOfLines = 1
        return label
    }()

    private let starsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = AppConstants.paddingXS 
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    // MARK: - Properties
    private var starButtons: [UIButton] = []
    private var currentUserID: String?
    private var currentRatingValue: Int = 0
    var onRatingChanged: ((_ userID: String, _ newRating: Int) -> Void)?

    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupStarButtons()
        backgroundColor = .clear
        selectionStyle = .none
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        contentView.addSubview(profileImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(starsStackView)

        profileImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppConstants.paddingM) 
            make.centerY.equalToSuperview()
            make.width.height.equalTo(AppConstants.profileImageSmallSize) 
        }

        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(profileImageView.snp.trailing).offset(AppConstants.paddingM) 
            make.centerY.equalTo(profileImageView)
            make.trailing.lessThanOrEqualTo(starsStackView.snp.leading).offset(-AppConstants.paddingS) 
        }
        
        starsStackView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(AppConstants.paddingM) 
            make.centerY.equalToSuperview()
            let starVisualSize = AppConstants.profileImageSmallSize * 0.7
            make.width.equalTo(starVisualSize * 5 + AppConstants.paddingXS * 4)
            make.height.equalTo(starVisualSize)
        }
    }

    private func setupStarButtons() {
        starsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        starButtons.removeAll()

        for i in 0..<5 {
            let button = UIButton(type: .system)
            button.tag = i + 1
            button.setImage(UIImage(systemName: "star"), for: .normal)
            button.setImage(UIImage(systemName: "star.fill"), for: .selected)
            starButtons.append(button)
            starsStackView.addArrangedSubview(button)
            button.addTarget(self, action: #selector(starButtonTapped(_:)), for: .touchUpInside)
        }
    }

    // MARK: - Actions
    @objc private func starButtonTapped(_ sender: UIButton) {
        let newRating = sender.tag
        if newRating == currentRatingValue {
             currentRatingValue = 0
        } else {
            currentRatingValue = newRating
        }
        updateStarAppearance()
        if let uid = currentUserID {
            onRatingChanged?(uid, currentRatingValue)
        }
    }

    // MARK: - UI Update
    private func updateStarAppearance() {
        for (index, button) in starButtons.enumerated() {
            button.isSelected = (index < currentRatingValue)
            button.tintColor = button.isSelected ? AppColors.accentYellow : AppColors.secondaryText 
        }
    }
    
    // MARK: - Configuration
    func configure(with user: UserProfile, currentRating: Int?) {
        self.currentUserID = user.uid
        let firstName = user.firstName ?? "Користувач"
        let lastName = user.lastName?.isEmpty ?? true ? (user.uid != nil ? String(user.uid!.prefix(6)) + "..." : "") : user.lastName!
        nameLabel.text = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)

        profileImageView.image = UIImage(systemName: "person.circle.fill")?.withTintColor(AppColors.placeholderText, renderingMode: .alwaysOriginal) 
        if let photoURLString = user.profilePhotoURL, let url = URL(string: photoURLString) {
            DispatchQueue.global(qos: .userInitiated).async {
                if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        if self.currentUserID == user.uid {
                            self.profileImageView.image = image
                        }
                    }
                }
            }
        }
        
        self.currentRatingValue = currentRating ?? 0
        updateStarAppearance()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        profileImageView.image = UIImage(systemName: "person.circle.fill")?.withTintColor(AppColors.placeholderText, renderingMode: .alwaysOriginal) 
        nameLabel.text = nil
        currentRatingValue = 0
        currentUserID = nil
        onRatingChanged = nil
        updateStarAppearance()
    }
}
