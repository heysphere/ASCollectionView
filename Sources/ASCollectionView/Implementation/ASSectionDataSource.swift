// ASCollectionView. Created by Apptek Studios 2019

import Foundation
import SwiftUI

@available(iOS 13.0, *)
internal protocol ASSectionDataSourceProtocol
{
	var endIndex: Int { get }
	func getIndexPaths(withSectionIndex sectionIndex: Int) -> [IndexPath]
	func getItemID<SectionID: Hashable>(for index: Int, withSectionID sectionID: SectionID) -> ASCollectionViewItemUniqueID?
	func getUniqueItemIDs<SectionID: Hashable>(withSectionID sectionID: SectionID) -> [ASCollectionViewItemUniqueID]
  func content(forItemID itemID: ASCollectionViewItemUniqueID, cellState: ASCellState) -> AnyView
	func content(supplementaryID: ASSupplementaryCellID) -> AnyView?
	var supplementaryViews: [String: AnyView] { get set }
	func getTypeErasedData(for indexPath: IndexPath) -> Any?
	func onAppear(_ indexPath: IndexPath)
	func onDisappear(_ indexPath: IndexPath)
	func prefetch(_ indexPaths: [IndexPath])
	func cancelPrefetch(_ indexPaths: [IndexPath])
	func willAcceptDropItem(from dragItem: UIDragItem) -> Bool
	func getDragItem(for indexPath: IndexPath) -> UIDragItem?
	func getItemID<SectionID: Hashable>(for dragItem: UIDragItem, withSectionID sectionID: SectionID) -> ASCollectionViewItemUniqueID?
	func supportsMove(_ indexPath: IndexPath) -> Bool
	func supportsMove(from sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) -> Bool
	func applyMove(from: IndexPath, to: IndexPath) -> Bool
	func applyRemove(atOffsets offsets: IndexSet)
	func applyInsert(items: [UIDragItem], at index: Int) -> Bool
	func supportsDelete(at indexPath: IndexPath) -> Bool
	func onDelete(indexPath: IndexPath) -> Bool
	func getContextMenu(for indexPath: IndexPath) -> UIContextMenuConfiguration?
	func getSelfSizingSettings(context: ASSelfSizingContext) -> ASSelfSizingConfig?

	func shouldHighlight(_ indexPath: IndexPath, currentSelection: Set<Int>) -> Bool
	func shouldSelect(_ indexPath: IndexPath, currentSelection: Set<Int>) -> Bool
	func shouldDeselect(_ indexPath: IndexPath) -> Bool

  func currentSwiftUISelections() -> Set<Int>
	func writebackSelectionToSwiftUI(with indices: Set<Int>)

	var dragEnabled: Bool { get }
	var dropEnabled: Bool { get }
	var canDropItem: ((IndexPath) -> Bool)? { get }
	var reorderingEnabled: Bool { get }

	mutating func setSelfSizingConfig(config: @escaping SelfSizingConfig)
}

@available(iOS 13.0, *)
protocol ASDataSourceConfigurableCell
{
	func setContent<Content: View>(itemID: ASCollectionViewItemUniqueID, content: Content)
	var hostingController: ASHostingController<AnyView> { get }
	var disableSwiftUIDropInteraction: Bool { get set }
	var disableSwiftUIDragInteraction: Bool { get set }
}

@available(iOS 13.0, *)
protocol ASDataSourceConfigurableSupplementary
{
	func setContent<Content: View>(supplementaryID: ASSupplementaryCellID, content: Content?)
	func setAsEmpty(supplementaryID: ASSupplementaryCellID?)
}

@available(iOS 13.0, *)
public enum ASSectionSelectionMode<DataID: Hashable>
{
	case none
  case single(Binding<DataID?>)
	case multiple(Binding<Set<DataID>>)
}

internal struct ASCellState {
  var isSelected: Bool = false
  var isHighlighted: Bool = false
}

