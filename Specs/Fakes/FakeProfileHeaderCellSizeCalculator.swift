////
///  FakeProfileHeaderCellSizeCalculator.swift
//

@testable import Ello


class FakeProfileHeaderCellSizeCalculator: ProfileHeaderCellSizeCalculator {

    override func processCells(_ cellItems: [StreamCellItem], withWidth: CGFloat, columnCount: Int, completion: @escaping Block) {
        for item in cellItems {
            item.calculatedCellHeights.oneColumn = AppSetup.Size.calculatorHeight
            item.calculatedCellHeights.multiColumn = AppSetup.Size.calculatorHeight
        }
        completion()
    }
}
