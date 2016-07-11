import UIKit
import RxSwift

class CloudFolderCell: UITableViewCell {
	internal var bag = DisposeBag()
	
	@IBOutlet weak var playButton: UIButton!
	@IBOutlet weak var folderNameLabel: UILabel!
}