@available(iOS 13.0, *)
internal struct ASSectionDataSource<DataCollection: RandomAccessCollection, DataID, Content, Container>: ASSectionDataSourceProtocol where DataID: Hashable, Content: View, Container: View, DataCollection.Index == Int
{
	typealias Data = DataCollection.Element
	var data: DataCollection
	var dataIDKeyPath: KeyPath<Data, DataID>
	var container: (Content, ASCellContext) -> Container
	var content: (DataCollection.Element, ASCellContext) -> Content

	var selectionMode: ASSectionSelectionMode<DataID> = .none
	var shouldAllowHighlight: ((_ index: Int) -> Bool)?
	var shouldAllowSelection: ((_ index: Int) -> Bool)?
	var shouldAllowDeselection: ((_ index: Int) -> Bool)?

	var onCellEvent: OnCellEvent<DataCollection.Element>?
	var dragDropConfig: ASDragDropConfig<DataCollection.Element>
	var shouldAllowSwipeToDelete: ShouldAllowSwipeToDelete?
	var onSwipeToDelete: OnSwipeToDelete<DataCollection.Element>?
	var contextMenuProvider: ContextMenuProvider<DataCollection.Element>?
	var selfSizingConfig: (SelfSizingConfig)?

	var supplementaryViews: [String: AnyView] = [:]

	var dragEnabled: Bool { dragDropConfig.dragEnabled }
	var dropEnabled: Bool { dragDropConfig.dropEnabled }
	var canDropItem: ((IndexPath) -> Bool)? { dragDropConfig.canDropItem }
	var reorderingEnabled: Bool { dragDropConfig.reorderingEnabled }

	var endIndex: Int { data.endIndex }

  func getIndex(of itemID: ASCollectionViewItemUniqueID) -> Int?
  {
    data.firstIndex(where: { AnyHashable($0[keyPath: dataIDKeyPath]) == itemID.itemID })
  }

  private func getIndex(of dataID: DataID) -> Int?
  {
    data.firstIndex(where: { $0[keyPath: dataIDKeyPath] == dataID })
  }

  func cellContext(for index: Int, cellState: ASCellState) -> ASCellContext
	{
		ASCellContext(
      isHighlighted: cellState.isHighlighted,
      isSelected: cellState.isSelected,
			index: index,
			isFirstInSection: index == data.startIndex,
			isLastInSection: index == data.endIndex - 1)
	}

  func content(forItemID itemID: ASCollectionViewItemUniqueID, cellState: ASCellState) -> AnyView
	{
		guard let content = getContent(forItemID: itemID, cellState: cellState)
		else
		{
			return AnyView(EmptyView().id(itemID))
		}
		return AnyView(content.id(itemID))
	}

	func content(supplementaryID: ASSupplementaryCellID) -> AnyView?
	{
		guard let content = supplementaryViews[supplementaryID.supplementaryKind] else { return nil }
		return AnyView(content.id(supplementaryID))
	}

  func getContent(forItemID itemID: ASCollectionViewItemUniqueID, cellState: ASCellState) -> Container?
	{
		guard let itemIndex = getIndex(of: itemID) else { return nil }
		let item = data[itemIndex]
    let context = cellContext(for: itemIndex, cellState: cellState)
		let view = content(item, context)
		return container(view, context)
	}

	func getTypeErasedData(for indexPath: IndexPath) -> Any?
	{
		data[safe: indexPath.item]
	}

	func getIndexPaths(withSectionIndex sectionIndex: Int) -> [IndexPath]
	{
		data.indices.map { IndexPath(item: $0, section: sectionIndex) }
	}

	func getItemID<SectionID: Hashable>(for index: Int, withSectionID sectionID: SectionID) -> ASCollectionViewItemUniqueID?
	{
		data[safe: index].map { getItemID(for: $0, withSectionID: sectionID) }
	}

	func getItemID<SectionID: Hashable>(for item: Data, withSectionID sectionID: SectionID) -> ASCollectionViewItemUniqueID
	{
		ASCollectionViewItemUniqueID(sectionID: sectionID, itemID: item[keyPath: dataIDKeyPath])
	}

