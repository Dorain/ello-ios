//
//  SensitiveSettingsViewController.swift
//  Ello
//
//  Created by Tony DiPasquale on 3/24/15.
//  Copyright (c) 2015 Ello. All rights reserved.
//

import Foundation

private let SensitiveSettingsSubmitViewHeight: CGFloat = 128


public protocol SensitiveSettingsDelegate {
    func sensitiveSettingsDidUpdate()
}

private enum SensitiveSettingsRow: Int {
    case Username
    case Email
    case Password
    case Submit
    case Unknown
}

public class SensitiveSettingsViewController: UITableViewController {
    @IBOutlet weak public var usernameView: ElloTextFieldView!
    @IBOutlet weak public var emailView: ElloTextFieldView!
    @IBOutlet weak public var passwordView: ElloTextFieldView!
    @IBOutlet weak public var currentPasswordField: ElloTextField!

    public var currentUser: User?
    public var delegate: SensitiveSettingsDelegate?
    var validationCancel: Functional.BasicBlock?

    public var isUpdatable: Bool {
        return currentUser?.username != usernameView.textField.text
            || currentUser?.email != emailView.textField.text
            || !passwordView.textField.text.isEmpty
    }

    public var height: CGFloat {
        let cellHeights = usernameView.height + emailView.height + passwordView.height
        return cellHeights + (isUpdatable ? SensitiveSettingsSubmitViewHeight : 0)
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    private func setupViews() {
        usernameView.label.text = "Username"
        usernameView.textField.text = currentUser?.username
        usernameView.textFieldDidChange = { text in
            self.valueChanged()
            self.usernameView.setState(.Loading)
            self.validationCancel?()

            self.validationCancel = Functional.cancelableDelay(0.5) {
                self.usernameView.setMessage("");

                if text.isEmpty {
                    self.usernameView.setState(.Error)
                } else if text == self.currentUser?.username {
                    self.usernameView.setState(.None)
                } else {
                    AvailabilityService().usernameAvailability(text, success: { availability in
                        if text != self.usernameView.textField.text { return }
                        let state: ValidationState = availability.username ? .OK : .Error

                        if !availability.username && !availability.usernameSuggestions.isEmpty {
                            let suggestions = ", ".join(availability.usernameSuggestions)
                            self.usernameView.setMessage("Available usernames -\n\(suggestions)");
                        }
                        self.usernameView.setState(state)
                        self.updateView()
                    }, failure: { _, _ in
                        self.usernameView.setState(.None)
                        self.updateView()
                    })
                }
                self.updateView()
            }
        }

        emailView.label.text = "Email"
        emailView.textField.text = currentUser?.email
        emailView.textFieldDidChange = { text in
            self.valueChanged()
            self.emailView.setState(.Loading)
            self.validationCancel?()

            self.validationCancel = Functional.cancelableDelay(0.5) {
                if text.isEmpty {
                    self.emailView.setState(.Error)
                } else if text == self.currentUser?.email {
                    self.emailView.setState(.None)
                } else if text.isValidEmail() {
                    AvailabilityService().emailAvailability(text, success: { availability in
                        if text != self.emailView.textField.text { return }
                        let state: ValidationState = availability.email ? .OK : .Error
                        self.emailView.setState(state)
                        }, failure: { _, _ in
                            self.emailView.setState(.None)
                    })
                } else {
                    self.emailView.setState(.Error)
                }
            }
        }

        passwordView.label.text = "Password"
        passwordView.textField.secureTextEntry = true
        passwordView.textFieldDidChange = { text in
            self.valueChanged()
            if text.isEmpty {
                self.passwordView.setState(.None)
            } else if text.isValidPassword() {
                self.passwordView.setState(.OK)
            } else {
                self.passwordView.setState(.Error)
            }
        }
    }

    public func valueChanged() {
        delegate?.sensitiveSettingsDidUpdate()
    }

    func updateView() {
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
        valueChanged()
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch SensitiveSettingsRow(rawValue: indexPath.row) ?? .Unknown {
        case .Username: return usernameView.height
        case .Email: return emailView.height
        case .Password: return passwordView.height
        case .Submit: return SensitiveSettingsSubmitViewHeight
        case .Unknown: return 0
        }
    }
}

public extension SensitiveSettingsViewController {
    class func instantiateFromStoryboard() -> SensitiveSettingsViewController {
        return UIStoryboard(name: "Settings", bundle: NSBundle(forClass: AppDelegate.self)).instantiateViewControllerWithIdentifier("SensitiveSettingsViewController") as! SensitiveSettingsViewController
    }
}
