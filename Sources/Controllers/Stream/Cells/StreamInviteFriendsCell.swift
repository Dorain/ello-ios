////
///  StreamInviteFriendsCell.swift
//

import Foundation

class StreamInviteFriendsCell: UICollectionViewCell {
    static let reuseIdentifier = "StreamInviteFriendsCell"

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var inviteButton: StyledButton!

    weak var inviteDelegate: InviteDelegate?
    var inviteCache: InviteCache?
    var bottomBorder = CALayer()
    var isOnboarding = false

    var person: LocalPerson? {
        didSet {
            nameLabel.text = person!.name
            styleInviteButton(inviteCache?.has(person!.identifier))
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        nameLabel.font = UIFont.defaultFont(18)
        nameLabel.textColor = UIColor.greyA()
        nameLabel.lineBreakMode = NSLineBreakMode.byTruncatingTail
        // bottom border
        bottomBorder.backgroundColor = UIColor.greyF1().cgColor
        self.layer.addSublayer(bottomBorder)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        isOnboarding = false
    }

    override func layoutSubviews() {
        bottomBorder.frame = CGRect(x: 0, y: self.bounds.height - 1, width: self.bounds.width, height: 1)
        super.layoutSubviews()
    }

    @IBAction func invite() {
        if let person = person {
            inviteDelegate?.sendInvite(person: person, isOnboarding: isOnboarding) {
                self.inviteCache?.saveInvite(person.identifier)
                self.styleInviteButton(self.inviteCache?.has(person.identifier))
            }
        }
    }

    func styleInviteButton(_ invited: Bool? = false) {
        if invited == true {
            inviteButton.style = .Invited
            inviteButton.setTitle(InterfaceString.Friends.Resend, for: .normal)
        }
        else {
            inviteButton.style = .InviteFriend
            inviteButton.setTitle(InterfaceString.Friends.Invite, for: .normal)
        }
    }
}