	func getUniqueItemIDs<SectionID: Hashable>(withSectionID sectionID: SectionID) -> [ASCollectionViewItemUniqueID]
	{
		data.map
		{
			ASCollectionViewItemUniqueID(sectionID: sectionID, itemID: $0[keyPath: dataIDKeyPath])
		}
	}

	func onAppear(_ indexPath: IndexPath)
	{
		guard let item = data[safe: indexPath.item] else { return }
		onCellEvent?(.onAppear(item: item))
	}

	func onDisappear(_ indexPath: IndexPath)
	{
		guard let item = data[safe: indexPath.item] else { return }
		onCellEvent?(.onDisappear(item: item))
	}

	func prefetch(_ indexPaths: [IndexPath])
	{
		let dataToPrefetch: [Data] = indexPaths.compactMap
		{
			data[safe: $0.item]
		}
		onCellEvent?(.prefetchForData(data: dataToPrefetch))
	}

	func cancelPrefetch(_ indexPaths: [IndexPath])
	{
		let dataToCancelPrefetch: [Data] = indexPaths.compactMap
		{
			data[safe: $0.item]
		}
		onCellEvent?(.cancelPrefetchForData(data: dataToCancelPrefetch))
	}

	func supportsDelete(at indexPath: IndexPath) -> Bool
	{
		guard onSwipeToDelete != nil else { return false }
		return shouldAllowSwipeToDelete?(indexPath.item) ?? true
	}

	func onDelete(indexPath: IndexPath) -> Bool
	{
		guard let item = data[safe: indexPath.item], let onDelete = onSwipeToDelete else { return false }
		let didDelete = onDelete(indexPath.item, item)
		return didDelete
	}

	func getDragItem(for indexPath: IndexPath) -> UIDragItem?
	{
		guard dragEnabled,
			dragDropConfig.canDragItem?(indexPath) ?? true
		else { return nil }
		guard let item = data[safe: indexPath.item] else { return nil }

		let itemProvider: NSItemProvider = dragDropConfig.dragItemProvider?(item) ?? NSItemProvider()
		let dragItem = UIDragItem(itemProvider: itemProvider)
		dragItem.localObject = item
		return dragItem
	}

	func willAcceptDropItem(from dragItem: UIDragItem) -> Bool
	{
		getDropItem(from: dragItem) != nil
	}

	func getDropItem(from dragItem: UIDragItem) -> Data?
	{
		guard dropEnabled else { return nil }

		let sourceItem = dragItem.localObject as? Data
		return dragDropConfig.dropItemProvider?(sourceItem, dragItem) ?? sourceItem
	}

	func getItemID<SectionID: Hashable>(for dragItem: UIDragItem, withSectionID sectionID: SectionID) -> ASCollectionViewItemUniqueID?
	{
		guard let item = getDropItem(from: dragItem) else { return nil }
		return getItemID(for: item, withSectionID: sectionID)
	}

	func supportsMove(_ indexPath: IndexPath) -> Bool
	{
		dragDropConfig.reorderingEnabled && (dragDropConfig.canDragItem?(indexPath) ?? true)
	}

	func supportsMove(from sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) -> Bool
	{
		dragDropConfig.reorderingEnabled && (dragDropConfig.canMoveItem?(sourceIndexPath, destinationIndexPath) ?? true)
	}

	func applyMove(from: IndexPath, to: IndexPath) -> Bool
	{
		// dragDropConfig.dataBinding?.wrappedValue.move(fromOffsets: [from], toOffset: to) //This is not behaving as expected
		// NOTE: Binding seemingly not updated until next runloop. Any change must be done in one move; hence the var array
		guard from != to,
			dragDropConfig.canMoveItem?(from, to) ?? true
		else { return false }
		if let binding = dragDropConfig.dataBinding
		{
			var array = binding.wrappedValue
			let value = array.remove(at: from.item)
			array.insert(value, at: to.item)
			binding.wrappedValue = array
			return true
		}
		else
		{
			return dragDropConfig.onMoveItem?(from.item, to.item) ?? false
		}
	}

