////
///  OmnibarViewController.swift
//

import Crashlytics
import SwiftyUserDefaults
import PINRemoteImage


class OmnibarViewController: BaseElloViewController {
    var keyboardWillShowObserver: NotificationObserver?
    var keyboardWillHideObserver: NotificationObserver?

    override var tabBarItem: UITabBarItem? {
        get { return UITabBarItem.item(.omni) }
        set { self.tabBarItem = newValue }
    }

    var previousTab: ElloTab = .DefaultTab
    var parentPost: Post?
    var editPost: Post?
    var editComment: ElloComment?
    var rawEditBody: [Regionable]?
    var defaultText: String?
    var canGoBack: Bool = true {
        didSet {
            if isViewLoaded {
                screen.canGoBack = canGoBack
            }
        }
    }

    typealias CommentSuccessListener = (_ comment: ElloComment) -> Void
    typealias PostSuccessListener = (_ post: Post) -> Void
    var commentSuccessListener: CommentSuccessListener?
    var postSuccessListener: PostSuccessListener?

    var _mockScreen: OmnibarScreenProtocol?
    var screen: OmnibarScreenProtocol {
        set(screen) { _mockScreen = screen }
        get {
            if let mock = _mockScreen { return mock }
            return self.view as! OmnibarScreen
        }
    }

    convenience init(parentPost post: Post) {
        self.init(nibName: nil, bundle: nil)
        parentPost = post
    }

    convenience init(editComment comment: ElloComment) {
        self.init(nibName: nil, bundle: nil)
        editComment = comment
        PostService().loadComment(comment.postId, commentId: comment.id, success: { (comment, _) in
            self.rawEditBody = comment.body
            if let body = comment.body, self.isViewLoaded {
                self.prepareScreenForEditing(body, isComment: true)
            }
        })
    }

    convenience init(editPost post: Post) {
        self.init(nibName: nil, bundle: nil)
        editPost = post
        PostService().loadPost(post.id, needsComments: false)
            .onSuccess { post in
                self.rawEditBody = post.body
                if let body = post.body, self.isViewLoaded {
                    self.prepareScreenForEditing(body, isComment: false)
                }
            }
            .ignoreFailures()
    }

    convenience init(parentPost post: Post, defaultText: String?) {
        self.init(parentPost: post)
        self.defaultText = defaultText
    }

    convenience init(defaultText: String?) {
        self.init(nibName: nil, bundle: nil)
        self.defaultText = defaultText
    }

    override func didSetCurrentUser() {
        super.didSetCurrentUser()
        if isViewLoaded {
            if let cachedImage = TemporaryCache.load(.avatar) {
                screen.avatarImage = cachedImage
            }
            else {
                screen.avatarURL = currentUser?.avatarURL()
            }
        }
    }

    func onCommentSuccess(_ listener: @escaping CommentSuccessListener) {
        commentSuccessListener = listener
    }

    func onPostSuccess(_ listener: @escaping PostSuccessListener) {
        postSuccessListener = listener
    }

