//
//  MappingType.swift
//  Ello
//
//  Created by Sean on 1/12/15.
//  Copyright (c) 2015 Ello. All rights reserved.
//


enum MappingType: String {
    case CommentsType = "comments"
    case CommentType = "comment"
    case PostsType = "posts"
    case PostType = "post"
    case ActivitiesType = "activities"
    case ActivityType = "activity"
    case UsersType = "users"
    case UserType = "user"
    case ErrorsType = "errors"
    case ErrorType = "error"
    case AssetsType = "assets"

    var jsonableType: JSONAble.Type {
        switch self {
        case CommentsType, CommentType: return Comment.self
        case PostsType, PostType: return Post.self
        case ActivitiesType, ActivityType: return Activity.self
        case UsersType, UserType: return User.self
        case ErrorsType, ErrorType: return ElloNetworkError.self
        default: return JSONAble.self
        }
    }

    var isOrdered: Bool {
        switch self {
        case AssetsType: return false
        default: return true
        }
    }

}