	func applyRemove(atOffsets offsets: IndexSet)
	{
		if let binding = dragDropConfig.dataBinding
		{
			binding.wrappedValue.remove(atOffsets: offsets)
		}
		else
		{
			_ = dragDropConfig.onDeleteOrRemoveItems?(offsets)
		}
	}

	func applyInsert(items: [UIDragItem], at index: Int) -> Bool
	{
		let actualItems = items.compactMap(getDropItem(from:))
		if let binding = dragDropConfig.dataBinding
		{
			let allDataIDs = Set(binding.wrappedValue.map { $0[keyPath: dataIDKeyPath] })
			let noDuplicates = actualItems.filter { !allDataIDs.contains($0[keyPath: dataIDKeyPath]) }
#if DEBUG
			// Notify during debug build if IDs are not unique (programmer error)
			if noDuplicates.count != actualItems.count { print("ASCOLLECTIONVIEW/ASTABLEVIEW: Attempted to insert an item with the same ID as one already in the section. This may cause unexpected behaviour.") }
#endif
			binding.wrappedValue.insert(contentsOf: noDuplicates, at: index)
			return !noDuplicates.isEmpty
		}
		else
		{
			return dragDropConfig.onInsertItems?(index, actualItems) ?? false
		}
	}

	func getContextMenu(for indexPath: IndexPath) -> UIContextMenuConfiguration?
	{
		guard
			let menuProvider = contextMenuProvider,
			let item = data[safe: indexPath.item]
		else { return nil }

		return menuProvider(indexPath.item, item)
	}

	func getSelfSizingSettings(context: ASSelfSizingContext) -> ASSelfSizingConfig?
	{
		selfSizingConfig?(context)
	}

  func shouldHighlight(_ indexPath: IndexPath, currentSelection: Set<Int>) -> Bool
	{
		guard data.containsIndex(indexPath.item) else { return false }
		switch selectionMode {
		case .none:
      return false
    case .single, .multiple:
      return shouldSelect(indexPath, currentSelection: currentSelection)
        && (shouldAllowHighlight?(indexPath.item) ?? true)
		}
	}

  func shouldSelect(_ indexPath: IndexPath, currentSelection: Set<Int>) -> Bool
	{
		guard data.containsIndex(indexPath.item) else { return false }
		switch selectionMode
		{
    case .none:
      return false
    case .single:
      return currentSelection.isEmpty && (shouldAllowSelection?(indexPath.item) ?? true)
    case .multiple:
			return shouldAllowSelection?(indexPath.item) ?? true
		}
	}

	func shouldDeselect(_ indexPath: IndexPath) -> Bool
	{
		guard data.containsIndex(indexPath.item) else { return false }
		return shouldAllowDeselection?(indexPath.item) ?? true
	}

  func currentSwiftUISelections() -> Set<Int> {
    let ids: Set<DataID>

    switch selectionMode {
    case .none:
      return []

    case let .multiple(binding):
      ids = binding.wrappedValue

    case let .single(binding):
      ids = binding.wrappedValue.map { [$0] } ?? []
    }

    return Set(ids.compactMap(getIndex(of:)))
  }

  func writebackSelectionToSwiftUI(with indices: Set<Int>) {
    let newSelection = Set(indices.compactMap { data[safe: $0]?[keyPath: dataIDKeyPath] })

    switch selectionMode {
    case .none:
      break

    case let .multiple(binding):
      binding.wrappedValue = newSelection

    case let .single(binding):
      binding.wrappedValue = newSelection.first
    }
  }
}

// MARK: SELF SIZING MODIFIERS - INTERNAL

@available(iOS 13.0, *)
internal extension ASSectionDataSource
{
	mutating func setSelfSizingConfig(config: @escaping SelfSizingConfig)
	{
		selfSizingConfig = config
	}
}
