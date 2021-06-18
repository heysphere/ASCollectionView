// ASCollectionView. Created by Apptek Studios 2019

import ASCollectionView
import SwiftUI
import UIKit

/// THIS IS A WORK IN PROGRESS
struct WaterfallScreen: View
{
	@State var data: [[Post]] = (0 ... 10).map { DataSource.postsForWaterfallSection($0, number: 100) }
	@State var selectedIDs: [SectionID: Set<Int>] = [:]
	@State var selectedPostID: Int? = nil // Post being viewed in the detail view
	@State var columnMinSize: CGFloat = 150

	private var selectedPost: Binding<Post?>
	{
		.init(
			get: { selectedPostID.flatMap { id in data.lazy.compactMap { $0.first { $0.id == id } }.first } },
			set: { selectedPostID = $0?.id }
		)
	}

	@Environment(\.editMode) private var editMode
	var isEditing: Bool
	{
		editMode?.wrappedValue.isEditing ?? false
	}

	typealias SectionID = Int

	var sections: [ASCollectionViewSection<SectionID>]
	{
		data.enumerated().map
		{ offset, sectionData in
			ASCollectionViewSection(
				id: offset,
				data: sectionData,
				selectionMode: self.isEditing ? .multiple($selectedIDs[offset]) : .single($selectedPostID),
				onCellEvent: onCellEvent)
			{ item, state in
				GeometryReader
				{ geom in
					ZStack(alignment: .bottomTrailing)
					{
						ASRemoteImageView(item.url)
							.scaledToFill()
							.frame(width: geom.size.width, height: geom.size.height)
							.opacity(self.opacity(isHighlighted: state.isHighlighted, isSelected: state.isSelected))

						if self.isEditing && state.isSelected
						{
							ZStack
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
						}
						else
						{
							Text("\(item.offset)")
								.font(.headline)
								.bold()
								.padding(2)
								.background(Color(.systemBackground).opacity(0.5))
								.cornerRadius(4)
								.padding(10)
						}
					}
					.frame(width: geom.size.width, height: geom.size.height)
					.clipped()
				}
			}.sectionHeader
			{
				Text("Section \(offset)")
					.padding()
					.frame(idealWidth: .infinity, maxWidth: .infinity, idealHeight: .infinity, maxHeight: .infinity, alignment: .leading)
					.background(Color.blue)
			}
		}
	}

	var body: some View
	{
		VStack(spacing: 0)
		{
			if self.isEditing
			{
				HStack
				{
					Text("Min. column size")
					Slider(value: self.$columnMinSize, in: 60 ... 200)
				}.padding()
			}

			ASCollectionView(
				editMode: isEditing,
				sections: sections)
				.layout(self.layout)
				.customDelegate(WaterfallScreenLayoutDelegate.init)
				.contentInsets(.init(top: 0, left: 10, bottom: 10, right: 10))
				.postSheet(item: selectedPost, onDismiss: { self.selectedIDs = [:] })
				.navigationBarTitle("Waterfall Layout", displayMode: .inline)
				.navigationBarItems(
					trailing:
					HStack(spacing: 20)
					{
						if self.isEditing
						{
							Button(action: {
								withAnimation
								{
									self.selectedIDs.forEach
									{ sectionIndex, selected in
										self.data[sectionIndex].remove(atOffsets: IndexSet(selected))
									}
								}
							})
							{
								Image(systemName: "trash")
							}
						}

						EditButton()
					})
		}
	}

	func opacity(isHighlighted: Bool, isSelected: Bool) -> Double
	{
		if !isEditing && isHighlighted
		{
			return 0.7
		}
		else if isEditing && isSelected
		{
			return 0.7
		}
		else
		{
			return 1
		}
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

private extension View
{
	func postSheet(item: Binding<Post?>, onDismiss: @escaping () -> Void) -> some View
	{
		sheet(item: item, onDismiss: onDismiss)
		{ post in
			VStack
			{
				ASRemoteImageView(post.url)
					.scaledToFill()
			}
		}
	}
}

extension WaterfallScreen
{
	var layout: ASCollectionLayout<Int>
	{
		ASCollectionLayout(createCustomLayout: ASWaterfallLayout.init)
		{ layout in
			layout.numberOfColumns = .adaptive(minWidth: self.columnMinSize)
		}
		// Can also initialise like this when no need to dynamically update values
		/*
		 ASCollectionLayout
		 {
		 	let layout = ASWaterfallLayout()
		 	return layout
		 }
		 */
	}
}

struct WaterfallScreen_Previews: PreviewProvider
{
	static var previews: some View
	{
		WaterfallScreen()
	}
}

class WaterfallScreenLayoutDelegate: ASCollectionViewDelegate, ASWaterfallLayoutDelegate
{
	func heightForHeader(sectionIndex: Int) -> CGFloat?
	{
		60
	}

	/// We explicitely provide a height here. If providing no delegate, this layout will use auto-sizing, however this causes problems if rotating the device (due to limitaitons in UICollecitonView and autosizing cells that are not visible)
	func heightForCell(at indexPath: IndexPath, context: ASWaterfallLayout.CellLayoutContext) -> CGFloat
	{
		guard let post: Post = getDataForItem(at: indexPath) else { return 100 }
		return context.width / post.aspectRatio
	}
}
