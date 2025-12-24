//
//  PrivacyPolicyController.swift
//  SubZen
//
//  Created by Star on 2024/12/24.
//

import UIKit
import SnapKit

class PrivacyPolicyController: UIViewController {
    private let textView = UITextView().with {
        $0.isEditable = false
        $0.font = .systemFont(ofSize: 15)
        $0.textColor = .label
        $0.backgroundColor = .systemBackground
        $0.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        $0.alwaysBounceVertical = true
    }

    init() {
        super.init(nibName: nil, bundle: nil)
        title = String(localized: "Privacy Policy")
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        view.addSubview(textView)
        textView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        loadPrivacyPolicy()
    }

    private func loadPrivacyPolicy() {
        guard let url = Bundle.main.url(forResource: "PrivacyPolicy", withExtension: "md"),
              let markdown = try? String(contentsOf: url)
        else {
            textView.text = String(localized: "Privacy policy not found. Please check your installation.")
            return
        }

        textView.text = markdown
    }
}
