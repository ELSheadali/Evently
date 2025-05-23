import UIKit
import SnapKit

// MARK: - Delegate Protocol for Filters Menu
protocol FiltersMenuDelegate: AnyObject {
    func filtersMenuDidApply(filters: FilterState?)
}

// MARK: - View Controller for Filters Menu
class FiltersMenuViewController: UIViewController {

    // MARK: - UI Properties
    let menuView = FiltersMenuView()

    // MARK: - Data Properties
    private var currentFilterState: FilterState?
    weak var delegate: FiltersMenuDelegate?

    // MARK: - Computed Properties
    private var menuHeight: CGFloat {
        return view.bounds.height * 0.4
    }

    private var menuInitialTransform: CGAffineTransform {
        return CGAffineTransform(translationX: 0, y: -menuHeight)
    }

    // MARK: - Initialization
    init(initialFilters: FilterState?, delegate: FiltersMenuDelegate?) {
        self.currentFilterState = initialFilters
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.0) // Standard dimming
        setupMenuViewLayout()
        setupDismissGesture()
        menuView.transform = menuInitialTransform
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        menuView.configure(with: currentFilterState)
        animatePresentation()
    }

    // MARK: - Setup Methods
    private func setupMenuViewLayout() {
        view.addSubview(menuView)
        menuView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(menuHeight)
        }
    }

    private func setupDismissGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped(_:)))
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
    }

    // MARK: - Animation Methods
    private func animatePresentation() {
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut], animations: {
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.5) // Standard dimming
            self.menuView.transform = .identity
        })
    }

    private func animateDismissal() {
        if menuView.themesTableViewIsVisible {
            menuView.themesTableView.alpha = 0
            menuView.themesTableView.isHidden = true
            menuView.themesTableViewIsVisible = false
        }

        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseIn], animations: {
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.0) // Standard dimming
            self.menuView.transform = self.menuInitialTransform
        }, completion: { _ in
            self.dismiss(animated: false, completion: nil)
        })
    }
    
    // MARK: - Actions
    @objc private func backgroundTapped(_ gesture: UITapGestureRecognizer) {
        let locationInMenuView = gesture.location(in: menuView)
        if menuView.themesTableViewIsVisible && !menuView.themesTableView.frame.contains(locationInMenuView) {
             menuView.hideThemesList()
        } else if !menuView.themesTableViewIsVisible { // Тільки якщо список тем вже не видимий
            dismissMenuAndApplyFilters()
        }
    }

    // MARK: - Helper Methods
    private func dismissMenuAndApplyFilters() {
        let newFilterState = menuView.getCurrentFilterState()
        self.currentFilterState = newFilterState
        delegate?.filtersMenuDidApply(filters: newFilterState)
        animateDismissal()
    }
}

// MARK: - UIGestureRecognizerDelegate
extension FiltersMenuViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Дозволяємо жесту спрацювати тільки якщо тап був поза menuView
        if touch.view?.isDescendant(of: menuView) == true {
            return false
        }
        return true
    }
}
