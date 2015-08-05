//
//  ElloAttributedStringSpec.swift
//  Ello
//
//  Created by Colin Gray on 3/7/2015.
//  Copyright (c) 2015 Ello. All rights reserved.
//

import Ello
import Quick
import Nimble


class ElloAttributedStringSpec: QuickSpec {
    override func spec() {
        describe("styling a string") {
            it("returns an attributed string") {
                let text = "text"
                let attrd = ElloAttributedString.style(text)
                expect(attrd).to(beAKindOf(NSAttributedString))
            }
        }
        describe("parsing Post body") {
            let tests: [String: (input: String, output: String)] = [
                "with newlines": (input: "test<br><br />", output: "test\n\n"),
                "link": (input: "<a href=\"foo.com\">a link</a>", output: "[a link](foo.com)"),
                "text and link": (input: "test <a href=\"foo.com\">a link</a>", output: "test [a link](foo.com)"),
                "styled text": (input: "test <b>bold</b> <i>italic</i> <strong>strong</strong> <em>emphasis</em>", output: "test bold italic strong emphasis")
            ]
            for (name, spec) in tests {
                it("should parse \(name)") {
                    let text = ElloAttributedString.parse(spec.input)
                    expect(text!.string) == spec.output
                }
            }

        }
    }
}
