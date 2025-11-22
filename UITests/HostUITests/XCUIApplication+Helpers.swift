import XCTest

private enum EnvironmentKey {
    static let crlfLineEndings = "crlfLineEndings"
}

extension XCUIApplication {
    var textView: XCUIElement? {
        textViews["RunestoneTextView"]
    }

    func disablingTextPersistance() -> Self {
        var newLaunchEnvironment = launchEnvironment
        newLaunchEnvironment[EnvironmentKey.disableTextPersistance] = "1"
        launchEnvironment = newLaunchEnvironment
        return self
    }

    func usingCRLFLineEndings() -> Self {
        var newLaunchEnvironment = launchEnvironment
        newLaunchEnvironment[EnvironmentKey.crlfLineEndings] = "1"
        launchEnvironment = newLaunchEnvironment
        return self
    }
}
