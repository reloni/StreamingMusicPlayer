import Foundation
import RxStreamPlayer

class AddItemsToPlayListModel {
	let tracks: [TrackType]
	let albums: [AlbumType]
	let artists: [ArtistType]
	let mainModel: MainModel
	
	init(mainModel: MainModel, artists: [ArtistType], albums: [AlbumType], tracks: [TrackType]) {
		self.mainModel = mainModel
		self.artists = artists
		self.albums = albums
		self.tracks = tracks
	}
	
	func addItemsToPlayLists(playLists: [PlayListType]) {
		playLists.forEach { pl in
			artists.forEach { mainModel.addArtistToPlayList($0, playList: pl) }
			albums.forEach { mainModel.addAlbumToPlayList($0, playList: pl) }
			mainModel.addTracksToPlayList(tracks, playList: pl)
		}
	}
}