    override func loadView() {
        self.view = OmnibarScreen(frame: UIScreen.main.bounds)

        screen.canGoBack = canGoBack
        screen.currentUser = currentUser
        var defaultRegions: [Regionable] = []
        if let text = defaultText {
            defaultRegions = [TextRegion(content: text)]
        }

        if editPost != nil {
            screen.title = InterfaceString.Omnibar.EditPostTitle
            screen.submitTitle = InterfaceString.Omnibar.EditPostButton
            screen.isEditing = true
            if let rawEditBody = rawEditBody {
                prepareScreenForEditing(rawEditBody, isComment: false)
            }
        }
        else if editComment != nil {
            screen.title = InterfaceString.Omnibar.EditCommentTitle
            screen.submitTitle = InterfaceString.Omnibar.EditCommentButton
            screen.isEditing = true
            if let rawEditBody = rawEditBody {
                prepareScreenForEditing(rawEditBody, isComment: true)
            }
        }
        else {
            let isComment: Bool
            if parentPost != nil {
                screen.title = InterfaceString.Omnibar.CreateCommentTitle
                screen.submitTitle = InterfaceString.Omnibar.CreateCommentButton
                isComment = true
            }
            else {
                screen.title = ""
                screen.submitTitle = InterfaceString.Omnibar.CreatePostButton
                isComment = false
            }
            prepareScreenForEditing(defaultRegions, isComment: isComment)

            if let fileName = omnibarDataName(),
                let data: Data = Tmp.read(fileName), (defaultText ?? "") == ""
            {
                if let omnibarData = NSKeyedUnarchiver.unarchiveObject(with: data) as? OmnibarCacheData {
                    let regions: [OmnibarRegion] = omnibarData.regions.flatMap { obj in
                        if let region = OmnibarRegion.fromRaw(obj) {
                            return region
                        }
                        return nil
                    }
                    _ = Tmp.remove(fileName)
                    screen.regions = regions
                }
            }
        }
        screen.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        postNotification(StatusBarNotifications.statusBarShouldChange, value: (false, .slide))
        UIApplication.shared.statusBarStyle = .lightContent

        if let previousTab = elloTabBarController?.previousTab {
            self.previousTab = previousTab
        }

        if let cachedImage = TemporaryCache.load(.avatar) {
            screen.avatarImage = cachedImage
        }
        else {
            screen.avatarURL = currentUser?.avatarURL()
        }

        keyboardWillShowObserver = NotificationObserver(notification: Keyboard.Notifications.KeyboardWillShow, block: self.keyboardWillShow)
        keyboardWillHideObserver = NotificationObserver(notification: Keyboard.Notifications.KeyboardWillHide, block: self.keyboardWillHide)
        view.setNeedsLayout()

        let isEditing = (editPost != nil || editComment != nil)
        if isEditing {
            if rawEditBody == nil {
                ElloHUD.showLoadingHudInView(self.view)
            }
        }
        else {
            let isShowingNarration = elloTabBarController?.shouldShowNarration ?? false
            let isPosting = !screen.interactionEnabled
            if !isShowingNarration && !isPosting && presentedViewController == nil {
                // desired behavior: animate the keyboard in when this screen is
                // shown.  without the delay, the keyboard just appears suddenly.
                delay(0) {
                    self.screen.startEditing()
                }
            }
        }

        screen.updateButtons()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        elloTabBarController?.setTabBarHidden(false, animated: animated)
        Crashlytics.sharedInstance().setObjectValue("Omnibar", forKey: CrashlyticsKey.streamName.rawValue)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        screen.stopEditing()

        if let keyboardWillShowObserver = keyboardWillShowObserver {
            keyboardWillShowObserver.removeObserver()
            self.keyboardWillShowObserver = nil
        }
        if let keyboardWillHideObserver = keyboardWillHideObserver {
            keyboardWillHideObserver.removeObserver()
            self.keyboardWillHideObserver = nil
        }
    }

    func prepareScreenForEditing(_ content: [Regionable], isComment: Bool) {
        var regions: [OmnibarRegion] = []
        var buyButtonURL: URL?
        var downloads: [(Int, URL)] = []  // the 'index' is used to replace the ImageURL region after it is downloaded
        for (index, region) in content.enumerated() {
            if let region = region as? TextRegion,
                let attrdText = ElloAttributedString.parse(region.content)
            {
                regions.append(.attributedText(attrdText))
            }
            else if let region = region as? ImageRegion,
                let url = region.url
            {
                if let imageRegionURL = region.buyButtonURL {
                    buyButtonURL = imageRegionURL as URL
                }
                downloads.append((index, url as URL))
                regions.append(.imageURL(url))
            }
        }
        screen.regions = regions
        screen.isComment = isComment
        screen.buyButtonURL = buyButtonURL

        let completed = after(downloads.count) {
            ElloHUD.hideLoadingHudInView(self.view)
        }

        for (index, imageURL) in downloads {
            PINRemoteImageManager.shared().downloadImage(with: imageURL, options: []) { result in
                if let animatedImage = result?.animatedImage {
                    regions[index] = .imageData(animatedImage.posterImage, animatedImage.data, "image/gif")
                }
                else if let image = result?.image {
                    regions[index] = .image(image)
                }
                else {
                    regions[index] = .error(imageURL)
                }
                let tmp = regions
                inForeground {
                    self.screen.regions = tmp
                    completed()
                }
            }
        }
    }

