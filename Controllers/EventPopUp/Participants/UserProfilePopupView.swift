import UIKit
import SnapKit

// MARK: - View для відображення профілю користувача у спливаючому вікні
class UserProfilePopupView: UIView {

    // MARK: - UI Elements
    let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = true
        scroll.alwaysBounceVertical = true
        return scroll
    }()

    let contentView: UIView = {
        let view = UIView()
        return view
    }()

    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = AppConstants.profileImageMediumSize / 2 
        imageView.backgroundColor = AppColors.secondaryText.withAlphaComponent(0.5) 
        imageView.image = UIImage(systemName: "person.circle.fill")
        imageView.tintColor = AppColors.placeholderText 
        return imageView
    }()

    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.profileName 
        label.textColor = AppColors.primaryText 
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let organizerRatingTitleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.profileSectionHeader 
        label.textColor = AppColors.placeholderText 
        label.textAlignment = .center
        label.text = "Рейтинг організатора"
        return label
    }()

    let organizerRatingValueDisplayLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.profileRatingValue 
        label.textColor = AppColors.primaryText 
        label.textAlignment = .center
        label.text = "–"
        return label
    }()

    private let participantRatingTitleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.profileSectionHeader 
        label.textColor = AppColors.placeholderText 
        label.textAlignment = .center
        label.text = "Рейтинг учасника"
        return label
    }()

    let participantRatingValueDisplayLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.profileRatingValue 
        label.textColor = AppColors.primaryText 
        label.textAlignment = .center
        label.text = "–"
        return label
    }()

    private let ratingsStackView: UIStackView = {
        let organizerStack = UIStackView()
        organizerStack.axis = .vertical
        organizerStack.alignment = .center
        organizerStack.spacing = AppConstants.paddingXS / 2 

        let participantStack = UIStackView()
        participantStack.axis = .vertical
        participantStack.alignment = .center
        participantStack.spacing = AppConstants.paddingXS / 2 
        
        let mainStack = UIStackView(arrangedSubviews: [organizerStack, participantStack])
        mainStack.axis = .horizontal
        mainStack.distribution = .fillEqually
        mainStack.alignment = .top // Важливо для однакового вирівнювання заголовків
        mainStack.spacing = AppConstants.paddingS 
        return mainStack
    }()

    let bioSectionLabel: UILabel = UserProfilePopupView.createStyledSectionLabel(text: "Біографія:")
    let bioTextView: UITextView = UserProfilePopupView.createStyledBioTextView()
    let bioContainerView: UIView = UserProfilePopupView.createStyledContainerView(for: "bio")
    
    let dateOfBirthSectionLabel: UILabel = UserProfilePopupView.createStyledSectionLabel(text: "Дата народження:")
    let dateOfBirthValueLabel: UILabel = UILabel()
    let dateOfBirthContainerView: UIView = UserProfilePopupView.createStyledContainerView(for: "dob")

    let placeOfWorkSectionLabel: UILabel = UserProfilePopupView.createStyledSectionLabel(text: "Місце роботи:")
    let placeOfWorkValueLabel: UILabel = UILabel()
    let placeOfWorkContainerView: UIView = UserProfilePopupView.createStyledContainerView(for: "work")

    let interestsSectionLabel: UILabel = UserProfilePopupView.createStyledSectionLabel(text: "Інтереси:")
    let interestsValueLabel: UILabel = UILabel()
    let interestsContainerView: UIView = UserProfilePopupView.createStyledContainerView(for: "interests")
    
    let noDataLabel: UILabel = {
        let label = UILabel()
        label.isHidden = true // Початково приховано
        return label
    }()
    
    let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        AppAppearance.styleActivityIndicator(indicator) 
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // MARK: - Static Factory Methods for Styled Elements
    private static func createStyledSectionLabel(text: String) -> UILabel {
        let label = UILabel()
        label.font = AppFonts.profileSectionHeader 
        label.textColor = AppColors.placeholderText 
        label.text = text
        label.isHidden = true // Початково приховано
        return label
    }
    
    private static func createStyledContainerView(for fieldName: String? = nil) -> UIView {
        let view = UIView()
        AppAppearance.styleCardView(view, backgroundColor: AppColors.subtleBackground, cornerRadius: AppConstants.cornerRadiusM)
        view.isHidden = true // Початково приховано
        return view
    }
    
    private static func createStyledBioTextView() -> UITextView {
        let textView = UITextView()
        AppAppearance.styleTextView(textView,
                                    font: AppFonts.profileValue, 
                                    textColor: AppColors.primaryText, 
                                    backgroundColor: .clear, // Прозорий фон всередині контейнера
                                    cornerRadius: AppConstants.cornerRadiusM, 
                                    textContainerInset: UIEdgeInsets(top: AppConstants.paddingS, left: AppConstants.paddingM, bottom: AppConstants.paddingS, right: AppConstants.paddingM)) 
        textView.isEditable = false
        textView.isScrollEnabled = false // Розмір визначається контентом
        textView.isHidden = true // Початково приховано
        return textView
    }
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        AppAppearance.applyPrimaryBackground(to: self) 
        
        configureValueLabel(dateOfBirthValueLabel)
        configureValueLabel(placeOfWorkValueLabel)
        configureValueLabel(interestsValueLabel)
        AppAppearance.styleEmptyStateLabel(noDataLabel, text: "Інформація про цього користувача недоступна.") 
        
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration
    private func configureValueLabel(_ label: UILabel) {
        label.font = AppFonts.profileValue 
        label.textColor = AppColors.primaryText 
        label.numberOfLines = 0 // Дозволяємо кілька рядків
        label.isHidden = true // Початково приховано
    }

    func configure(with profile: UserProfile) {
        profileImageView.isHidden = false
        nameLabel.isHidden = false
        
        let firstName = profile.firstName ?? ""
        let lastName = profile.lastName ?? ""
        if firstName.isEmpty && lastName.isEmpty {
            nameLabel.text = profile.uid != nil ? "Користувач \(profile.uid!.prefix(8))..." : "Анонімний користувач"
        } else {
            nameLabel.text = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
        }

        profileImageView.image = UIImage(systemName: "person.circle.fill")?.withTintColor(AppColors.placeholderText, renderingMode: .alwaysOriginal) 
        if let photoURLString = profile.profilePhotoURL, let url = URL(string: photoURLString) {
            DispatchQueue.global(qos: .userInitiated).async {
                if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.profileImageView.image = image
                    }
                }
            }
        }

        var hasAnyRating = false
        if let avgOrgRating = profile.averageOrganizerRating, let orgCount = profile.organizerRatingsCount, orgCount > 0 {
            organizerRatingValueDisplayLabel.text = String(format: "%.1f", avgOrgRating)
            hasAnyRating = true
        } else {
            organizerRatingValueDisplayLabel.text = "–"
        }

        if let avgPartRating = profile.averageParticipantRating, let partCount = profile.participantRatingsCount, partCount > 0 {
            participantRatingValueDisplayLabel.text = String(format: "%.1f", avgPartRating)
            hasAnyRating = true
        } else {
            participantRatingValueDisplayLabel.text = "–"
        }
        
        ratingsStackView.isHidden = !hasAnyRating

        if let bio = profile.bio, !bio.isEmpty {
            bioTextView.text = bio
            bioSectionLabel.isHidden = false
            bioContainerView.isHidden = false
            bioTextView.isHidden = false
        } else {
            bioSectionLabel.isHidden = true
            bioContainerView.isHidden = true
            bioTextView.isHidden = true
        }
        
        if let dob = profile.dateOfBirth {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMMM yyyy"
            formatter.locale = Locale(identifier: "uk_UA")
            dateOfBirthValueLabel.text = formatter.string(from: dob) + " р."
            dateOfBirthSectionLabel.isHidden = false
            dateOfBirthContainerView.isHidden = false
            dateOfBirthValueLabel.isHidden = false
        } else {
            dateOfBirthSectionLabel.isHidden = true
            dateOfBirthContainerView.isHidden = true
            dateOfBirthValueLabel.isHidden = true
        }

        if let placeOfWork = profile.placeOfWork, !placeOfWork.isEmpty {
            placeOfWorkValueLabel.text = placeOfWork
            placeOfWorkSectionLabel.isHidden = false
            placeOfWorkContainerView.isHidden = false
            placeOfWorkValueLabel.isHidden = false
        } else {
            placeOfWorkSectionLabel.isHidden = true
            placeOfWorkContainerView.isHidden = true
            placeOfWorkValueLabel.isHidden = true
        }

        if let interests = profile.interests, !interests.isEmpty {
            interestsValueLabel.text = interests.joined(separator: ", ")
            interestsSectionLabel.isHidden = false
            interestsContainerView.isHidden = false
            interestsValueLabel.isHidden = false
        } else {
            interestsSectionLabel.isHidden = true
            interestsContainerView.isHidden = true
            interestsValueLabel.isHidden = true
        }
    }
        
    // MARK: - State Updates
    func showLoadingState(_ isLoading: Bool) {
        if isLoading {
            activityIndicator.startAnimating()
            scrollView.isHidden = true
            noDataLabel.isHidden = true // Приховуємо мітку "немає даних" під час завантаження
        } else {
            activityIndicator.stopAnimating()
            // scrollView та noDataLabel будуть показані/приховані в showNoDataAvailable або showData
        }
    }
    
    func showNoDataAvailable(message: String = "Інформація про цього користувача недоступна.") {
        scrollView.isHidden = true
        profileImageView.isHidden = true // Ховаємо також фото та ім'я, якщо немає даних
        nameLabel.isHidden = true
        ratingsStackView.isHidden = true // Ховаємо рейтинги
        
        noDataLabel.text = message
        noDataLabel.isHidden = false // Показуємо мітку про відсутність даних
        
        // Ховаємо всі інформаційні секції
        [bioSectionLabel, bioContainerView,
         dateOfBirthSectionLabel, dateOfBirthContainerView,
         placeOfWorkSectionLabel, placeOfWorkContainerView,
         interestsSectionLabel, interestsContainerView].forEach { $0.isHidden = true }
    }

    func showData() {
        scrollView.isHidden = false // Показуємо scrollView з даними
        noDataLabel.isHidden = true // Ховаємо мітку "немає даних"
    }
    
    // MARK: - Setup Layout
    private func setupViews() {
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(profileImageView)
        contentView.addSubview(nameLabel)
        
        contentView.addSubview(ratingsStackView)
        // Додаємо мітки до відповідних стеків всередині ratingsStackView
        guard ratingsStackView.arrangedSubviews.count == 2,
              let organizerStack = ratingsStackView.arrangedSubviews[0] as? UIStackView,
              let participantStack = ratingsStackView.arrangedSubviews[1] as? UIStackView else {
            // Ця помилка не має виникати, якщо ratingsStackView налаштовано правильно
            return
        }
        organizerStack.addArrangedSubview(organizerRatingTitleLabel)
        organizerStack.addArrangedSubview(organizerRatingValueDisplayLabel)
        participantStack.addArrangedSubview(participantRatingTitleLabel)
        participantStack.addArrangedSubview(participantRatingValueDisplayLabel)

        contentView.addSubview(bioSectionLabel)
        contentView.addSubview(bioContainerView)
        bioContainerView.addSubview(bioTextView)
        
        contentView.addSubview(dateOfBirthSectionLabel)
        contentView.addSubview(dateOfBirthContainerView)
        dateOfBirthContainerView.addSubview(dateOfBirthValueLabel)
        
        contentView.addSubview(placeOfWorkSectionLabel)
        contentView.addSubview(placeOfWorkContainerView)
        placeOfWorkContainerView.addSubview(placeOfWorkValueLabel)
        
        contentView.addSubview(interestsSectionLabel)
        contentView.addSubview(interestsContainerView)
        interestsContainerView.addSubview(interestsValueLabel)
        
        addSubview(noDataLabel) // Додаємо noDataLabel до головного view, а не contentView
        addSubview(activityIndicator) // Додаємо activityIndicator до головного view

        // --- Constraints ---
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview() // Важливо для вертикального скролу
        }
        
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        noDataLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(AppConstants.paddingXXL) 
        }

        profileImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(AppConstants.paddingXL + AppConstants.paddingXS) 
            make.centerX.equalToSuperview()
            make.width.height.equalTo(AppConstants.profileImageMediumSize) 
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(profileImageView.snp.bottom).offset(AppConstants.paddingL - AppConstants.paddingXS) 
            make.leading.trailing.equalToSuperview().inset(AppConstants.paddingXL) 
        }

        ratingsStackView.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(AppConstants.paddingL) 
            make.leading.trailing.equalToSuperview().inset(AppConstants.paddingXL) 
        }

        // Налаштування для інформаційних секцій
        let verticalSpacing = AppConstants.paddingL + AppConstants.paddingXS 
        let sectionTopSpacing = AppConstants.paddingM // Відступ між заголовком секції та її контейнером 
        let valueLabelPadding = UIEdgeInsets(top: AppConstants.paddingS, 
                                            left: AppConstants.paddingM, 
                                            bottom: AppConstants.paddingS, 
                                            right: AppConstants.paddingM) 

        // Bio Section
        bioSectionLabel.snp.makeConstraints { make in
            make.top.equalTo(ratingsStackView.snp.bottom).offset(verticalSpacing)
            make.leading.equalToSuperview().offset(AppConstants.paddingXL) 
            make.trailing.equalToSuperview().offset(-AppConstants.paddingXL) 
        }
        bioContainerView.snp.makeConstraints { make in
            make.top.equalTo(bioSectionLabel.snp.bottom).offset(sectionTopSpacing - AppConstants.paddingXS) 
            make.leading.trailing.equalTo(bioSectionLabel)
        }
        bioTextView.snp.makeConstraints { make in
            make.edges.equalToSuperview() // UITextView займає весь контейнер
        }
        
        // Date of Birth Section
        dateOfBirthSectionLabel.snp.makeConstraints { make in
            make.top.equalTo(bioContainerView.snp.bottom).offset(verticalSpacing)
            make.leading.trailing.equalTo(bioSectionLabel)
        }
        dateOfBirthContainerView.snp.makeConstraints { make in
            make.top.equalTo(dateOfBirthSectionLabel.snp.bottom).offset(sectionTopSpacing)
            make.leading.trailing.equalTo(bioSectionLabel)
        }
        dateOfBirthValueLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(valueLabelPadding)
        }

        // Place of Work Section
        placeOfWorkSectionLabel.snp.makeConstraints { make in
            make.top.equalTo(dateOfBirthContainerView.snp.bottom).offset(verticalSpacing)
            make.leading.trailing.equalTo(bioSectionLabel)
        }
        placeOfWorkContainerView.snp.makeConstraints { make in
            make.top.equalTo(placeOfWorkSectionLabel.snp.bottom).offset(sectionTopSpacing)
            make.leading.trailing.equalTo(bioSectionLabel)
        }
        placeOfWorkValueLabel.snp.makeConstraints { make in
             make.edges.equalToSuperview().inset(valueLabelPadding)
        }
        
        // Interests Section
        interestsSectionLabel.snp.makeConstraints { make in
            make.top.equalTo(placeOfWorkContainerView.snp.bottom).offset(verticalSpacing)
            make.leading.trailing.equalTo(bioSectionLabel)
        }
        interestsContainerView.snp.makeConstraints { make in
            make.top.equalTo(interestsSectionLabel.snp.bottom).offset(sectionTopSpacing)
            make.leading.trailing.equalTo(bioSectionLabel)
            // Важливо: прив'язка до низу contentView для правильного розміру scrollView
            make.bottom.equalToSuperview().offset(-(AppConstants.paddingXXL)) 
        }
        interestsValueLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(valueLabelPadding)
        }
    }
}
