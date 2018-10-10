import XCTest

func screenshot(activity: XCTActivity) {
    let screenshot = XCUIScreen.main.screenshot()
    let attachment = XCTAttachment.init(screenshot: screenshot)
    attachment.lifetime = XCTAttachment.Lifetime.keepAlways
    activity.add(attachment)
}

class ConfettiUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        
        let app = XCUIApplication()
        app.launchArguments = ["test"]
        app.launch()
    }
    
    func waitFor(element: XCUIElement, timeout: TimeInterval = 5,  file: String = #file, line: UInt = #line) {
        let existsPredicate = NSPredicate(format: "exists == true")
        
        expectation(for: existsPredicate,
                    evaluatedWith: element, handler: nil)
        
        waitForExpectations(timeout: timeout) { error in
            if error != nil {
                let message = "Failed to find \(element) after \(timeout) seconds."
                self.recordFailure(withDescription: message, inFile: file, atLine: Int(line), expected: true)
            }
        }
    }
    
    override func tearDown() {
        // Called after the invocation of each test method
        super.tearDown()
    }
    
    func loginIfNeeded() {
        XCTContext.runActivity(named: "Logged in") { activity in
            let buttonExists = XCUIApplication().buttons["I'd rather not"].waitForExistence(timeout: 2)
            if (buttonExists) {
                XCUIApplication().buttons["I'd rather not"].tap()
                //await animation - and data load
                sleep(5)
            }
        }
    }

    func addEvent(person: String, waitForImages: Bool = false) {
        let app = XCUIApplication()
        
        
        XCTContext.runActivity(named: "Add event") { activity in
            app.buttons["AddButton"].tap()
        }
        
        XCTContext.runActivity(named: "Choose Birthday") { activity in
            app.buttons["Birthday"].tap()
        }
        
        if waitForImages {
            sleep(5)
        }
        
        XCTContext.runActivity(named: "Choose '\(person)'") { activity in
            let search = app.searchFields["Search Contacts"]
            search.tap()
            search.typeText(person)
            screenshot(activity: activity)
            app.tables["contacts"].cells.element(boundBy: 0).tap()
        }
        
        XCTContext.runActivity(named: "Save") { activity in
            app.buttons["Save"].tap()
        }
    }
    
    func testCreateABirthday() {
        let app = XCUIApplication()
        
        loginIfNeeded()
        
        waitFor(element: app.buttons["Me"])
        XCTContext.runActivity(named: "Empty view") {
            activity in
            screenshot(activity: activity) }
        
        addEvent(person: "Ellen Appleseed", waitForImages: true)
        
        addEvent(person: "David Appleseed")
        
        
        XCTContext.runActivity(named: "Main view") { activity in screenshot(activity: activity) }
        
        XCTContext.runActivity(named: "Event details") { activity in
            app.cells.element(boundBy: 0).tap()
            screenshot(activity: activity)
        }
        XCTContext.runActivity(named: "View profile") { activity in
            app.buttons["Me"].tap()
            screenshot(activity: activity)
        }
        
        app.staticTexts["Logout"].tap()
    }
    
    func addEventForPerson(_ name : String) {
        let app = XCUIApplication()
        app.buttons["AddButton"].tap()
        app.buttons["Birthday"].tap()
        let search = app.searchFields["Search Contacts"]
        search.tap()
        search.typeText(name)
        app.tables["contacts"].cells.element(boundBy: 0).tap()
        app.buttons["Save"].tap()
    }
    
    func testOptionsSheet() {
        let app = XCUIApplication()
        
        let buttonExists = XCUIApplication().buttons["I'd rather not"].waitForExistence(timeout: 2)
        if (buttonExists) {
            XCUIApplication().buttons["I'd rather not"].tap()
            //await animation - and data load
            sleep(5)
        }
        
        waitFor(element: app.buttons["Me"])
        addEventForPerson("Ellen Appleseed")
        addEventForPerson("Hanna Appleseed")
        app.cells.element(boundBy: 0).tap()
        
        let detailsView = app.navigationBars["Confetti.EventDetailView"]
        detailsView.children(matching: .button).element(boundBy: 1).tap()
    }

}

extension XCUIElement {
    func tapIfExists() {
        if exists {
            tap()
        }
    }
}

