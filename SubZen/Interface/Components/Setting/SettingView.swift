//
//  SettingView.swift
//  SubZen
//
//  Created by Star on 2025/9/10.
//

import SnapKit
import UIKit

class SettingView: UIView {
    private let nameLabel = UILabel().with {
        $0.text = "HelloWorld"
    }

    init() {
        super.init(frame: .zero)

        backgroundColor = .background

        addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }
}

#if DEBUG && canImport(SwiftUI)
    import SwiftUI

    #Preview {
        UIViewPreview {
            let view = SettingView()
            return view
        }
    }
#endif