    func keyboardWillShow(_ keyboard: Keyboard) {
        screen.keyboardWillShow()
    }

    func keyboardWillHide(_ keyboard: Keyboard) {
        screen.keyboardWillHide()
    }

    fileprivate func goToPreviousTab() {
        elloTabBarController?.selectedTab = previousTab
    }

}

extension OmnibarViewController {

    class func canEditRegions(_ regions: [Regionable]?) -> Bool {
        return OmnibarScreen.canEditRegions(regions)
    }
}


extension OmnibarViewController: OmnibarScreenDelegate {

    func omnibarCancel() {
        if canGoBack {
            if let fileName = omnibarDataName() {
                var dataRegions = [NSObject]()
                for region in screen.regions {
                    if let rawRegion = region.rawRegion {
                        dataRegions.append(rawRegion)
                    }
                }
                let omnibarData = OmnibarCacheData()
                omnibarData.regions = dataRegions
                let data = NSKeyedArchiver.archivedData(withRootObject: omnibarData)
                _ = Tmp.write(data, to: fileName)
            }

            if parentPost != nil {
                Tracker.sharedTracker.contentCreationCanceled(.comment)
            }
            else if editPost != nil {
                Tracker.sharedTracker.contentEditingCanceled(.post)
            }
            else if editComment != nil {
                Tracker.sharedTracker.contentEditingCanceled(.comment)
            }
            else {
                Tracker.sharedTracker.contentCreationCanceled(.post)
            }
            _ = navigationController?.popViewController(animated: true)
        }
        else {
            Tracker.sharedTracker.contentCreationCanceled(.post)
            goToPreviousTab()
        }
    }

    func omnibarPresentController(_ controller: UIViewController) {
        if !(controller is AlertViewController) {
            UIApplication.shared.statusBarStyle = .lightContent
        }
        self.present(controller, animated: true, completion: nil)
    }

    func omnibarPushController(_ controller: UIViewController) {
        self.navigationController?.pushViewController(controller, animated: true)
    }

    func omnibarDismissController() {
        self.dismiss(animated: true, completion: nil)
    }

    func omnibarSubmitted(_ regions: [OmnibarRegion], buyButtonURL: URL?) {
        let content = generatePostContent(regions)
        guard content.count > 0 else {
            return
        }

        if let authorId = currentUser?.id {
            startPosting(authorId, content, buyButtonURL: buyButtonURL)
        }
        else {
            contentCreationFailed(InterfaceString.App.LoggedOutError)
        }
    }

}

// MARK: Posting the content to API
extension OmnibarViewController {

    func generatePostContent(_ regions: [OmnibarRegion]) -> [PostEditingService.PostContentRegion] {
        var content: [PostEditingService.PostContentRegion] = []
        for region in regions {
            switch region {
            case let .attributedText(attributedText):
                let textString = attributedText.string
                if textString.characters.count > 5000 {
                    contentCreationFailed(InterfaceString.Omnibar.TooLongError)
                    return []
                }

                let cleanedText = textString.trimmingCharacters(in: CharacterSet.whitespaces)
                if cleanedText.characters.count > 0 {
                    content.append(.text(ElloAttributedString.render(attributedText)))
                }
            case let .image(image):
                content.append(.image(image))
            case let .imageData(image, data, contentType):
                content.append(.imageData(image, data, contentType))
            default:
                break // there are "non submittable" types from OmnibarRegion, like Spacer and ImageURL
            }
        }
        return content
    }

