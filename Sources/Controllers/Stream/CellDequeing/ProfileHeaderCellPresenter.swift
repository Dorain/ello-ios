//
//  ProfileHeaderCellPresenter.swift
//  Ello
//
//  Created by Sean on 2/18/15.
//  Copyright (c) 2015 Ello. All rights reserved.
//

import Foundation


struct ProfileHeaderCellPresenter {

    static func configure(
        cell:UICollectionViewCell,
        streamCellItem:StreamCellItem,
        streamKind: StreamKind,
        indexPath: NSIndexPath)
    {
        if let cell = cell as? ProfileHeaderCell {
            let user = streamCellItem.jsonable as User

            if let avatarURL = user.avatarURL? {
                cell.setAvatarURL(avatarURL)
            }

            cell.relationshipView.userId = user.userId
            cell.relationshipView.userAtName = user.atName
            if let relationship = Relationship(rawValue: user.relationshipPriority) {
                cell.relationshipView.relationship = relationship
            }
            else {
                cell.relationshipView.relationship = Relationship.None
            }
            cell.relationshipView.hidden = user.isCurrentUser
            cell.usernameLabel.text = user.atName
            cell.nameLabel.text = user.name
            cell.countsTextView.appendTextWithAction("Posts \(user.postsCount? ?? 0) / ")
            cell.countsTextView.appendTextWithAction("Following \(user.followingCount? ?? 0) / ", link: "following", object: user)
            cell.countsTextView.appendTextWithAction("Followers \(user.followersCount? ?? 0)", link: "followers", object: user)
        }
    }
}


