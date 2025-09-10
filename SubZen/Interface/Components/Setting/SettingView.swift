//
//  SettingView.swift
//  SubZen
//
//  Created by Star on 2025/9/10.
//

import UIKit
import SnapKit

class SettingView: UIView {
		let nameLabel = UILabel().with{
				$0.text = "HelloWorld"
		}
		
		init() {
				super.init(frame: .zero)
				
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
