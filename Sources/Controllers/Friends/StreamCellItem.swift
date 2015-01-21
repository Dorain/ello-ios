//
//  StreamCellItem.swift
//  Ello
//
//  Created by Sean Dougherty on 12/16/14.
//  Copyright (c) 2014 Ello. All rights reserved.
//

import Foundation

class StreamCellItem {

    enum CellType {
        case Header
        case CommentHeader
        case Footer
        case BodyElement
        case CommentBodyElement
    }

//    let comment:Comment?
    let streamable:Streamable
    let type:StreamCellItem.CellType
    let data:Block?
    var cellHeight:CGFloat = 0

    init(streamable:Streamable, type:StreamCellItem.CellType, data:Block?, cellHeight:CGFloat) {
        self.streamable = streamable
        self.type = type
        self.data = data
        self.cellHeight = cellHeight
    }
}