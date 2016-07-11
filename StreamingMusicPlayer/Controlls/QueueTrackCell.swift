import UIKit
import RxSwift

class QueueTrackCell: UITableViewCell {
	internal var bag = DisposeBag()
	
	@IBOutlet weak var albumArtImage: UIImageView!
	@IBOutlet weak var trackTitleLabel: UILabel!
	@IBOutlet weak var artistNameLabel: UILabel!
	@IBOutlet weak var trackTimeLabel: UILabel!
}
