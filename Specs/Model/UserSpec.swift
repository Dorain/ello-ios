//
//  UserSpec.swift
//  Ello
//
//  Created by Sean Dougherty on 12/1/14.
//  Copyright (c) 2014 Ello. All rights reserved.
//

@testable
import Ello
import Quick
import Nimble


class UserSpec: QuickSpec {
    override func spec() {
        describe("User") {
            describe("isOwnPost(_:)") {
                let subject: User = stub(["id": "correctId"])
                it("should return true if post's author is the current user") {
                    let post: Post = stub(["authorId": "correctId"])
                    expect(subject.isOwnPost(post)) == true
                }
                it("should return false if post's author is not the user") {
                    let post: Post = stub(["authorId": "WRONG ID"])
                    expect(subject.isOwnPost(post)) == false
                }
            }

            describe("isOwnComment(_:)") {
                let subject: User = stub(["id": "correctId"])
                it("should return true if comment's author is the current user") {
                    let comment: ElloComment = stub(["authorId": "correctId"])
                    expect(subject.isOwnComment(comment)) == true
                }
                it("should return false if comment's author is not the user") {
                    let comment: ElloComment = stub(["authorId": "WRONG ID"])
                    expect(subject.isOwnComment(comment)) == false
                }
            }

            describe("isOwnParentPost(_:)") {
                let subject: User = stub(["id": "correctId"])
                it("should return true if comment parentPost's author is the current user") {
                    let post: Post = stub(["authorId": "correctId"])
                    let comment: ElloComment = stub(["loadedFromPost": post])
                    expect(subject.isOwnParentPost(comment)) == true
                }
                it("should return false if comment parentPost's author is not the user") {
                    let post: Post = stub(["authorId": "WRONG ID"])
                    let comment: ElloComment = stub(["loadedFromPost": post])
                    expect(subject.isOwnParentPost(comment)) == false
                }
            }

            describe("+fromJSON:") {
                it("parses correctly") {
                    let data = stubbedJSONData("users_user_details", "users")
                    let user = User.fromJSON(data) as! User
                    // active record
                    expect(user.id) == "420"
                    // required
                    expect(user.href) == "/api/v2/users/420"
                    expect(user.username) == "pam"
                    expect(user.name) == "Pamilanderson"
                    expect(user.experimentalFeatures) == true
                    expect(user.relationshipPriority) == RelationshipPriority.None
                    //TODO: test for "has_commenting_enabled", "has_reposting_enabled", "has_sharing_enabled" and
                    // "has_loves_enabled"
                    // optional
                    expect(user.avatar).to(beAKindOf(Asset.self))
                    expect(user.identifiableBy) == ""
                    expect(user.postsCount!) == 4
                    expect(user.followersCount!) == "0"
                    expect(user.followingCount!) == 0
                    expect(user.formattedShortBio) == "<p>Have been spying for a while now.</p>"
    //                expect(user.externalLinks) == "http://isis.com http://ello.co"
                    expect(user.coverImage).to(beAKindOf(Asset.self))
                    expect(user.backgroundPosition) == ""
                    expect(user.isCurrentUser) == false

    //                expect(user.mostRecentPost).toNot(beNil())
    //                expect(user.mostRecentPost?.id) == "4721"
    //                expect(user.mostRecentPost?.author) == user
                }
            }

           context("NSCoding") {

                var filePath = ""
                if let url = NSURL(string: NSFileManager.ElloDocumentsDir()) {
                    filePath = url.URLByAppendingPathComponent("UserSpec").absoluteString
                }

                afterEach {
                    do {
                        try NSFileManager.defaultManager().removeItemAtPath(filePath)
                    }
                    catch {

                    }
                }

                context("encoding") {

                    it("encodes successfully") {
                        let user: User = stub([:])

                        let wasSuccessfulArchived = NSKeyedArchiver.archiveRootObject(user, toFile: filePath)

                        expect(wasSuccessfulArchived).to(beTrue())
                    }
                }

                context("decoding") {

                    it("decodes successfully") {
                        let post: Post = stub(["id" : "sample-post-id"])
                        let stubbedMostRecentPost: Post = stub(["id" : "another-sample-post-id", "authorId" : "sample-userId"])
                        let attachment: Attachment = stub(["url": NSURL(string: "http://www.example.com")!, "height": 0, "width": 0, "type": "png", "size": 0 ])
                        let asset: Asset = stub(["regular" : attachment])
                        let coverAttachment: Attachment = stub(["url": NSURL(string: "http://www.example2.com")!, "height": 0, "width": 0, "type": "png", "size": 0 ])
                        let coverAsset: Asset = stub(["hdpi" : coverAttachment])

                        let user: User = stub([
                            "avatar" : asset,
                            "coverImage" : coverAsset,
                            "experimentalFeatures" : true,
                            "followersCount" : "6",
                            "followingCount" : 8,
                            "href" : "sample-href",
                            "name" : "sample-name",
                            "posts" : [post],
                            "postsCount" : 9,
                            "mostRecentPost" : stubbedMostRecentPost,
                            "relationshipPriority" : "self",
                            "id" : "sample-userId",
                            "username" : "sample-username",
                            "profile": Profile.stub(["email": "sample@email.com"]) ,
                            "formattedShortBio" : "sample-short-bio",
                            "externalLinks": "sample-external-links"
                        ])

                        NSKeyedArchiver.archiveRootObject(user, toFile: filePath)
                        let unArchivedUser = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as! User

                        expect(unArchivedUser).toNot(beNil())
                        expect(unArchivedUser.version) == 1

                        expect(unArchivedUser.avatarURL?.absoluteString) == "http://www.example.com"
                        expect(unArchivedUser.coverImageURL?.absoluteString) == "http://www.example2.com"
                        expect(unArchivedUser.experimentalFeatures).to(beTrue())
                        expect(unArchivedUser.followersCount) == "6"
                        expect(unArchivedUser.followingCount) == 8
                        expect(unArchivedUser.href) == "sample-href"
                        expect(unArchivedUser.name) == "sample-name"
                        expect(unArchivedUser.hasCommentingEnabled) == true
                        expect(unArchivedUser.hasLovesEnabled) == true
                        expect(unArchivedUser.hasSharingEnabled) == true
                        expect(unArchivedUser.hasRepostingEnabled) == true

                        let firstPost = unArchivedUser.posts!.first!
                        expect(firstPost.id) == "sample-post-id"

                        expect(unArchivedUser.relationshipPriority.rawValue) == "self"
                        expect(unArchivedUser.id) == "sample-userId"
                        expect(unArchivedUser.username) == "sample-username"
                        expect(unArchivedUser.formattedShortBio) == "sample-short-bio"
    //                    expect(unArchivedUser.externalLinks) == "sample-external-links"
                        expect(unArchivedUser.isCurrentUser).to(beTrue())

                        expect(unArchivedUser.mostRecentPost).toNot(beNil())
                        expect(unArchivedUser.mostRecentPost?.id) == "another-sample-post-id"
                        expect(unArchivedUser.mostRecentPost?.author!.id) == unArchivedUser.id
                    }
                }
            }
        }

        describe("merge(JSONAble)") {
            it("returns non-User objects") {
                let post: Post = stub([:])
                let user: User = stub([:])
                expect(user.merge(post)) == post
            }
            it("returns User objects") {
                let userA: User = stub([:])
                let userB: User = stub([:])
                expect(userA.merge(userB)) == userB
            }
            it("merges the formattedShortBio") {
                let userA: User = stub(["formattedShortBio": "userA"])
                let userB: User = stub(["formattedShortBio": "userB"])
                let merged = userA.merge(userB) as! User
                expect(merged.formattedShortBio) == "userB"
            }
            it("preserves the formattedShortBio") {
                let userA: User = stub(["formattedShortBio": "userA"])
                let userB: User = stub(["formattedShortBio": ""])
                let merged = userA.merge(userB) as! User
                expect(merged.formattedShortBio) == "userA"
            }
        }
    }
}
