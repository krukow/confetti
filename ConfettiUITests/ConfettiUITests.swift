import XCTest
import AppCenterXCUITestExtensions

var screenshotsEnabledIfZero = 0

func suspendScreenshots() { screenshotsEnabledIfZero += 1 }
func resumeScreenshots() { screenshotsEnabledIfZero -= 1 }
var screenshotsEnabled: Bool { return screenshotsEnabledIfZero == 0 }

func withoutScreenshots(run: ()->()) {
    suspendScreenshots()
    run()
    resumeScreenshots()
}

func step(_ label: String, run: (()-> ())? = nil) {
    run?()
    
    if screenshotsEnabled {
        ACTLabel.labelStep(label)
    }
}

class ConfettiUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        
        let app = XCUIApplication()
        app.launchArguments = ["test"]
        ACTLaunch.launch(app)
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
        sleep(1)
        step("Login") {
            XCUIApplication().buttons["I'd rather not"].tapIfExists()
            sleep(1)
        }
    }

    func addEvent(person: String, waitForImages: Bool = false) {
        let app = XCUIApplication()
        
        
        step("Add event") {
            app.buttons["AddButton"].tap()
        }
        
        step("Choose Birthday") {
            app.buttons["Birthday"].tap()
        }
        
        if waitForImages {
            sleep(5)
        }
        
        step("Choose '\(person)'") {
            let search = app.searchFields["Search Contacts"]
            search.tap()
            search.typeText(person)
            app.tables["contacts"].cells.element(boundBy: 0).tap()
        }
        
        step("Save") {
            app.buttons["Save"].tap()
        }
    }
    
    func testCreateABirthday() {
        let app = XCUIApplication()
        
        loginIfNeeded()
        
        waitFor(element: app.buttons["Me"])
        step("Empty view")

        addEvent(person: "Ellen Appleseed", waitForImages: true)
        
        withoutScreenshots {
            for name in ["David", "Hannah", "Stu", "Carrie", "Vinicius"] {
                addEvent(person: "\(name) Appleseed")
            }
        }
        
        step("Main view")
        
        step("Event details") {
            app.cells.element(boundBy: 0).tap()
        }
        
        step("View profile") {
            app.buttons["Me"].tap()
        }
        
        app.staticTexts["Logout"].tap()
    }
    
    func testCrash() {
        let app = XCUIApplication()
        loginIfNeeded()
        
        waitFor(element: app.buttons["Me"])
        
        step("Me") {
            app.buttons["Me"].tapIfExists()
        }
        
        if TARGET_OS_SIMULATOR == 0 {
            step("Crash") {
                app.tables/*@START_MENU_TOKEN@*/.staticTexts["Crash the app!"]/*[[".cells.staticTexts[\"Crash the app!\"]",".staticTexts[\"Crash the app!\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
            }
            
            step("Should not get here") {
                self.waitFor(element: app.buttons["Me"])
            }
        }
    }
    
    func testOptionsSheet() {
        let app = XCUIApplication()
        loginIfNeeded()
        
        addEvent(person: "Ellen Appleseed", waitForImages: false)
        addEvent(person: "Hannah Appleseed", waitForImages: false)

        app.cells.element(boundBy: 0).tap()

        app.navigationBars["Confetti.EventDetailView"].children(matching: .button).element(boundBy: 1).tap()

        step("Options sheet") {
            sleep(1)
        }

        app.sheets.buttons["Clear Photo"].tap()

    }
}

extension XCUIElement {
    func tapIfExists() {
        if exists {
            tap()
        }
    }
}

