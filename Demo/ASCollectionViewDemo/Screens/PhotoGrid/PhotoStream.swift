// ASCollectionView. Created by Apptek Studios 2019

import ASCollectionView
import SwiftUI
import UIKit

struct PhotoStreamScreen: View
{
	@State var data: [Post] = DataSource.postsForGridSection(1, number: 10)

	typealias SectionID = Int

	var sections: [ASCollectionViewSection<SectionID>]
	{
		data.map { item in
			ASSection(id: item.id, data: CollectionOfOne(item)) { item, context in
				RoundedRectangle(cornerRadius: 12.0, style: .continuous)
					.fill(Color.secondary)
					.overlay(
						Text("height = \(abs((item.id % 5) + 1) * 60)")
							.background(Color.white)
					)
					.frame(width: 100, height: CGFloat(160), alignment: .center)
			}
		}
	}

	var body: some View
	{
		ASCollectionView(sections: sections)
			.layout(self.layout)
			.edgesIgnoringSafeArea(.all)
			.navigationBarTitle("Explore", displayMode: .large)
	}

	func onCellEvent(_ event: CellEvent<Post>)
	{
		switch event
		{
		case let .onAppear(item):
			ASRemoteImageManager.shared.load(item.url)
		case let .onDisappear(item):
			ASRemoteImageManager.shared.cancelLoad(for: item.url)

		case let .prefetchForData(data):
			for item in data
			{
				ASRemoteImageManager.shared.load(item.url)
			}
		case let .cancelPrefetchForData(data):
			for item in data
			{
				ASRemoteImageManager.shared.cancelLoad(for: item.url)
			}
		}
	}
}

extension PhotoStreamScreen
{
	var layout: ASCollectionLayout<Int>
	{
		.init(customLayout: {
//			let size = NSCollectionLayoutSize(
//				widthDimension: .fractionalWidth(1.0),
//				heightDimension: .estimated(20)
//			)
//
//			let item = NSCollectionLayoutItem(layoutSize: size)
//			let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitem: item, count: 1)
//			let section = NSCollectionLayoutSection(group: group)
//			section.contentInsets = .init(top: 8, leading: 16, bottom: 8, trailing: 16)
//
//			let layout = TestLayout(section: section)
//			return layout

			let layout = UICollectionViewFlowLayout()
			layout.scrollDirection = .vertical
			layout.estimatedItemSize = CGSize(width: 414, height: 20)

			return layout
		})
	}
}

class TestLayout: UICollectionViewCompositionalLayout {
	override func shouldInvalidateLayout(forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> Bool {
		let value = super.shouldInvalidateLayout(forPreferredLayoutAttributes: preferredAttributes, withOriginalAttributes: originalAttributes)
		print("@@@", "layout", value, "t", originalAttributes.size, "f", preferredAttributes.size)
		return true
	}
}

struct StreamView_Previews: PreviewProvider
{
	static var previews: some View
	{
		PhotoStreamScreen()
	}
}
