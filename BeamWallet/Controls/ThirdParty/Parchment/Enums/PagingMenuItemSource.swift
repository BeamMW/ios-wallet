import Foundation

public enum PagingMenuItemSource {
	case `class`(type: PagingCell.Type)
	case nib(nib: UINib)
}
