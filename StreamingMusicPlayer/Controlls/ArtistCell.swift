import UIKit
import RxSwift

class ArtistCell: UITableViewCell {
	var bag: DisposeBag = DisposeBag()
	
	@IBOutlet weak var albumCountLabel: UILabel!
	@IBOutlet weak var artistNameLabel: UILabel!
	@IBOutlet weak var showMenuButton: UIButton!
	
	override func prepareForReuse() {
		bag = DisposeBag()
	}
}
