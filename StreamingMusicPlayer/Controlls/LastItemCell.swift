import UIKit

class LastItemCell: UITableViewCell {
	@IBOutlet weak var titleLabel: UILabel!

	var titleText: String = ""
	var itemsCount: UInt? = nil
	
	func refreshTitle(titleText: String, itemsCount: UInt?) {
		self.titleText = titleText
		self.itemsCount = itemsCount
		refreshTitle()
	}
	
	func refreshTitle() {
		guard titleText.characters.count > 0 else { titleLabel.text = nil; return }
		
		var text = titleText
		if let itemsCount = itemsCount {
			text += " (\(itemsCount))"
		}
		
		titleLabel.text = text
	}
}
