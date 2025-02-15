// ASCollectionView. Created by Apptek Studios 2019

import ASCollectionView
import SwiftUI
import UIKit

struct PhotoGridScreen: View
{
	@State var data: [Post] = DataSource.postsForGridSection(1, number: 1000)
	@State var selectedIDs: Set<Int> = []

	@Environment(\.editMode) private var editMode
	var isEditing: Bool
	{
		editMode?.wrappedValue.isEditing ?? false
	}

	typealias SectionID = Int

	var section: ASCollectionViewSection<SectionID>
	{
		ASCollectionViewSection(
			id: 0,
			data: data,
			selectionMode: isEditing ? .multiple($selectedIDs) : .none,
			onCellEvent: onCellEvent)
		{ item, state in
			ZStack(alignment: .bottomTrailing)
			{
				GeometryReader
				{ geom in
					NavigationLink(destination: self.destinationForItem(item))
					{
						ASRemoteImageView(item.url)
							.aspectRatio(1, contentMode: .fill)
							.frame(width: geom.size.width, height: geom.size.height)
							.clipped()
							.opacity(self.isEditing ? (state.isSelected ? 1 : 0.7) : 1)
					}
					.buttonStyle(NeutralButtonStyle())
					.disabled(self.isEditing)
				}

				self.selectionIndicator(isSelected: state.isSelected, isHighlighted: state.isHighlighted)
			}
		}
	}

	var body: some View
	{
		ASCollectionView(
			editMode: isEditing,
			section: section)
			.layout(self.layout)
			.edgesIgnoringSafeArea(.all)
			.navigationBarTitle("Explore", displayMode: .large)
			.navigationBarItems(
				trailing:
				HStack(spacing: 20)
				{
					if self.isEditing
					{
						Button(action: {
							withAnimation
							{
								// We want the cell removal to be animated, so explicitly specify `withAnimation`
								self.data.removeAll { self.selectedIDs.contains($0.id) }
							}
						})
						{
							Image(systemName: "trash")
						}
					}

					EditButton()
				})
	}

	private func selectionIndicator(isSelected: Bool, isHighlighted: Bool) -> some View
	{
		let scale: CGFloat
		switch (isSelected, isHighlighted)
		{
		case (true, true): scale = 0.75
		case (true, false): scale = 1
		case (false, true): scale = 1.15
		case (false, false): scale = 0
		}

		return ZStack
		{
			Circle()
				.fill(Color.blue)
			Circle()
				.strokeBorder(Color.white, lineWidth: 2)
			Image(systemName: "checkmark")
				.font(.system(size: 10, weight: .bold))
				.foregroundColor(.white)
		}
		.frame(width: 20, height: 20)
		.padding(10)
		.scaleEffect(scale)
		.animation(Animation.easeInOut(duration: 0.15))
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

	func contextMenuProvider(int: Int, post: Post) -> UIContextMenuConfiguration?
	{
		let configuration = UIContextMenuConfiguration(identifier: nil, previewProvider: nil)
		{ (_) -> UIMenu? in
			let testAction = UIAction(title: "Do nothing")
			{ _ in
				//
			}
			let testAction2 = UIAction(title: "Try dragging the photo")
			{ _ in
				//
			}
			return UIMenu(title: "", image: nil, identifier: nil, options: [], children: [testAction, testAction2])
		}
		return configuration
	}

	func destinationForItem(_ item: Post) -> some View
	{
		ScrollView
		{
			PostView(post: item)
				.onAppear
				{
					ASRemoteImageManager.shared.load(item.url)
					ASRemoteImageManager.shared.load(item.usernamePhotoURL)
				}
		}
		.navigationBarTitle("", displayMode: .inline)
	}
}

extension PhotoGridScreen
{
	var layout: ASCollectionLayout<Int>
	{
		ASCollectionLayout(scrollDirection: .vertical, interSectionSpacing: 0)
		{
			ASCollectionLayoutSection
			{ environment in
				let isWide = environment.container.effectiveContentSize.width > 500
				let gridBlockSize = environment.container.effectiveContentSize.width / (isWide ? 5 : 3)
				let gridItemInsets = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)
				let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(gridBlockSize), heightDimension: .absolute(gridBlockSize))
				let item = NSCollectionLayoutItem(layoutSize: itemSize)
				item.contentInsets = gridItemInsets
				let verticalGroupSize = NSCollectionLayoutSize(widthDimension: .absolute(gridBlockSize), heightDimension: .absolute(gridBlockSize * 2))
				let verticalGroup = NSCollectionLayoutGroup.vertical(layoutSize: verticalGroupSize, subitem: item, count: 2)

				let featureItemSize = NSCollectionLayoutSize(widthDimension: .absolute(gridBlockSize * 2), heightDimension: .absolute(gridBlockSize * 2))
				let featureItem = NSCollectionLayoutItem(layoutSize: featureItemSize)
				featureItem.contentInsets = gridItemInsets

				let fullWidthItemSize = NSCollectionLayoutSize(widthDimension: .absolute(environment.container.effectiveContentSize.width), heightDimension: .absolute(gridBlockSize * 2))
				let fullWidthItem = NSCollectionLayoutItem(layoutSize: fullWidthItemSize)
				fullWidthItem.contentInsets = gridItemInsets

				let verticalAndFeatureGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(gridBlockSize * 2))
				let verticalAndFeatureGroupA = NSCollectionLayoutGroup.horizontal(layoutSize: verticalAndFeatureGroupSize, subitems: isWide ? [verticalGroup, verticalGroup, featureItem, verticalGroup] : [verticalGroup, featureItem])
				let verticalAndFeatureGroupB = NSCollectionLayoutGroup.horizontal(layoutSize: verticalAndFeatureGroupSize, subitems: isWide ? [verticalGroup, featureItem, verticalGroup, verticalGroup] : [featureItem, verticalGroup])

				let rowGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(gridBlockSize))
				let rowGroup = NSCollectionLayoutGroup.horizontal(layoutSize: rowGroupSize, subitem: item, count: isWide ? 5 : 3)

				let outerGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(gridBlockSize * 8))
				let outerGroup = NSCollectionLayoutGroup.vertical(layoutSize: outerGroupSize, subitems: [verticalAndFeatureGroupA, rowGroup, fullWidthItem, verticalAndFeatureGroupB, rowGroup])

				let section = NSCollectionLayoutSection(group: outerGroup)
				return section
			}
		}
	}

	var dragDropConfig: ASDragDropConfig<Post>
	{
		ASDragDropConfig<Post>(dataBinding: $data)
			.canDragItem
			{ (indexPath) -> Bool in
				true
				// indexPath.item != 0 // eg. prevent dragging/moving the first item
			}
			.canMoveItem
			{ (from, to) -> Bool in
				// You could add a check here to prevent moving between certain sections etc.
				true
			}
			.dragItemProvider
			{ item in
				NSItemProvider(object: item.url as NSURL)
			}
	}
}

struct GridView_Previews: PreviewProvider
{
	static var previews: some View
	{
		PhotoGridScreen()
	}
}

struct NeutralButtonStyle: ButtonStyle
{
	func makeBody(configuration: Configuration) -> some View
	{
		configuration.label
	}
}
