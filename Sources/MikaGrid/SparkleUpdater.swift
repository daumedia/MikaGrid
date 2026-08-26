// SparkleUpdater.swift
// MikaGrid
//
// Sparkle auto-update wrapper for checking and installing updates.
// Swift 6.0 strict concurrency, macOS 14+

import Foundation
import Observation
@preconcurrency import Sparkle
import MikaGridCore

@Observable
@MainActor
final class SparkleUpdater: UpdateChecking {
    private var updaterController: SPUStandardUpdaterController!
    private let observer = UpdaterObserver()

    /// Grund des letzten fehlgeschlagenen Prüflaufs.
    ///
    /// Bis 1.1.1 lief Sparkle ohne Delegate: Ein dauerhaft toter Update-Weg — falsche Adresse,
    /// gelöschter Zweig, abgelaufenes Zertifikat — blieb vollständig unbemerkt. Weder Nutzer
    /// noch Betreiber erfuhren davon, und aus Nutzersicht sah das genauso aus wie
    /// „ich bin aktuell".
    private(set) var lastCheckError: String?

    var canCheckForUpdates: Bool {
        updaterController.updater.canCheckForUpdates
    }

    var automaticallyChecksForUpdates: Bool {
        get { updaterController.updater.automaticallyChecksForUpdates }
        set { updaterController.updater.automaticallyChecksForUpdates = newValue }
    }

    /// Ob gefundene Updates von selbst geladen und installiert werden.
    ///
    /// Diese Stufe war bis 1.1.1 in der Oberfläche gar nicht vertreten, obwohl Sparkle sie beim
    /// ersten Start abfragt und auf dem geprüften System auf „an" stand.
    var automaticallyDownloadsUpdates: Bool {
        get { updaterController.updater.automaticallyDownloadsUpdates }
        set { updaterController.updater.automaticallyDownloadsUpdates = newValue }
    }

    var lastUpdateCheckDate: Date? {
        updaterController.updater.lastUpdateCheckDate
    }

    init() {
        observer.onCycleFinished = { [weak self] error in
            MainActor.assumeIsolated { self?.lastCheckError = error }
        }
        self.updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: observer,
            userDriverDelegate: nil
        )
    }

    func checkForUpdates() {
        lastCheckError = nil
        updaterController.checkForUpdates(nil)
    }
}

/// Nimmt Sparkles Rückmeldungen entgegen. Eigene Klasse, weil `SPUUpdaterDelegate` von einem
/// `NSObject` erfüllt werden muss und nicht an den MainActor gebunden ist.
private final class UpdaterObserver: NSObject, SPUUpdaterDelegate, @unchecked Sendable {
    var onCycleFinished: ((String?) -> Void)?

    func updater(_ updater: SPUUpdater, didFinishUpdateCycleFor updateCheck: SPUUpdateCheck, error: (any Error)?) {
        guard let error else {
            onCycleFinished?(nil)
            return
        }
        // Sparkle meldet „kein Update gefunden" als Fehler — das ist der Normalfall, kein Problem.
        let noUpdateFound = (error as NSError).code == Int(Sparkle.SUError.noUpdateError.rawValue)
        onCycleFinished?(noUpdateFound ? nil : error.localizedDescription)
    }
}
