import AppKit
import Testing
@testable import WinDummy

/// Runs against a private pasteboard, so the real clipboard is never touched.
@MainActor
@Suite struct ClipboardStoreTests {
    let pasteboard = NSPasteboard(name: NSPasteboard.Name("windummy-tests-\(UUID().uuidString)"))
    let store: ClipboardStore

    init() {
        store = ClipboardStore(pasteboard: pasteboard)
    }

    private func copy(_ string: String) {
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
        store.poll()
    }

    private func copyImage(red: CGFloat) {
        let image = NSImage(size: NSSize(width: 8, height: 8))
        image.lockFocus()
        NSColor(red: red, green: 0, blue: 0, alpha: 1).setFill()
        NSRect(x: 0, y: 0, width: 8, height: 8).fill()
        image.unlockFocus()
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
        store.poll()
    }

    @Test func recordsTextNewestFirst() {
        copy("one")
        copy("two")
        #expect(store.items.map(\.searchableText) == ["two", "one"])
    }

    @Test func copyingTheSameTextAgainMovesItToTheTop() {
        copy("one")
        copy("two")
        copy("one")
        #expect(store.items.map(\.searchableText) == ["one", "two"])
    }

    @Test func ignoresWhatPasswordManagersMarkAsSecret() {
        pasteboard.clearContents()
        pasteboard.setString("hunter2", forType: .string)
        pasteboard.setData(Data(), forType: NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType"))
        store.poll()
        #expect(store.items.isEmpty)
    }

    @Test func filesAreRecordedAsFilesAndPutBackAsFiles() throws {
        let url = URL(fileURLWithPath: "/Applications/Safari.app")
        pasteboard.clearContents()
        // Like Finder: the file reference plus its name as text.
        pasteboard.writeObjects([url as NSURL])
        pasteboard.setString("Safari.app", forType: .string)
        store.poll()

        let item = try #require(store.items.first)
        guard case .files(let urls, _) = item.content else {
            Issue.record("expected files, got \(item.content)")
            return
        }
        #expect(urls == [url])
        #expect(item.plainText == url.path)

        pasteboard.clearContents()
        store.copyToClipboard(item)
        let restored = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL]
        #expect(restored == [url])
    }

    @Test func formattingSurvivesAndPlainTextDropsIt() throws {
        let rtf = try #require(NSAttributedString(string: "bold").rtf(from: NSRange(location: 0, length: 4), documentAttributes: [:]))
        pasteboard.clearContents()
        pasteboard.setData(rtf, forType: .rtf)
        pasteboard.setString("bold", forType: .string)
        store.poll()
        let item = try #require(store.items.first)

        pasteboard.clearContents()
        store.copyToClipboard(item)
        #expect(pasteboard.data(forType: .rtf) == rtf)

        store.copyToClipboard(item, plainText: true)
        #expect(pasteboard.data(forType: .rtf) == nil)
        #expect(pasteboard.string(forType: .string) == "bold")
    }

    @Test func keepsOnlyTheFiveLatestImages() {
        copy("text before")
        for i in 0..<7 {
            copyImage(red: CGFloat(i) / 10)
        }
        #expect(store.items.filter(\.isImage).count == 5)
        #expect(store.items.contains { $0.searchableText == "text before" })
    }

    @Test func theSameImageTwiceIsOneEntry() {
        copyImage(red: 0.5)
        copy("between")
        copyImage(red: 0.5)
        #expect(store.items.count == 2)
        #expect(store.items.first?.isImage == true)
    }

    @Test func removingTheCurrentEntryEmptiesTheClipboard() throws {
        copy("secret code")
        let item = try #require(store.items.first)
        store.remove(item)
        #expect(store.items.isEmpty)
        #expect(pasteboard.string(forType: .string) == nil)
    }

    @Test func pasteTemporarilyPutsTheOldClipboardBack() async throws {
        copy("keep me")
        var seenDuringPaste: String?
        store.pasteTemporarily("@") {
            seenDuringPaste = pasteboard.string(forType: .string)
        }
        #expect(seenDuringPaste == "@")

        try await Task.sleep(for: .seconds(1))
        #expect(pasteboard.string(forType: .string) == "keep me")
        store.poll()
        #expect(store.items.map(\.searchableText) == ["keep me"])
    }
}
