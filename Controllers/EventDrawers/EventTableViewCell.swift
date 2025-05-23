import UIKit
import SnapKit
import FirebaseAuth
import Kingfisher

// MARK: - Enum for Cell Configuration Type
enum EventCellType {
    case created
    case joined
    case discover
    case history
}

// MARK: - Delegate for Cell Actions
protocol EventTableViewCellDelegate: AnyObject {
    func didTapEditButton(on cell: EventTableViewCell)
    func didTapUnjoinButton(on cell: EventTableViewCell)
    func didTapJoinButton(on cell: EventTableViewCell)
}

// MARK: - Table View Cell for Displaying Event Information
class EventTableViewCell: UITableViewCell {

    static let identifier = "EventTableViewCell"
    weak var delegate: EventTableViewCellDelegate?

    // MARK: - UI Elements
    private let cardContainerView: UIView = {
        let view = UIView()
        AppAppearance.styleCardView(view, backgroundColor: AppColors.darkSubtleBackground, cornerRadius: AppConstants.cornerRadiusM)
        return view
    }()

    private let eventImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = AppConstants.cornerRadiusS
        iv.backgroundColor = AppColors.secondaryText.withAlphaComponent(0.2)
        iv.image = UIImage(systemName: "photo.on.rectangle.angled")
        iv.tintColor = AppColors.placeholderText.withAlphaComponent(0.5)
        return iv
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.bold(size: 15)
        label.textColor = AppColors.primaryText
        label.numberOfLines = 1
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.cellSubtitle
        label.textColor = AppColors.placeholderText
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.cellCaption
        label.textColor = AppColors.tertiaryText
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.numberOfLines = 1
        return label
    }()

    private let peopleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.cellCaption
        label.textColor = AppColors.tertiaryText
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.textAlignment = .right
        label.numberOfLines = 1
        return label
    }()
    
    private lazy var editButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "pencil.circle.fill"), for: .normal)
        btn.tintColor = AppColors.primaryText
        btn.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
        return btn
    }()
    
    private lazy var unjoinButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "person.crop.circle.badge.xmark.fill"), for: .normal)
        btn.tintColor = AppColors.actionRed
        btn.addTarget(self, action: #selector(unjoinButtonTapped), for: .touchUpInside)
        return btn
    }()
    
    private lazy var joinButton: UIButton = {
        let btn = UIButton()
        AppAppearance.styleButton(btn,
                                  title: "Join",
                                  font: AppFonts.smallButtonTitle,
                                  backgroundColor: AppColors.actionGreen.withAlphaComponent(0.8),
                                  cornerRadius: (AppConstants.textFieldHeight - AppConstants.paddingM) / 2,
                                  image: UIImage(systemName: "person.fill.badge.plus"),
                                  imagePadding: AppConstants.paddingXS)
        if var config = btn.configuration {
            config.contentInsets = NSDirectionalEdgeInsets(top: AppConstants.paddingXS, leading: AppConstants.paddingS, bottom: AppConstants.paddingXS, trailing: AppConstants.paddingS)
            btn.configuration = config
        }
        btn.addTarget(self, action: #selector(joinButtonTapped), for: .touchUpInside)
        return btn
    }()
    
    private let infoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.spacing = AppConstants.paddingXS
        return stackView
    }()

    private lazy var textStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [nameLabel, descriptionLabel, infoStackView])
        stack.axis = .vertical
        stack.spacing = AppConstants.paddingXS + 1
        return stack
    }()

    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let spacerView = UIView()
        spacerView.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
        
        infoStackView.addArrangedSubview(dateLabel)
        infoStackView.addArrangedSubview(spacerView)
        infoStackView.addArrangedSubview(peopleLabel)
        
        setupView()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupView() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.addSubview(cardContainerView)
        
        [eventImageView, textStackView, editButton, unjoinButton, joinButton].forEach { cardContainerView.addSubview($0) }
    }

    private func setupLayout() {
        cardContainerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(AppConstants.paddingXS + 1)
            make.bottom.equalToSuperview().inset(AppConstants.paddingXS + 1)
            make.leading.equalToSuperview().offset(AppConstants.paddingS)
            make.trailing.equalToSuperview().inset(AppConstants.paddingS)
        }

        eventImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppConstants.paddingS)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(65)
        }
        
        let actionButtonSize: CGFloat = AppConstants.paddingXL + AppConstants.paddingS
        [editButton, unjoinButton].forEach { button in
            button.snp.makeConstraints { make in
                make.trailing.equalToSuperview().inset(AppConstants.paddingS)
                make.centerY.equalToSuperview()
                make.width.height.equalTo(actionButtonSize)
            }
        }
        
        joinButton.snp.makeConstraints {make in
            make.trailing.equalToSuperview().inset(AppConstants.paddingS)
            make.centerY.equalToSuperview()
        }
    }

    // MARK: - Configuration
    func configure(with event: Event, cellType: EventCellType) {
        nameLabel.text = event.name
        descriptionLabel.text = event.description
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yy, HH:mm"
        dateFormatter.locale = Locale(identifier: "uk_UA")
        dateLabel.text = dateFormatter.string(from: event.date)
        
        let currentParticipants = event.participantUIDs?.count ?? 0
        peopleLabel.text = "👥 \(currentParticipants)/\(event.maxPeople)"
        
        // --- Зміни тут: завжди приховуємо кнопки ---
        editButton.isHidden = true
        unjoinButton.isHidden = true
        joinButton.isHidden = true

        textStackView.snp.remakeConstraints { make in
            make.leading.equalTo(eventImageView.snp.trailing).offset(AppConstants.paddingS)
            make.centerY.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview().offset(AppConstants.paddingS - AppConstants.paddingXS)
            make.bottom.lessThanOrEqualToSuperview().inset(AppConstants.paddingS - AppConstants.paddingXS)
            // Завжди прив'язуємо до правого краю, оскільки кнопок немає
            make.trailing.equalToSuperview().inset(AppConstants.paddingS)
        }
        // --- Кінець змін ---

        let placeholderImage = UIImage(systemName: "photo.on.rectangle.angled")?.withTintColor(AppColors.placeholderText.withAlphaComponent(0.5), renderingMode: .alwaysOriginal)
        eventImageView.backgroundColor = AppColors.secondaryText.withAlphaComponent(0.2)
        
        if let photoURLString = event.photoURL, !photoURLString.isEmpty, let url = URL(string: photoURLString) {
            eventImageView.kf.indicatorType = .activity
            (eventImageView.kf.indicator?.view as? UIActivityIndicatorView)?.color = AppColors.primaryText
            
            eventImageView.kf.setImage(
                with: url,
                placeholder: placeholderImage,
                options: [
                    .transition(.fade(AppConstants.defaultAnimationDuration)),
                    .processor(DownsamplingImageProcessor(size: CGSize(width: 130, height: 130))),
                    .scaleFactor(UIScreen.main.scale),
                    .cacheOriginalImage
                ],
                completionHandler: { result in
                    switch result {
                    case .success(_):
                        self.eventImageView.backgroundColor = .clear
                        self.eventImageView.tintColor = .clear
                    case .failure(_):
                        self.eventImageView.image = placeholderImage
                        self.eventImageView.backgroundColor = AppColors.secondaryText.withAlphaComponent(0.2)
                        self.eventImageView.tintColor = AppColors.placeholderText.withAlphaComponent(0.5)
                    }
                }
            )
        } else {
            eventImageView.kf.cancelDownloadTask()
            eventImageView.image = placeholderImage
            eventImageView.tintColor = AppColors.placeholderText.withAlphaComponent(0.5)
        }
    }
    
    // MARK: - Actions
    @objc private func editButtonTapped() { delegate?.didTapEditButton(on: self) }
    @objc private func unjoinButtonTapped() { delegate?.didTapUnjoinButton(on: self) }
    @objc private func joinButtonTapped() { delegate?.didTapJoinButton(on: self) }

    // MARK: - Prepare for Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        eventImageView.kf.cancelDownloadTask()
        eventImageView.image = UIImage(systemName: "photo.on.rectangle.angled")?.withTintColor(AppColors.placeholderText.withAlphaComponent(0.5), renderingMode: .alwaysOriginal)
        eventImageView.backgroundColor = AppColors.secondaryText.withAlphaComponent(0.2)
        eventImageView.tintColor = AppColors.placeholderText.withAlphaComponent(0.5)
        
        [nameLabel, descriptionLabel, dateLabel, peopleLabel].forEach { $0.text = nil }
        
        editButton.isHidden = true
        unjoinButton.isHidden = true
        joinButton.isHidden = true
        
        delegate = nil
    }
}