    fileprivate func startPosting(_ authorId: String, _ content: [PostEditingService.PostContentRegion], buyButtonURL: URL?) {
        let service: PostEditingService
        let didGoToPreviousTab: Bool

        if let parentPost = parentPost {
            service = PostEditingService(parentPost: parentPost)
            didGoToPreviousTab = false
        }
        else if let editPost = editPost {
            service = PostEditingService(editPost: editPost)
            didGoToPreviousTab = false
        }
        else if let editComment = editComment {
            service = PostEditingService(editComment: editComment)
            didGoToPreviousTab = false
        }
        else {
            service = PostEditingService()

            goToPreviousTab()
            didGoToPreviousTab = true
        }

        startSpinner()
        service.create(
            content: content,
            buyButtonURL: buyButtonURL,
            success: { postOrComment in
                if self.editPost != nil || self.editComment != nil {
                    URLCache.shared.removeAllCachedResponses()
                }

                self.emitSuccess(postOrComment, didGoToPreviousTab: didGoToPreviousTab)
            },
            failure: { error, statusCode in
                ElloHUD.hideLoadingHudInView(self.view)
                self.screen.interactionEnabled = true
                self.contentCreationFailed(error.elloErrorMessage ?? error.localizedDescription)

                if let vc = self.parent as? ElloTabBarController, didGoToPreviousTab {
                    vc.selectedTab = .omnibar
                }
            })
    }

    fileprivate func emitSuccess(_ postOrComment: AnyObject, didGoToPreviousTab: Bool) {
        if let comment = postOrComment as? ElloComment {
            self.emitCommentSuccess(comment)
        }
        else if let post = postOrComment as? Post {
            self.emitPostSuccess(post, didGoToPreviousTab: didGoToPreviousTab)
        }
    }

    fileprivate func emitCommentSuccess(_ comment: ElloComment) {
        if editComment != nil {
            Tracker.sharedTracker.commentEdited(comment)
            postNotification(CommentChangedNotification, value: (comment, .replaced))
            stopSpinner()
        }
        else {
            ContentChange.updateCommentCount(comment, delta: 1)
            Tracker.sharedTracker.commentCreated(comment)
            postNotification(CommentChangedNotification, value: (comment, .create))

            if let post = comment.parentPost {
                PostService().loadPost(post.id, needsComments: false)
                    .onSuccess { post in
                        ElloLinkedStore.sharedInstance.setObject(post, forKey: post.id, type: .postsType)
                        postNotification(PostChangedNotification, value: (post, .watching))
                        self.stopSpinner()
                    }
                    .onFail { _ in
                        self.stopSpinner()
                    }
            }
            else {
                stopSpinner()
            }
        }

        if let listener = commentSuccessListener {
            listener(comment)
        }
    }

    fileprivate func emitPostSuccess(_ post: Post, didGoToPreviousTab: Bool) {
        stopSpinner()

        if editPost != nil {
            Tracker.sharedTracker.postEdited(post)
            postNotification(PostChangedNotification, value: (post, .replaced))
        }
        else {
            if let user = currentUser, let postsCount = user.postsCount {
                user.postsCount = postsCount + 1
                postNotification(CurrentUserChangedNotification, value: user)
            }

            Tracker.sharedTracker.postCreated(post)
            postNotification(PostChangedNotification, value: (post, .create))
        }

        if let listener = postSuccessListener {
            listener(post)
        }

        self.screen.resetAfterSuccessfulPost()

        if didGoToPreviousTab {
            NotificationBanner.displayAlert(message: InterfaceString.Omnibar.CreatedPost)
        }
    }

    func startSpinner() {
        ElloHUD.showLoadingHudInView(view)
        screen.interactionEnabled = false
    }

    func stopSpinner() {
        ElloHUD.hideLoadingHudInView(self.view)
        self.screen.interactionEnabled = true
    }

    func contentCreationFailed(_ errorMessage: String) {
        let contentType: ContentType
        if parentPost == nil && editComment == nil {
            contentType = .post
        }
        else {
            contentType = .comment
        }
        Tracker.sharedTracker.contentCreationFailed(contentType, message: errorMessage)
        screen.reportError("Could not create \(contentType.rawValue)", errorMessage: errorMessage)
    }

}

extension OmnibarViewController {
    func omnibarDataName() -> String? {
        if let post = parentPost {
            return "omnibar_v2_comment_\(post.repostId ?? post.id)"
        }
        else if editPost != nil || editComment != nil {
            return nil
        }
        else {
            return "omnibar_v2_post"
        }
    }
}
