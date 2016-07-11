import UIKit

class FolderInfoCell: UITableViewCell {
	var cloudResource: CloudResource?
	
	@IBOutlet weak var folderNameLabel: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		// Initialization code
	}
	
	override func setSelected(selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
		
		// Configure the view for the selected state
	}
	
	func setDisplayResource(resource: CloudResource) {
		cloudResource = resource
	}
	
	func refresh() {
		folderNameLabel.text = cloudResource?.name
	}
}
